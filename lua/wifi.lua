--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local inspect = require("inspect")
local contains = require("contains")
local nodemcu = require("nodemcu-module")
local Eventmon = require("wifi-eventmon")
local Ap = require("wifi-ap")
local Sta = require("wifi-sta")
local wifi = require("wifi-constants")

-- ========================
-- ========================
-- ========================

wifi.sta = Sta
wifi.eventmon = Eventmon
wifi.ap = Ap

--- wifi.setmode is stock nodemcu API
wifi.setmode = function(mode)
  assert(contains(wifi.wifiModeEnum, mode), "expected model one of " .. inspect(wifi.wifiModeEnum) .. " but found " .. mode)
  if mode == wifi.SOFTAP then
    if nodemcu.wifi.mode == wifi.STATION or nodemcu.wifi.mode == wifi.STATIONAP then
      wifi.sta.disconnect()
    end
  end
  nodemcu.wifi.mode = mode
end

--- wifi.getmode is stock nodemcu API
wifi.getmode = function()
  return nodemcu.wifi.mode
end

return wifi
