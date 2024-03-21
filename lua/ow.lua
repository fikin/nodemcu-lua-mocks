--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local nodemcu = require("nodemcu-module")

---@alias ow_rom string

---ow module
---@class ow
ow = {}
ow.__index = ow

---stock API
---@param pin integer
ow.setup = function(pin)
  nodemcu.ow.pin = pin
end

---stock API
---@param pin integer
---@param alarm_search? integer one or zero
---@return ow_rom
ow.search = function(pin, alarm_search)
  assert(pin == nodemcu.ow.pin)
  if alarm_search then assert(alarm_search and (alarm_search == 1 or alarm_search == 0)); end
  return nodemcu.ow.Rom
end

---stock API
---@param pin integer
---@param rom ow_rom
ow.select = function(pin, rom)
  assert(pin == nodemcu.ow.pin)
  nodemcu.ow.selected_rom = rom
end

---stock API
---@param pin integer
---@return integer
ow.read = function(pin)
  assert(pin == nodemcu.ow.pin)
  return 0 -- TODO
end

---stock API
---@param pin integer
---@param size integer
---@return string
ow.read_bytes = function(pin, size)
  assert(pin == nodemcu.ow.pin)
  assert(type(size) == "number")
  return "A" -- TODO
end

---stock API
---@param pin integer
---@param v integer
---@param power integer zero or one
ow.write = function(pin, v, power)
  assert(pin == nodemcu.ow.pin)
  assert(type(v) == "number")
  assert(power == 1 or power == 0)
  -- TODO
end

---stock API
---@param pin integer
---@param buf string
---@param power integer zero or one
ow.write_bytes = function(pin, buf, power)
  assert(pin == nodemcu.ow.pin)
  assert(type(buf) == "string")
  assert(power == 1 or power == 0)
  -- TODO
end

---stock API
---@param buf string
---@return integer
ow.crc8 = function(buf)
  assert(type(buf) == "string")
  return 0 -- TODO
end

---stock API
---@param pin integer
ow.reset = function(pin)
  assert(pin == nodemcu.ow.pin)
  -- TODO
end

---stock API
---@param pin integer
ow.reset_search = function(pin)
  assert(pin == nodemcu.ow.pin)
  -- TODO
end

---stock API
---@param pin integer
ow.skip = function(pin)
  assert(pin == nodemcu.ow.pin)
  -- TODO
end

---stock API
---@param pin integer
ow.depower = function(pin)
  assert(pin == nodemcu.ow.pin)
  -- TODO
end

return ow
