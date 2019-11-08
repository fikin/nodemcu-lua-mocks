--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local nodemcu = require("nodemcu-module")
file = {}
file.__index = file

--- file.open is stock nodemcu API
file.open = function(name)
  assert(type(name) == "string", "name must be string")
  nodemcu.file_opened._fd = io.open(name)
  if not nodemcu.file_opened._fd then
    return false
  end
  nodemcu.file_opened._in = io.input(nodemcu.file_opened._fd)
  return true
end

--- file.exists is stock nodemcu API
file.exists = function(loc)
  assert(type(loc) == "string", "location must be string")
  local f = io.open(loc, "r")
  if f ~= nil then
    io.close(f)
    return true
  else
    return false
  end
end

--- file.close is stock nodemcu API
file.close = function()
  if nodemcu.file_opened._fd then
    io.close(nodemcu.file_opened._fd)
    nodemcu.file_opened._fd = nil
    nodemcu.file_opened._in = nil
  end
end

--- file.read is stock nodemcu API
file.read = function(delim)
  if nodemcu.file_opened._in then
    return nodemcu.file_opened._in:read("*line")
  else
    return nil
  end
end

return file
