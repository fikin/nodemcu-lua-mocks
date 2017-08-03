--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]

wifi = {}
wifi.__index = wifi

require('Timer')

wifi.NULLMODE = 0
wifi.STATION = 1
wifi.SOFTAP = 2
wifi.STATIONAP = 3

wifi.OPEN = 14

wifi.TestData = {}
wifi.TestData.reset = function()
  wifi.TestData.mode = wifi.NULLMODE
  wifi.TestData.sta = {
    GotIpTimeoutMs = 1,
    hostname = nil,
    autoconnect = false,
    ip = { ip = null, netmask = nil, gateway = nil },
    cfg = {},
    isConfigured = false,
    onConfigureCb = function(cfg) return false end,
    onConnectCb = function() return true end, -- return true if connect is ok, else false
    onGetIp = function() return { ip = '192.168.255.2', netmask = '255.255.255.0', gateway = '192.168.255.1' } end
  }
  wifi.TestData.ap = {
    ip = { ip = null, netmask = nil, gateway = nil },
    cfg = {},
    isConfigured = false,
    onConfigureCb = function(cfg) return false end
  }
  wifi.TestData.eventsCb = {}
  Timer.reset()
end
wifi.TestData.reset()

wifi.setmode = function(mode)
  if mode == wifi.SOFTAP and (wifi.TestData.mode == wifi.STATION or wifi.TestData.mode == wifi.STATIONAP) then
    wifi.sta.disconnect()
  end
  wifi.TestData.mode = mode
end
wifi.getmode = function() return wifi.TestData.mode; end

local function fire(what,T)
  if wifi.TestData.eventsCb[what] then
    wifi.TestData.eventsCb[what](T)
  end
end

local Eventmon = {}
Eventmon.stasgottipa_got_ip = 1
Eventmon.STA_CONNECTED       = 1
Eventmon.STA_DISCONNECTED    = 2
Eventmon.STA_AUTHMODE_CHANGE = 3
Eventmon.STA_GOT_IP          = 4
Eventmon.STA_DHCP_TIMEOUT    = 5
Eventmon.AP_STACONNECTED     = 6
Eventmon.AP_STADISCONNECTED  = 7
Eventmon.AP_PROBEREQRECVED   = 8
Eventmon.register = function(what, callback)
  wifi.TestData.eventsCb[what] = callback;
end

local Sta = {}
Sta.config = function(cfg) 
  wifi.TestData.sta.cfg = cfg
  if wifi.TestData.sta.onConfigureCb(cfg) then
    wifi.TestData.sta.isConfigured = true
    if cfg.auto then
      Sta.connect()
    end
    return true
  else
    wifi.TestData.sta.isConfigured = false
    return false
  end
end
Sta.getconfig = function(flg)
  if flg then
    return { ssid = wifi.TestData.sta.cfg.ssid, pwd = wifi.TestData.sta.cfg.pwd }
  else
    return wifi.TestData.sta.cfg.ssid, wifi.TestData.sta.cfg.pwd
  end 
end
Sta.autoconnect = function(oneOrZero) wifi.TestData.sta.autoconnect = oneOrZero end
Sta.sethostname = function(name) wifi.TestData.sta.hostname = name; end
Sta.gethostname = function() return wifi.TestData.sta.hostname end
Sta.getip = function() return wifi.TestData.sta.ip.ip, wifi.TestData.sta.ip.netmask, wifi.TestData.sta.ip.gateway end
local function queueEvent(fnc)
  Timer.createSingle( wifi.TestData.sta.GotIpTimeoutMs, fnc):start()
end
Sta.connect = function()
  if wifi.TestData.sta.isConfigured then
    if wifi.TestData.sta.onConnectCb() then
      local gotIp = function() queueEvent( function() 
          wifi.TestData.sta.ip = wifi.TestData.sta.onGetIp()
          fire(Eventmon.STA_GOT_IP, { 
            IP = wifi.TestData.sta.ip.ip, 
            netmask = wifi.TestData.sta.ip.netmask, 
            gateway = wifi.TestData.sta.ip.gateway 
          })
        end) 
      end
      if wifi.getmode() == wifi.STATION then queueEvent(function() fire(Eventmon.STA_CONNECTED, nil) gotIp() end)
      elseif wifi.getmode() == wifi.STATIONAP then queueEvent(function() fire(Eventmon.AP_STACONNECTED, nil) gotIp() end) end
    else
      if wifi.getmode() == wifi.STATION then queueEvent(function() fire(Eventmon.STA_DISCONNECTED, nil) end)
      elseif wifi.getmode() == wifi.STATIONAP then queueEvent(function() fire(Eventmon.AP_STADISCONNECTED, nil) end) end
    end
  end
end
Sta.disconnect = function() 
  local fnc = function() wifi.TestData.sta.ip = { ip = null, netmask = nil, gateway = nil } end
  if wifi.getmode() == wifi.STATION then queueEvent(function() fire(Eventmon.STA_DISCONNECTED, nil) fnc() end)
  elseif wifi.getmode() == wifi.STATIONAP then queueEvent(function() fire(Eventmon.AP_STADISCONNECTED, nil) fnc() end) end
end

local Ap = {}
Ap.setip = function(ip) wifi.TestData.ap.ip = ip end
Ap.getip = function() return wifi.TestData.ap.ip.ip, wifi.TestData.ap.ip.netmask, wifi.TestData.ap.ip.gateway end
Ap.config = function(cfg)
  wifi.TestData.ap.cfg = cfg
  if wifi.TestData.ap.onConfigureCb(cfg) then
    wifi.TestData.ap.isConfigured = true
    return true
  else
    wifi.TestData.ap.isConfigured = false
    return false
  end
end
Ap.getconfig = function(flg)
  if flg then
    return { ssid = wifi.TestData.ap.cfg.ssid, pwd = wifi.TestData.ap.cfg.pwd }
  else
    return wifi.TestData.ap.cfg.ssid, wifi.TestData.ap.cfg.pwd
  end 
end

wifi.sta = Sta
wifi.eventmon = Eventmon
wifi.ap = Ap

return wifi