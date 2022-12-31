--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local modname = ...
local nodemcu = require("nodemcu-module")
local openFileFn = require("file_obj")

---file module
---@class file
file = {
  ---file.obj, meant to point at nodemcu.file_data.obj
  ---Not recommended to be used much, use object methods instead.
  ---@type file_obj
  obj = nil
}
file.__index = file


---register nodemcu state reset for the module
nodemcu.add_reset_fn(modname, function()
  file.obj = nil
end)

local function fileLoc(loc)
  return nodemcu.t_file_workDir .. "/" .. loc
end

---file.getcontents is stock nodemcu API
---@param loc string
---@return string|nil
file.getcontents = function(loc)
  assert(type(loc) == "string", "location must be string")
  local f, err = openFileFn(fileLoc(loc), "r")
  if not f then
    return nil
  end
  local str = f:read(4096)
  f:close()
  return str
end

---file.open is stock nodemcu API
---@param loc string
---@param mode string
---@return file_obj?
file.open = function(loc, mode)
  assert(type(loc) == "string", "name must be string")
  assert((file.obj and file.obj:isClosed()) or not file.obj, "file.obj is not closed")
  local f, err = openFileFn(fileLoc(loc), mode)
  if f then
    file.obj = f
  end
  return f
end

---file.exists is stock nodemcu API
---@param loc string
---@return boolean
file.exists = function(loc)
  assert(type(loc) == "string", "location must be string")
  local f, err = openFileFn(fileLoc(loc), "r")
  if f then
    f:close()
    return true
  end
  return false
end

---file.remove is stock nodemcu API
---@param loc string
file.remove = function(loc)
  assert(type(loc) == "string", "location must be string")
  os.remove(fileLoc(loc))
end

---file.putcontents is stick nodemcu API
---@param loc string
---@param data string
---@return boolean|nil
file.putcontents = function(loc, data)
  assert(type(loc) == "string", "location must be string")
  assert(data ~= nil, "data is nil")
  local f, err = openFileFn(fileLoc(loc), "w")
  if f then
    f:write(data)
    f:close()
    return true
  end
  return nil
end

---file.rename is stock API
---@param oldname string
---@param newname string
---@return boolean
file.rename = function(oldname, newname)
  assert(type(oldname) == "string", "oldname must be string")
  assert(type(newname) == "string", "newname must be string")
  return os.rename(fileLoc(oldname), fileLoc(newname))
end

---@class file_stat
---@field size integer
---@field name string

---file.stat(filename) is stock API
---@param loc string
---@return file_stat|nil
file.stat = function(loc)
  assert(type(loc) == "string", "location must be string")
  local f, err = openFileFn(fileLoc(loc), "r")
  if f then
    local sz = f:seek("end")
    f:close()
    return { size = sz, name = loc }
  end
  return nil
end

---file.close is stock nodemcu API
file.close = function()
  if file.obj then
    file.obj:close()
    file.obj = nil
  end
end

---file.flush is stock nodemcu API
file.flush = function()
  if file.obj then
    file.obj:flush()
  end
end

--- file.read is stock nodemcu API
---@param ... unknown
---@return string|nil
file.read = function(...)
  if file.obj then
    return file.obj:read(...)
  end
  return nil
end

---file.readline is stock nodemcu API
---@return string|nil
file.readline = function()
  if file.obj then
    return file.obj:readline()
  end
  return nil
end

---file.seek is stock nodemcu API
---@param ... unknown
---@return integer|nil
file.seek = function(...)
  if file.obj then
    return file.obj:seek(...)
  end
  return nil
end

---file.write is stock nodemcu API
---@param ... unknown
---@return boolean|nil
file.write = function(...)
  if file.obj then
    return file.obj:write(...)
  end
  return nil
end

---file.writeline is stock nodemcu API
---@param ... unknown
---@return boolean|nil
file.writeline = function(...)
  if file.obj then
    return file.obj:writeline(...)
  end
  return nil
end

return file
