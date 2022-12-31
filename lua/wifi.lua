--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local nodemcu = require("nodemcu-module")
local Eventmon = require("wifi-eventmon")
local Ap = require("wifi-ap")
local Sta = require("wifi-sta")
local wifi = require("wifi-constants")

wifi.sta = Sta
wifi.eventmon = Eventmon
wifi.ap = Ap

--- wifi.setmode is stock nodemcu API
---@param mode integer
wifi.setmode = function(mode)
  local T = { new_mode = mode, old_mode = wifi.getmode() }
  if T.old_mode ~= T.new_mode then
    -- TODO in future : close AP
    -- close STA mode
    if (T.old_mode == wifi.STATIONAP or T.old_mode == wifi.STATION) and
        (T.new_mode == wifi.NULLMODE or T.new_mode == wifi.SOFTAP)
    then
      nodemcu.fireWifiEvent(wifi.eventmon.STA_DISCONNECTED, { reason = wifi.eventmon.reason.UNSPECIFIED })
    end
    -- change wifi mode
    nodemcu.fireWifiEvent(wifi.eventmon.WIFI_MODE_CHANGED, T)
  end
end

--- wifi.getmode is stock nodemcu API
---@return integer
wifi.getmode = function()
  return nodemcu.wifi.mode
end

---stock API
---@param country_info wifi_country
---@return boolean
wifi.setcountry = function(country_info)
  if wifi.getmode() == wifi.NULLMODE then
    nodemcu.wifi.country = country_info
    return true
  end
  return false
end

---stock API
---@param mode integer
wifi.setphymode = function(mode)
  nodemcu.wifi.phymode = mode
end

---stock API
---@param maxtxpower integer
wifi.setmaxtxpower = function(maxtxpower)
  nodemcu.wifi.maxpower = maxtxpower
end

return wifi
