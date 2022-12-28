--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local modname = ...
local contains = require("contains")
local inspect = require("inspect")
local nodemcu = require("nodemcu-module")

---Eventmon is stock nodemcu API
---@class wifi_eventmon
local Eventmon = {}
Eventmon.__index = Eventmon

---@alias wifi_eventmon_fn fun(T:table)

Eventmon.STA_CONNECTED = 1
Eventmon.STA_DISCONNECTED = 2
Eventmon.STA_AUTHMODE_CHANGE = 3
Eventmon.STA_GOT_IP = 4
Eventmon.STA_DHCP_TIMEOUT = 5
Eventmon.AP_STACONNECTED = 6
Eventmon.AP_STADISCONNECTED = 7
Eventmon.AP_PROBEREQRECVED = 8

Eventmon.fire = function(what, ...)
  if nodemcu.eventmonCb[what] then
    nodemcu.eventmonCb[what](...)
  end
end

---Eventmon.register is stock nodemcu API
---@param what integer
---@param callback wifi_eventmon_fn
Eventmon.register = function(what, callback)
  nodemcu.eventmonCb[what] = callback
end

return Eventmon
