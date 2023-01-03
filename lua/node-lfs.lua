--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local strSplit = require("str-split")

-- remember the function, in case it is replaced later on by LFS user code.
local lf = loadfile

---extract .lua file name (no extension)
---@param loc string
---@return string
local function getModname(loc)
    local s, _ = string.gsub(string.match(loc, "[^/]*.lua$"), ".lua", "")
    return s
end

---index env.NODEMCU_LFS_FILES into table modName=location
---@return {[string]:string}
local function getLFSfun()
    local str = os.getenv("NODEMCU_LFS_FILES") or ""
    local lst = strSplit(str, " ")
    local ret = {}
    for i, loc in ipairs(lst) do
        local name = getModname(loc)
        ret[name] = loc
    end
    return ret
end

---@class node_lfs
local LFS = {}
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
---@param imageName string
---@return string? error
LFS.reload = function(imageName)
    -- TODO how to determine if to return err
    -- TODO how to simulate node reboot
    return "FIXME : not implemented"
end

return LFS
