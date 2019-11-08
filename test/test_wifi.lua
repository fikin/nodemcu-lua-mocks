--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local lu = require("luaunit")
local nodemcu = require("nodemcu")

function testInit()
  nodemcu.reset()
  -- configure sta to fail on confgure
  nodemcu.wifiSTAsetConfigFnc(
    function(cfg)
      return false
    end
  )
  -- configure ap to fail on configure
  nodemcu.wifiAPsetConfigFnc(
    function(cfg)
      return false
    end
  )

  wifi.setmode(wifi.STATIONAP)
  lu.assertFalse(wifi.sta.config({}))
  lu.assertFalse(wifi.ap.config({}))
end

local function setupDefaultSta(failOnConnect, autoConnect)
  local flg = {
    gotConfigCalled = false,
    gotConnected = false,
    gotIP = false,
    gotDisconnected = false
  }

  -- configure sta to succeed configure, connect and obtaining an ip
  nodemcu.wifiSTAsetConfigFnc(
    function(cfg)
      flg.gotConfigCalled = true
      lu.assertEquals("AA", cfg.ssid)
      lu.assertEquals("BB", cfg.pwd)
      return true, failOnConnect, "A:B:C:D:E:F", 12, "1", "100", "255"
    end
  )

  -- test that wifi events were triggered ok
  wifi.eventmon.register(
    wifi.eventmon.STA_CONNECTED,
    function()
      flg.gotConnected = true
    end
  )
  wifi.eventmon.register(
    wifi.eventmon.STA_GOT_IP,
    function(T)
      flg.gotIP = true
      lu.assertEquals(T.IP, "1")
      lu.assertEquals(T.netmask, "100")
      lu.assertEquals(T.gateway, "255")
    end
  )
  wifi.eventmon.register(
    wifi.eventmon.STA_DISCONNECTED,
    function()
      flg.gotDisconnected = true
    end
  )
  local cfg = {ssid = "AA", pwd = "BB", auto = autoConnect, save = false}
  return cfg, flg
end

function testStationAutoconnectOk()
  nodemcu.reset()
  cfg, flg = setupDefaultSta(true, true)

  -- test
  wifi.setmode(wifi.STATION)
  wifi.sta.sethostname("hh")
  lu.assertTrue(wifi.sta.config(cfg))
  lu.assertTrue(flg.gotConfigCalled)
  nodemcu.advanceTime(nodemcu.wifiSTA.ConnectTimeout + 1)
  lu.assertTrue(flg.gotConnected)
  lu.assertFalse(flg.gotDisconnected)
  nodemcu.advanceTime(nodemcu.wifiSTA.ConnectTimeout + 1)
  lu.assertTrue(flg.gotIP)
  lu.assertFalse(flg.gotDisconnected)

  lu.assertEquals(wifi.sta.getconfig(true).ssid, cfg.ssid)
  lu.assertEquals(wifi.sta.getconfig(true).pwd, cfg.pwd)
  lu.assertEquals(wifi.sta.gethostname(), "hh")
  local ip, nm, gt = wifi.sta.getip()
  lu.assertEquals(ip, "1")
  lu.assertEquals(nm, "100")
  lu.assertEquals(gt, "255")
end

function testStationManualConnectOk()
  nodemcu.reset()
  cfg, flg = setupDefaultSta(true, false)

  -- test
  wifi.setmode(wifi.STATION)
  lu.assertTrue(wifi.sta.config(cfg))
  nodemcu.advanceTime(nodemcu.wifiSTA.ConnectTimeout + 1)
  lu.assertFalse(flg.gotConnected)
  lu.assertFalse(flg.gotDisconnected)
  wifi.sta.connect()
  nodemcu.advanceTime(nodemcu.wifiSTA.ConnectTimeout + 1)
  lu.assertTrue(flg.gotConnected)
  lu.assertFalse(flg.gotDisconnected)
  nodemcu.advanceTime(nodemcu.wifiSTA.ConnectTimeout + 1)
  lu.assertTrue(flg.gotIP)
  lu.assertFalse(flg.gotDisconnected)
end

function testStationAutoconnectErr()
  nodemcu.reset()
  cfg, flg = setupDefaultSta(false, true)

  wifi.setmode(wifi.STATION)
  lu.assertTrue(wifi.sta.config(cfg))
  nodemcu.advanceTime(nodemcu.wifiSTA.ConnectTimeout + 1)
  lu.assertTrue(flg.gotDisconnected)
end

function testAP()
  nodemcu.reset()
  nodemcu.wifiAPsetConfigFnc(
    function(cfg)
      lu.assertEquals("AA", cfg.ssid)
      lu.assertEquals("BB", cfg.pwd)
      return true
    end
  )

  wifi.setmode(wifi.SOFTAP)
  wifi.ap.setip({ip = "11", netmask = "22", gateway = "33"})
  local cfg = {ssid = "AA", pwd = "BB", save = false}
  lu.assertTrue(wifi.ap.config(cfg))

  lu.assertEquals(wifi.ap.getconfig(true).ssid, cfg.ssid)
  lu.assertEquals(wifi.ap.getconfig(true).pwd, cfg.pwd)
  local ip, nm, gt = wifi.ap.getip()
  lu.assertEquals(ip, "11")
  lu.assertEquals(nm, "22")
  lu.assertEquals(gt, "33")
end

local function assertHasGotIp(flg)
  lu.assertTrue(flg.gotConnected)
  lu.assertTrue(flg.gotIP)
  lu.assertFalse(flg.gotDisconnected)
end

function testDisconnectStation()
  nodemcu.reset()
  cfg, flg = setupDefaultSta(true, true)

  wifi.setmode(wifi.STATION)
  lu.assertTrue(wifi.sta.config(cfg))
  nodemcu.advanceTime(nodemcu.wifiSTA.ConnectTimeout + 3)
  assertHasGotIp(flg)
  wifi.sta.disconnect()
  nodemcu.advanceTime(nodemcu.wifiSTA.ConnectTimeout + 1)
  lu.assertTrue(flg.gotDisconnected)
end

function testChangeModeFromStaToAp()
  nodemcu.reset()
  cfg, flg = setupDefaultSta(true, true)

  wifi.setmode(wifi.STATION)
  lu.assertTrue(wifi.sta.config(cfg))
  nodemcu.advanceTime(nodemcu.wifiSTA.ConnectTimeout + 3)
  assertHasGotIp(flg)

  wifi.setmode(wifi.SOFTAP)

  nodemcu.advanceTime(nodemcu.wifiSTA.ConnectTimeout + 4)
  lu.assertTrue(flg.gotDisconnected)
end

function testStaGetAccessPointsEmpty()
  nodemcu.reset()
  wifi.setmode(wifi.STATION)
  wifi.sta.getap(
    {},
    1,
    function(tbl)
      lu.assertEquals(tbl, {})
    end
  )
end

function testStaGetAccessPointsAll()
  nodemcu.reset()
  nodemcu.wifiSTAsetAP({bssid1 = "ssid1, rssi1, authmode1, channel1", bssid2 = "ssid2, rssi2, authmode2, channel2"})
  wifi.sta.getap(
    {},
    1,
    function(tbl)
      lu.assertEquals(tbl, nodemcu.wifiSTA.accessPoints) -- don't mimic this, this field is internal
    end
  )
end

function testStaGetAccessPointsBySSID()
  nodemcu.reset()
  wifi.setmode(wifi.STATION)
  nodemcu.wifiSTAsetAP({bssid1 = "ssid1, rssi1, authmode1, channel1", bssid2 = "ssid2, rssi2, authmode2, channel2"})
  wifi.sta.getap(
    {ssid = "ssid2"},
    1,
    function(tbl)
      lu.assertEquals(tbl, {bssid2 = "ssid2, rssi2, authmode2, channel2"})
    end
  )
end

os.exit(lu.run())
