--[[
License : GPLv3, see LICENCE in root of repository

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
  local rec = nodemcu.get_ow(pin)
  -- these overwrite test case setups ...
  -- rec.searchIndx = 0
  -- rec.selectedRom = ""
  -- rec.events = {}
  -- rec.tobeRead = {}
  table.insert(rec.events, { "setup", pin })
end

---stock API
---@param pin integer
---@param alarm_search? integer one or zero
---@return ow_rom
ow.search = function(pin, alarm_search)
  local rec = nodemcu.get_ow(pin)
  alarm_search = alarm_search or 1
  assert(alarm_search == 1 or alarm_search == 0)
  rec.searchIndx = rec.searchIndx + 1
  table.insert(rec.events, { "search", pin, alarm_search })
  if alarm_search == 1 then
    return rec.regularDevices[rec.searchIndx]
  else
    return rec.alarmingDevices[rec.searchIndx]
  end
end

---stock API
---@param pin integer
---@param rom ow_rom
ow.select = function(pin, rom)
  local rec = nodemcu.get_ow(pin)
  -- TODO check for ROM existing in devices list
  rec.selectedRom = rom
  table.insert(rec.events, { "select", pin, rom })
end

---stock API
---@param pin integer
---@return string
ow.read = function(pin)
  local rec = nodemcu.get_ow(pin)
  table.insert(rec.events, { "read", pin })
  return string.sub(table.remove(rec.tobeRead, 1) or "", 1, 1)
end

---stock API
---@param pin integer
---@param size integer
---@return string
ow.read_bytes = function(pin, size)
  local rec = nodemcu.get_ow(pin)
  assert(type(size) == "number")
  return string.sub(table.remove(rec.tobeRead, 1) or "", 1, size)
end

---stock API
---@param pin integer
---@param v integer
---@param power integer zero or one
ow.write = function(pin, v, power)
  local rec = nodemcu.get_ow(pin)
  assert(v >= 0)
  assert(v <= 255)
  assert(power == 1 or power == 0)
  table.insert(rec.events, { "write", pin, v, power })
end

---stock API
---@param pin integer
---@param buf string
---@param power integer zero or one
ow.write_bytes = function(pin, buf, power)
  local rec = nodemcu.get_ow(pin)
  assert(type(buf) == "string")
  assert(power == 1 or power == 0)
  table.insert(rec.events, { "write_bytes", pin, buf, power })
end

---stock API
---@param buf string
---@return integer
ow.crc8 = function(buf)
  assert(type(buf) == "string")
  return require("crc8")(buf)
end

---stock API
---@param pin integer
---@return integer 1 or 0
ow.reset = function(pin)
  local rec = nodemcu.get_ow(pin)
  table.insert(rec.events, { "reset", pin })
  return rec.reset_resp
end

---stock API
---@param pin integer
ow.reset_search = function(pin)
  local rec = nodemcu.get_ow(pin)
  table.insert(rec.events, { "reset_search", pin })
  rec.searchIndx = 0
end

---stock API
---@param pin integer
ow.skip = function(pin)
  local rec = nodemcu.get_ow(pin)
  table.insert(rec.events, { "skip", pin })
end

---stock API
---@param pin integer
ow.depower = function(pin)
  local rec = nodemcu.get_ow(pin)
  table.insert(rec.events, { "depower", pin })
end

return ow
