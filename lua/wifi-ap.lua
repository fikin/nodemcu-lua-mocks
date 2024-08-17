--[[
License : GPLv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local nodemcu = require("nodemcu-module")
local wiki = require("wifi-constants")

---@class wifi_ap_dhcp
local Dhcp = {}
Dhcp.__index = Dhcp

---stock API
---@param dhcp_config table
---@return pool_startip string
---@return pool_endip string
Dhcp.config = function(dhcp_config)
  nodemcu.wifiAP.dhcpConfig = dhcp_config
  return dhcp_config.start or "0.0.0.128", "0.0.0.255"
end

---stock API
---@return boolean
Dhcp.start = function()
  return true
end

---stock API
---@return boolean
Dhcp.stop = function()
  return true
end

---@class wifi_ap
local Ap = {
  dhcp = Dhcp
}
Ap.__index = Ap

---Ap.getclient is stock nodemcu API
---@return wifi_ap_clients
Ap.getclient = function()
  return nodemcu.wifiAP.clients
end

--- Ap.getdefaultconfig is stock nodemcu API
---@return wifi_ap_config
Ap.getdefaultconfig = function()
  return {
    ssid = "NODEMCU_MOCK",
    pwd = "public",
    auth = wiki.OPEN,
    bssid_set = 0
  }
end

--- Ap.setip is stock nodemcu API
---@param ip wifi_ip
---@return boolean
Ap.setip = function(ip)
  nodemcu.wifiAP.staticIp = ip
  return true
end

--- Ap.getip is stock nodemcu API
---@return string|nil ip
---@return string|nil netmask
---@return string|nil gateway
Ap.getip = function()
  local i = nodemcu.wifiAP.staticIp
  if i then
    return i.ip, i.netmask, i.gateway
  end
  return nil, nil, nil
end

--- Ap.getmac is stock nodemcu API
---@return string
Ap.getmac = function()
  return nodemcu.wifiAP.mac
end

--- Ap.setmac is stock nodemcu API
---@param mac string
---@return boolean
Ap.setmac = function(mac)
  nodemcu.wifiAP.mac = mac
  return true
end

--- Ap.config is stock nodemcu API
---@param cfg wifi_ap_config
---@return boolean
Ap.config = function(cfg)
  if not (cfg or cfg.ssid) then
    return false
  end
  nodemcu.wifiAP.cfg = cfg
  return true
end

--- Ap.getconfig implements stock nodemcu wifi.ap API
---@param flg boolean
---@return wifi_ap_config|string|nil ssid
---@return string|nil pwd
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
