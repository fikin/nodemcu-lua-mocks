--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local inspect = require("inspect")
local nodemcu = require("nodemcu-module")
local Timer = require("Timer")
local Eventmon = require("wifi-eventmon")


local function queueEvent(fnc)
  Timer.createSingle(nodemcu.wifiSTA.ConnectTimeout, fnc):start()
end

-- ######################
-- ######################
-- ######################

-- implements stock nodemcu wifi.Sta API
---@class wifi_sta
local Sta = {}
Sta.__index = Sta

---stock API
---@param tbl boolean
---@return wifi_sta_config
Sta.getdefaultconfig = function(tbl)
  return {
    ssid = "undefined",
    pwd = "undefined",
    bssid_set = 0,
    bssid = "undefined",
  }
end

--- Sta.config is stock nodemcu API
---@param cfg wifi_sta_config
---@return boolean
Sta.config = function(cfg)
  if cfg == nil or cfg.ssid == nil then
    return false
  end
  nodemcu.wifiSTA.cfg = cfg
  -- control loop will take care of connection sequence if auto==true
  return true
end

--- Sta.getconfig is stock nodemcu API
---@param flg boolean
---@return nil|string|wifi_sta_config
---@return nil|string
Sta.getconfig = function(flg)
  assert(type(flg) == "boolean", "flg must be a boolean")
  if nodemcu.wifiSTA.cfg == nil then
    return nil, nil
  elseif flg then
    return nodemcu.wifiSTA.cfg
  else
    return nodemcu.wifiSTA.cfg.ssid, nodemcu.wifiSTA.cfg.pwd
  end
end

--- Sta.autoconnect is stock nodemcu API
---@param oneOrZero integer
Sta.autoconnect = function(oneOrZero)
  assert(nodemcu.wifiSTA.cfg, "call autoconnect() after config()")
  nodemcu.wifiSTA.cfg.auto = oneOrZero == 1 and true or false
end

--- Sta.changeap is stock nodemcu API
---@param ap_index integer
Sta.changeap = function(ap_index)
  assert(type(ap_index) == "number")
  assert(flg < 5 and flg > 0, "expects 0<ap_index<6 but found " .. inspect(ap_index))
  nodemcu.wifiSTA.ap_index = ap_index
end

--- Sta.getapindex is stock noemcu API
---@return integer
Sta.getapindex = function()
  return nodemcu.wifiSTA.ap_index
end

--- Sta.sethostname is stock nodemcu API
---@param name string
---@return boolean true if set ok, else false
Sta.sethostname = function(name)
  assert(type(name) == "string")
  nodemcu.wifiSTA.hostname = name
  return true
end

--- Sta.gethostname is stock nodemcu API
---@return string|nil
Sta.gethostname = function()
  return nodemcu.wifiSTA.hostname
end

--- Sta.getip is stock nodemcu API
---@return string|nil ip
---@return string|nil netmask
---@return string|nil gateway
Sta.getip = function()
  local i = nodemcu.wifiSTA.assignedIp
  if i then
    return i.ip, i.netmask, i.gateway
  end
  return nil, nil, nil
end

--- Sta.getap is stock nodemcu API
---@param cfg? {[string]:string}
---@param format? integer
---@param cb fun(ap:{[string]:string})
Sta.getap = function(cfg, format, cb)
  nodemcu.wifiSTA.GetAP(cfg, format, cb)
end

--- Sta.connect is stock nodemcu API
---@param cb? wifi_eventmon_fn
Sta.connect = function(cb)
  if type(cb) == "function" then
    Eventmon.register(Eventmon.STA_CONNECTED, cb)
  end
  nodemcu.fireWifiEvent(nodemcu.wifi.ConnectingEvent, {})
end

---stock API
---@param cb? wifi_eventmon_fn
Sta.disconnect = function(cb)
  if type(cb) == "function" then
    Eventmon.register(Eventmon.STA_DISCONNECTED, cb)
  end
  nodemcu.fireWifiEvent(wifi.eventmon.STA_DISCONNECTED, { reason = wifi.eventmon.reason.UNSPECIFIED })
end

---stock API
---@param staticIp wifi_ip
---@return boolean
Sta.setip = function(staticIp)
  nodemcu.wifiSTA.staticIp = staticIp
  return true
end

---stock API
---@param sleepType integer
---@return boolean
Sta.sleeptype = function(sleepType)
  nodemcu.wifiSTA.sleeptype = sleepType
  return true
end

---stock API
---@param mac string
---@return boolean
Sta.setmac = function(mac)
  nodemcu.wifiSTA.mac = mac
  return true
end

---stock API
---@return integer
Sta.status = function()
  return nodemcu.wifiSTA.status
end

return Sta
