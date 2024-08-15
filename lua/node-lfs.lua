--[[
License : GPLv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local strSplit = require("str-split")

-- remember the function, in case it is replaced later on by LFS user code.
local lf = loadfile

---extract .lua file name (no extension)
---@param loc string
---@return string
local function getModname(loc)
    local s, _ = string.gsub(string.match(loc, "[^/]*.lua$"), ".lua$", "")
    return s
end

---index env.NODEMCU_LFS_FILES into table modName=location
---@return {[string]:string}
local function getLFSfun()
    local str = os.getenv("NODEMCU_LFS_FILES") or ""
    local lst = strSplit(str, " ")
    local ret = {}
    for _, loc in ipairs(lst) do
        local name = getModname(loc)
        ret[name] = loc
    end
    return ret
end

---@class node_lfs
local LFS = {
    ---fixed value, overwrite in test cases if required.
    ---BUT pay attention this is not reset with nodemcu.reset(),
    ---you need to start new test case althogether.
    time = 1669271656
}
LFS.__index = LFS

---stock API
---@return string[]
LFS.list = function()
    local ret = {}
    for k, _ in pairs(getLFSfun()) do
        table.insert(ret, k)
    end
    table.sort(ret)
    return ret
end

---stock API
---@param modName any
---@return fun()? function
---@return string? error_message
LFS.get = function(modName)
    local loc = getLFSfun()[modName]
    if loc then
        local fn, err = assert(lf(loc))
        if fn then
            package.preload[modName] = fn
        end
        return fn, err
    end
    return nil, nil
end

---stock API
---if the imageName exists, it raises and error with mesage "node.LFS.reload".
---if the imageName does not exists, it returns doing nothing.
---if global variable NODEMCU_LFS_RELOAD_FAIL is defined, it returns its value as error
---@param imageName string
---@return string error
LFS.reload = function(imageName)
    assert(type(imageName) == "string")
    local ok = require("file").exists(imageName)
    if ok then
        if _G["NODEMCU_LFS_RELOAD_FAIL"] then
            return string.format("%s", _G["NODEMCU_LFS_RELOAD_FAIL"])
        end
        error("node.LFS.reload")
    else
        return string.format("image file missing : %s", imageName)
    end
end

return LFS
