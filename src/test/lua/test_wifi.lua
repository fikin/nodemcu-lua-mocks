--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]

luaunit = require('luaunit')

require('wifi')

function testInit()
  wifi.TestData.reset()
  wifi.setmode(wifi.STATIONAP)
  luaunit.assertFalse( wifi.sta.config({}) )
  luaunit.assertFalse( wifi.ap.config({}) )
end

function testStationAutoconnectOk()
  wifi.TestData.reset()
  
  wifi.TestData.sta.onConfigureCb = function(cfg) return true end
  wifi.TestData.sta.onConnectCb = function() return true end
  wifi.TestData.sta.onGetIp = function() return { ip = '1', netmask = '100', gateway = '255' } end
  
  local gotConnected = false
  local gotIP = false
  wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, function() gotConnected = true end)
  wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, function(T) 
    gotIP = true 
    luaunit.assertEquals(T.IP,'1')
    luaunit.assertEquals(T.netmask,'100')
    luaunit.assertEquals(T.gateway,'255')
  end)
  wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, function() error('We should not be here.') end)
  
  wifi.setmode(wifi.STATION)
  wifi.sta.sethostname('aa')
  local cfg = { ssid = 'AA', pwd = 'BB', auto = true, save = false }
  luaunit.assertTrue( wifi.sta.config( cfg ) )
  Timer.joinAll(wifi.TestData.sta.GotIpTimeoutMs + 1)
  luaunit.assertTrue( gotConnected )
  Timer.joinAll(wifi.TestData.sta.GotIpTimeoutMs + 1)
  luaunit.assertTrue( gotIP )
  
  luaunit.assertEquals(wifi.sta.getconfig(true).ssid, cfg.ssid)
  luaunit.assertEquals(wifi.sta.getconfig(true).pwd, cfg.pwd)
  luaunit.assertEquals(wifi.sta.gethostname(), 'aa')
  local ip, nm, gt = wifi.sta.getip()
  luaunit.assertEquals(ip,'1')
  luaunit.assertEquals(nm,'100')
  luaunit.assertEquals(gt,'255')
end

function testStationManualConnectOk()
  wifi.TestData.reset()
  
  wifi.TestData.sta.onConfigureCb = function(cfg) return true end
  wifi.TestData.sta.onConnectCb = function() return true end
  wifi.TestData.sta.onGetIp = function() return { ip = '1', netmask = '100', gateway = '255' } end
  
  local gotConnected = false
  local gotIP = false
  wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, function() gotConnected = true end)
  wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, function(IP) gotIP = true end)
  wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, function() error('We should not be here.') end)
  
  wifi.setmode(wifi.STATION)
  luaunit.assertTrue( wifi.sta.config( { ssid = 'AA', pwd = 'BB', auto = false, save = false } ) )
  Timer.joinAll(wifi.TestData.sta.GotIpTimeoutMs + 1)
  luaunit.assertFalse( gotConnected )
  wifi.sta.connect()
  Timer.joinAll(wifi.TestData.sta.GotIpTimeoutMs + 1)
  luaunit.assertTrue( gotConnected )
  Timer.joinAll(wifi.TestData.sta.GotIpTimeoutMs + 1)
  luaunit.assertTrue( gotIP )
end

function testStationAutoconnectErr()
  wifi.TestData.reset()
  
  wifi.TestData.sta.onConfigureCb = function(cfg) return true end
  wifi.TestData.sta.onConnectCb = function() return false end
  wifi.TestData.sta.onGetIp = function() error('We should not be here.') end
  
  local gotDisconnected = false
  wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, function() error('We should not be here.') end)
  wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, function(IP) error('We should not be here.') end)
  wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, function() gotDisconnected = true end)
  
  wifi.setmode(wifi.STATION)
  luaunit.assertTrue( wifi.sta.config( { ssid = 'AA', pwd = 'BB', auto = true, save = false } ) )
  Timer.joinAll(wifi.TestData.sta.GotIpTimeoutMs + 1)
  luaunit.assertTrue( gotDisconnected )
end

function testAP()
  wifi.TestData.reset()
  
  wifi.TestData.ap.onConfigureCb = function(cfg) return true end
  
  wifi.setmode(wifi.SOFTAP)
  wifi.ap.setip({ ip='11', netmask='22', gateway='33'})
  local cfg = { ssid = 'AA', pwd = 'BB', save = false }
  luaunit.assertTrue( wifi.ap.config( cfg ) )
  
  luaunit.assertEquals(wifi.ap.getconfig(true).ssid, cfg.ssid)
  luaunit.assertEquals(wifi.ap.getconfig(true).pwd, cfg.pwd)
  local ip, nm, gt = wifi.ap.getip()
  luaunit.assertEquals(ip,'11')
  luaunit.assertEquals(nm,'22')
  luaunit.assertEquals(gt,'33')
end

function testDisconnectStation()
  wifi.TestData.reset()
  
  wifi.TestData.sta.onConfigureCb = function(cfg) return true end
  
  local gotDisconnected = false
  wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, function() gotDisconnected = true end)
  
  wifi.setmode(wifi.STATION)
  luaunit.assertTrue( wifi.sta.config( { ssid = 'AA', pwd = 'BB', auto = true, save = false } ) )
  Timer.joinAll(wifi.TestData.sta.GotIpTimeoutMs + 1)
  wifi.sta.disconnect()
  Timer.joinAll(wifi.TestData.sta.GotIpTimeoutMs + 1)
  luaunit.assertTrue( gotDisconnected )
end

function testChangeModeFromStaToAp()
  wifi.TestData.reset()
  
  wifi.TestData.sta.onConfigureCb = function(cfg) return true end
  
  local gotDisconnected = false
  wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, function() gotDisconnected = true end)
  
  wifi.setmode(wifi.STATION)
  luaunit.assertTrue( wifi.sta.config( { ssid = 'AA', pwd = 'BB', auto = true, save = false } ) )
  Timer.joinAll(wifi.TestData.sta.GotIpTimeoutMs + 1)

  wifi.TestData.ap.onConfigureCb = function(cfg) return true end
  wifi.setmode(wifi.SOFTAP)

  Timer.joinAll(wifi.TestData.sta.GotIpTimeoutMs + 1)
  luaunit.assertTrue( gotDisconnected )
end

os.exit( luaunit.LuaUnit.run() )
