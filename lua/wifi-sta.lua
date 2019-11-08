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

local function fire(what, T)
  if nodemcu.eventmonCb[what] then
    nodemcu.eventmonCb[what](T)
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
  nodemcu.wifiSTA.cfg = cfg
  assert(type(cfg.ssid) == "string", "cfg.ssid must be a string")
  assert(type(cfg.pwd) == "string", "cfg.pwd must be a string")
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
    return {ssid = nodemcu.wifiSTA.cfg.ssid, pwd = nodemcu.wifiSTA.cfg.pwd}
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

local function dispatchDisconnect(currWifiMode, optionalCb)
  assert(
    contains(wifiConstants.stationModeEnum, currWifiMode),
    "expected currWifiMode one of " .. inspect(wifiConstants.stationModeEnum) .. " but found " .. currWifiMode
  )
  queueEvent(
    function()
      fire(currWifiMode == wifi.STATION and Eventmon.STA_DISCONNECTED or Eventmon.AP_STADISCONNECTED, nil)
    end
  )
  if optionalCb ~= nil then
    queueEvent(
      function()
        optionalCb(
          {
            SSID = nodemcu.wifiSTA.cfg.ssid,
            BSSID = nodemcu.wifiSTA.bssid,
            channel = nodemcu.wifiSTA.channel
          }
        )
      end
    )
  end
end

local function dispatchConnect(currWifiMode, optionalCb)
  assert(
    contains(wifiConstants.stationModeEnum, currWifiMode),
    "expected currWifiMode one of " .. inspect(wifiConstants.stationModeEnum) .. " but found " .. currWifiMode
  )
  queueEvent(
    function()
      fire(currWifiMode == wifi.STATION and Eventmon.STA_CONNECTED or Eventmon.AP_STACONNECTED, nil)
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
  if optionalCb ~= nil then
    queueEvent(
      function()
        optionalCb(
          {
            SSID = nodemcu.wifiSTA.cfg.ssid,
            BSSID = nodemcu.wifiSTA.bssid,
            channel = nodemcu.wifiSTA.channel
          }
        )
      end
    )
  end
end

--- Sta.connect is stock nodemcu API
Sta.connect = function(cb)
  assert(nodemcu.wifiSTA.isConfigOk ~= nil)
  assert(not nodemcu.wifiSTA.alreadyConnected, "it seems Sta is already connected ")
  if nodemcu.wifiSTA.isConnectOk then
    nodemcu.wifiSTA.alreadyConnected = true
    dispatchConnect(wifi.getmode(), cb)
  else
    dispatchDisconnect(wifi.getmode(), cb)
  end
end

Sta.disconnect = function(cb)
  assert(nodemcu.wifiSTA.isConfigOk ~= nil)
  assert(nodemcu.wifiSTA.alreadyConnected, "it seems Sta is already disconnected")
  nodemcu.wifiSTA.alreadyConnected = false
  dispatchDisconnect(wifi.getmode(), cb)
end

return Sta
