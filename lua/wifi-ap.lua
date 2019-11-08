--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local nodemcu = require("nodemcu-module")

local Ap = {}
Ap.__index = Ap

--- Ap.getclient is stock nodemcu API
Ap.getclient = function()
  return nodemcu.wifiAP.clients
end

--- Ap.getdefaultconfig is stock nodemcu API
Ap.getdefaultconfig = function()
  return {
    ssid = "NODEMCU_MOCK",
    pwd = "public",
    auth = wiki.OPEN,
    bssid_set = 0
  }
end

--- Ap.setip is stock nodemcu API
Ap.setip = function(cfg)
  assert(cfg ~= nil, "cfg must be valid object")
  nodemcu.wifiAP.ip = cfg.ip
  nodemcu.wifiAP.netmask = cfg.netmask
  nodemcu.wifiAP.gateway = cfg.gateway
end

--- Ap.getip is stock nodemcu API
Ap.getip = function()
  return nodemcu.wifiAP.ip, nodemcu.wifiAP.netmask, nodemcu.wifiAP.gateway
end

--- Ap.getmac is stock nodemcu API
Ap.getmac = function()
  return nodemcu.wifiAP.mac
end

--- Ap.setmac is stock nodemcu API
Ap.setmac = function(mac)
  lu.assertIsString(flg)
  nodemcu.wifiAP.mac = mac
end

--- Ap.config is stock nodemcu API
Ap.config = function(cfg)
  if cfg == nil or cfg.ssid == nil then
    return false
  end
  nodemcu.wifiAP.cfg = cfg
  return nodemcu.wifiAP.configApFnc(cfg)
end

--- Ap.getconfig implements stock nodemcu wifi.ap API
Ap.getconfig = function(flg)
  assert(type(flg) == "boolean", "flg has to be boolean")
  if nodemcu.wifiAP.cfg == nil then
    return nil, nil
  elseif flg then
    return nodemcu.wifiAP.cfg
  else
    return nodemcu.wifiAP.cfg.ssid, nodemcu.wifiAP.cfg.pwd
  end
end

-- ========================
-- ========================
-- ========================

return Ap
