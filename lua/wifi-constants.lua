--[[
License : GPLv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]

---@class wifi_country
---@field country string
---@field policy string
---@field end_ch integer
---@field start_ch integer

---@class wifi
---@field sta wifi_sta
---@field eventmon wifi_eventmon
---@field ap wifi_ap
---@field getmode fun():integer
---@field setmode fun(mode:integer)
---@field setcountry fun(country:wifi_country):boolean
---@field setphymode fun(mode:integer)
---@field setmaxtxpower fun(maxtxpower:integer)
wifi = {}
wifi.__index = wifi

wifi.NULLMODE = 0
wifi.STATION = 1
wifi.SOFTAP = 2
wifi.STATIONAP = 3

wifi.STA_IDLE = 5
wifi.STA_CONNECTING = 6
wifi.STA_WRONGPWD = 7
wifi.STA_APNOTFOUND = 8
wifi.STA_FAIL = 9
wifi.STA_GOTIP = 10

wifi.PHYMODE_B = 11
wifi.PHYMODE_G = 12
wifi.PHYMODE_N = 13

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

---@class wifi_ap_config
---@field ssid string
---@field pwd string
---@field auth integer
---@field bssid_set integer

---@class wifi_sta_config
---@field ssid string
---@field pwd string
---@field auto boolean
---@field save boolean

---@alias wifi_ap_clients {[string]:string}

return wifi
