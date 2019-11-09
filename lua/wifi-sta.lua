--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local inspect = require("inspect")
local contains = require("contains")
local nodemcu = require("nodemcu-module")
local Timer = require("Timer")
local wifiConstants = require("wifi-constants")
local Eventmon = require("wifi-eventmon")

-- ######################
-- ######################
-- ######################

local function fire(what, ...)
  if nodemcu.eventmonCb[what] then
    nodemcu.eventmonCb[what](...)
  end
end

local function queueEvent(fnc)
  Timer.createSingle(nodemcu.wifiSTA.ConnectTimeout, fnc):start()
end

-- ######################
-- ######################
-- ######################

-- implements stock nodemcu wifi.Sta API
local Sta = {}
Sta.__index = Sta

--- Sta.config is stock nodemcu API
Sta.config = function(cfg)
  if cfg == nil or cfg.ssid == nil then
    return false
  end
  assert(type(cfg.ssid) == "string", "cfg.ssid must be a string")
  assert(type(cfg.pwd) == "string", "cfg.pwd must be a string")
  nodemcu.wifiSTA.cfg = cfg
  if type(cfg.connected_cb) == "function" then
    Eventmon.register(Eventmon.STA_CONNECTED, cfg.connected_cb)
  end
  if type(cfg.disconnected_cb) == "function" then
    Eventmon.register(Eventmon.STA_DISCONNECTED, cfg.disconnected_cb)
  end
  if type(cfg.authmode_change_cb) == "function" then
    Eventmon.register(Eventmon.STA_AUTHMODE_CHANGE, cfg.authmode_change_cb)
  end
  if type(cfg.got_ip_cb) == "function" then
    Eventmon.register(Eventmon.STA_GOT_IP, cfg.got_ip_cb)
  end
  if type(cfg.dhcp_timeout_cb) == "function" then
    Eventmon.register(Eventmon.STA_DHCP_TIMEOUT, cfg.dhcp_timeout_cb)
  end
  nodemcu.wifiSTA.ssid = cfg.ssid
  nodemcu.wifiSTA.pwd = cfg.pwd
  nodemcu.wifiSTA.isConfigOk,
    nodemcu.wifiSTA.isConnectOk,
    nodemcu.wifiSTA.bssid,
    nodemcu.wifiSTA.channel,
    nodemcu.wifiSTA.ip,
    nodemcu.wifiSTA.netmask,
    nodemcu.wifiSTA.gateway = nodemcu.wifiSTA.configStaFnc(cfg)
  if nodemcu.wifiSTA.isConfigOk and cfg.auto then
    queueEvent(
      function()
        Sta.connect()
      end
    )
  end
  return nodemcu.wifiSTA.isConfigOk
end

--- Sta.getconfig is stock nodemcu API
Sta.getconfig = function(flg)
  assert(type(flg) == "boolean", "flg must be a boolean")
  if nodemcu.wifiSTA.cfg == nil then
    return nil
  elseif flg then
    return {ssid = nodemcu.wifiSTA.ssid, pwd = nodemcu.wifiSTA.pwd}
  else
    return nodemcu.wifiSTA.cfg
  end
end

--- Sta.autoconnect is stock nodemcu API
Sta.autoconnect = function(oneOrZero)
  nodemcu.wifiSTA.autoconnect = oneOrZero
end

--- Sta.changeap is stock nodemcu API
Sta.changeap = function(ap_index)
  assert(type(ap_index) == "number")
  assert(flg < 5 and flg > 0, "expects 0<ap_index<6 but found " .. inspect(ap_index))
  nodemcu.wifiSTA.ap_index = ap_index
end

--- Sta.getapindex is stock noemcu API
Sta.getapindex = function()
  return nodemcu.wifiSTA.ap_index
end

--- Sta.sethostname is stock nodemcu API
Sta.sethostname = function(name)
  assert(type(name) == "string")
  nodemcu.wifiSTA.hostname = name
end

--- Sta.gethostname is stock nodemcu API
Sta.gethostname = function()
  return nodemcu.wifiSTA.hostname
end

--- Sta.getip is stock nodemcu API
Sta.getip = function()
  return nodemcu.wifiSTA.ip, nodemcu.wifiSTA.netmask, nodemcu.wifiSTA.gateway
end

--- Sta.getap is stock nodemcu API
Sta.getap = function(cfg, format, cb)
  if type(cfg) == "function" then
    cb = cfg
    cfg = nil
  end
  cfg = cfg or {}
  format = format or 0
  assert(format == 1, "supported is format=1 only")
  assert(type(cb) == "function", "cb must be defined")
  local function filterRes(cfg, tbl)
    local function filterMatched(cfg, bssid, val)
      if cfg.bssid and cfg.bssid ~= bssid then
        return false
      end
      local ssid, rssi, authmode, channel = string.match(val, "([^,]+),([^,]+),([^,]+),([^,]*)")
      if cfg.ssid and cfg.ssid ~= ssid then
        return false
      end
      if cfg.channel and cfg.channel ~= channel then
        return false
      end
      return true
    end
    local ret = {}
    for bssid, v in pairs(tbl) do
      if filterMatched(cfg, bssid, v) then
        ret[bssid] = v
      end
    end
    return ret
  end
  cb(filterRes(cfg, nodemcu.wifiSTA.accessPoints))
end

local function dispatchDisconnect(currWifiMode)
  assert(
    contains(wifiConstants.stationModeEnum, currWifiMode),
    "expected currWifiMode one of " .. inspect(wifiConstants.stationModeEnum) .. " but found " .. currWifiMode
  )
  queueEvent(
    function()
      fire(currWifiMode == wifi.STATION and Eventmon.STA_DISCONNECTED or Eventmon.AP_STADISCONNECTED, nil)
    end
  )
end

local function dispatchConnect(currWifiMode)
  assert(
    contains(wifiConstants.stationModeEnum, currWifiMode),
    "expected currWifiMode one of " .. inspect(wifiConstants.stationModeEnum) .. " but found " .. currWifiMode
  )
  queueEvent(
    function()
      fire(
        currWifiMode == wifi.STATION and Eventmon.STA_CONNECTED or Eventmon.AP_STACONNECTED,
        {
          SSID = nodemcu.wifiSTA.ssid,
          BSSID = nodemcu.wifiSTA.bssid,
          channel = nodemcu.wifiSTA.channel
        }
      )
      queueEvent(
        function()
          fire(
            Eventmon.STA_GOT_IP,
            {
              IP = nodemcu.wifiSTA.ip,
              netmask = nodemcu.wifiSTA.netmask,
              gateway = nodemcu.wifiSTA.gateway
            }
          )
        end
      )
    end
  )
end

--- Sta.connect is stock nodemcu API
Sta.connect = function(cb)
  assert(nodemcu.wifiSTA.isConfigOk ~= nil)
  assert(not nodemcu.wifiSTA.alreadyConnected, "it seems Sta is already connected ")
  if type(cb) == "function" then
    Eventmon.register(Eventmon.STA_CONNECTED, cb)
  end
  if nodemcu.wifiSTA.isConnectOk then
    nodemcu.wifiSTA.alreadyConnected = true
    dispatchConnect(wifi.getmode())
  else
    dispatchDisconnect(wifi.getmode())
  end
end

Sta.disconnect = function(cb)
  assert(nodemcu.wifiSTA.isConfigOk ~= nil)
  assert(nodemcu.wifiSTA.alreadyConnected, "it seems Sta is already disconnected")
  nodemcu.wifiSTA.alreadyConnected = false
  dispatchDisconnect(wifi.getmode(), cb)
end

return Sta
