--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local contains = require("contains")
local inspect = require("inspect")
local nodemcu = require("nodemcu-module")

-- Eventmon is stock nodemcu API
local Eventmon = {}
Eventmon.__index = Eventmon

Eventmon.STA_CONNECTED = 1
Eventmon.STA_DISCONNECTED = 2
Eventmon.STA_AUTHMODE_CHANGE = 3
Eventmon.STA_GOT_IP = 4
Eventmon.STA_DHCP_TIMEOUT = 5
Eventmon.AP_STACONNECTED = 6
Eventmon.AP_STADISCONNECTED = 7
Eventmon.AP_PROBEREQRECVED = 8

local eventmonEnum = {
  Eventmon.STA_CONNECTED,
  Eventmon.STA_DISCONNECTED,
  Eventmon.STA_AUTHMODE_CHANGE,
  Eventmon.STA_GOT_IP,
  Eventmon.STA_DHCP_TIMEOUT,
  Eventmon.AP_STACONNECTED,
  Eventmon.AP_STADISCONNECTED,
  Eventmon.AP_PROBEREQRECVED
}

--- Eventmon.register is stock nodemcu API
Eventmon.register = function(what, callback)
  assert(
    contains(eventmonEnum, what),
    "expected what one of " .. inspect(eventmonEnum) .. " but found " .. inspect(what)
  )
  assert(type(callback) == "function", "callback is not a function")
  nodemcu.eventmonCb[what] = callback
end

return Eventmon
