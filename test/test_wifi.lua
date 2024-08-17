--[[
License : GPLv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local lu = require("luaunit")
local nodemcu = require("nodemcu")

function testMissingConfigForSoftAP()
  nodemcu.reset()
  lu.assertEquals(wifi.getmode(), wifi.NULLMODE)
  wifi.setmode(wifi.SOFTAP)
  nodemcu.advanceTime(3)
  lu.assertEquals(wifi.getmode(), wifi.NULLMODE)
end

function testSetSoftAP()
  nodemcu.reset()
  lu.assertEquals(wifi.getmode(), wifi.NULLMODE)
  wifi.ap.config(wifi.ap.getdefaultconfig())
  wifi.setmode(wifi.SOFTAP)
  nodemcu.advanceTime(3)
  lu.assertEquals(wifi.getmode(), wifi.SOFTAP)
end

function testSetStation()
  nodemcu.reset()
  nodemcu.wifiSTA.AccessPoint = { ssid = "AA", pwd = "BB", bssid = "dummy", channel = 13,
    dhcp = { ip = "1.2.3.4", gateway = "1.2.3.255", netmask = "255.255.255.0" } }

  wifi.sta.config({ ssid = "AA", pwd = "BB", auto = false, save = false })
  wifi.setmode(wifi.STATION)
  wifi.sta.connect()
  nodemcu.advanceTime(100)
  lu.assertEquals(wifi.sta.status(), wifi.STA_GOTIP)
  lu.assertEquals(table.pack(wifi.sta.getip()), { "1.2.3.4", "255.255.255.0", "1.2.3.255", n = 3 })
end

function testSetStationIncomplete()
  nodemcu.reset()

  lu.assertEquals(wifi.getmode(), wifi.NULLMODE)
  wifi.sta.config(wifi.sta.getdefaultconfig(true))
  wifi.setmode(wifi.STATION)
  nodemcu.advanceTime(3)
  lu.assertEquals(wifi.getmode(), wifi.STATION)
  lu.assertEquals(wifi.sta.status(), wifi.STA_IDLE) -- no connect(), no cfg.auto=true

  wifi.sta.connect()
  nodemcu.advanceTime(3)
  lu.assertEquals(wifi.sta.status(), wifi.STA_APNOTFOUND) -- no AccessPoint defined
end

os.exit(lu.run())
