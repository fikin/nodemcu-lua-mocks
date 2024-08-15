--[[
License : GPLv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
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
Eventmon.WIFI_MODE_CHANGED = 9

Eventmon.reason = {
  ["UNSPECIFIED"] = 1,
  ["AUTH_EXPIRE"] = 2,
  ["AUTH_LEAVE"] = 3,
  ["ASSOC_EXPIRE"] = 4,
  ["ASSOC_TOOMANY"] = 5,
  ["NOT_AUTHED"] = 6,
  ["NOT_ASSOCED"] = 7,
  ["ASSOC_LEAVE"] = 8,
  ["ASSOC_NOT_AUTHED"] = 9,
  ["DISASSOC_PWRCAP_BAD"] = 10,
  ["DISASSOC_SUPCHAN_BAD"] = 11,
  ["IE_INVALID"] = 13,
  ["MIC_FAILURE"] = 14,
  ["4WAY_HANDSHAKE_TIMEOUT"] = 15,
  ["GROUP_KEY_UPDATE_TIMEOUT"] = 16,
  ["IE_IN_4WAY_DIFFERS"] = 17,
  ["GROUP_CIPHER_INVALID"] = 18,
  ["PAIRWISE_CIPHER_INVALID"] = 19,
  ["AKMP_INVALID"] = 20,
  ["UNSUPP_RSN_IE_VERSION"] = 21,
  ["INVALID_RSN_IE_CAP"] = 22,
  ["802_1X_AUTH_FAILED"] = 23,
  ["CIPHER_SUITE_REJECTED"] = 24,
  ["BEACON_TIMEOUT"] = 200,
  ["NO_AP_FOUND"] = 201,
  ["AUTH_FAIL"] = 202,
  ["ASSOC_FAIL"] = 203,
  ["HANDSHAKE_TIMEOUT"] = 204,
}

Eventmon.fire = function(what, ...)
  if nodemcu.wifiEventmonTbl[what] then
    nodemcu.wifiEventmonTbl[what](...)
  end
end

---Eventmon.register is stock nodemcu API
---@param what integer
---@param callback wifi_eventmon_fn
Eventmon.register = function(what, callback)
  nodemcu.wifiEventmonTbl[what] = callback
end

---stock API
---@param what integer
Eventmon.unregister = function(what)
  nodemcu.wifiEventmonTbl[what] = nil
end

return Eventmon
