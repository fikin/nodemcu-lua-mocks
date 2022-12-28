--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]

---@class wifi
---@field sta wifi_sta
---@field eventmon wifi_eventmon
---@field ap wifi_ap
---@field getmode fun():integer
---@field setmode fun(mode:integer)
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

wifi.wifiModeEnum = { wifi.STATION, wifi.SOFTAP, wifi.STATIONAP, wifi.NULLMODE }
wifi.wifiAuthEnum = { wifi.OPEN, wifi.WPA_PSK, wifi.WPA2_PSK, wifi.WPA_WPA2_PSK }
wifi.stationModeEnum = { wifi.STATION, wifi.STATIONAP }

---@class wifi_ip
---@field ip string
---@field netmask string
---@field gateway string

return wifi
