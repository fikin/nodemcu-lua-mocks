--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local lu = require("luaunit")
local nodemcu = require("nodemcu")
local inspect = require("inspect")

function testTcpListener()
  nodemcu.reset()

  local listener = net.createServer(net.TCP, 1000)

  local connectionReceived = false
  local onIncomingConnection = function(con)
    lu.assertNotIsNil(con)
    connectionReceived = true
  end

  listener:listen(11, "192.168.255.2", onIncomingConnection)

  local p, i = listener:getaddr()
  lu.assertEquals(i, "192.168.255.2")
  lu.assertEquals(p, 11)

  local con = listener:TD_ConnectFrom(44, "33.33.33.33")
  lu.assertTrue(connectionReceived)
end

function testTcpServer()
  nodemcu.reset()

  local closed = false
  local onIncomingConnection = function(con)
    lu.assertNotNil(con)
    local ready = false
    con:on(
      "receive",
      function(sck, data)
        lu.assertNotNil(sck)
        lu.assertNotNil(data)
        sck:send("1-" .. data)
        ready = data == "34"
      end
    )
    con:on(
      "sent",
      function(sck)
        lu.assertNotNil(sck)
        if ready then
          sck:close()
        end
      end
    )
    con:on(
      "disconnection",
      function(sck)
        closed = true
      end
    )
  end

  local srv = net.createServer(net.TCP, 1)

  srv:listen(22, "192.168.255.2", onIncomingConnection)

  local conn = srv:TD_ConnectFrom(44, "33.33.33.33")
  nodemcu.advanceTime(10)
  conn:TD_Send("12")
  nodemcu.advanceTime(10)
  conn:TD_Send("34")
  nodemcu.advanceTime(10)

  lu.assertTrue(closed)
  lu.assertEquals(conn:TD_PopSentData(), {"1-12", "1-34"})
end

os.exit(lu.run())
