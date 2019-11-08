--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
wifi = {}
wifi.__index = wifi

wifi.NULLMODE = 0
wifi.STATION = 1
wifi.SOFTAP = 2
wifi.STATIONAP = 3

wifi.OPEN = 14
wifi.WPA_PSK = 15
wifi.WPA2_PSK = 16
wifi.WPA_WPA2_PSK = 17

wifi.wifiModeEnum = {wifi.STATION, wifi.SOFTAP, wifi.STATIONAP, wifi.NULLMODE}
wifi.wifiAuthEnum = {wifi.OPEN, wifi.WPA_PSK, wifi.WPA2_PSK, wifi.WPA_WPA2_PSK}
wifi.stationModeEnum = {wifi.STATION, wifi.STATIONAP}

return wifi
