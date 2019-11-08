--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
-- ==========================
-- ==========================
-- ==========================
local lu = require("luaunit")
local socketFactory = require("socket")
local nodemcu = require("nodemcu")

function testSending()
    nodemcu.reset()

    local con = socketFactory(4444, "192.168.255.11")

    local sentCbWasCalled = 0
    local wasClosed = false
    con:on(
        "sent",
        function(con2)
            sentCbWasCalled = sentCbWasCalled + 1
        end
    )
    con:on(
        "receive",
        function(con2, data)
            lu.error("should not be here")
        end
    )
    con:on(
        "disconnection",
        function(con2)
            wasClosed = true
        end
    )

    con:connect(1111, "22.22.22.22")
    nodemcu.advanceTime(5)
    con:send("1")
    nodemcu.advanceTime(5)
    con:send("2")
    nodemcu.advanceTime(5)
    con:close()
    nodemcu.advanceTime(5)

    lu.assertEquals(2, sentCbWasCalled)
    lu.assertEquals(con:TD_PopSentData(), {"1", "2"})
    lu.assertTrue(wasClosed)
end

function testReceiving()
    nodemcu.reset()

    local con = socketFactory(4444, "192.168.255.11")

    local receivedData = {}
    con:on(
        "receive",
        function(sck, data)
            table.insert(receivedData, data)
        end
    )
    con:on(
        "sent",
        function(data)
            lu.error("should not be here")
        end
    )
    con:on(
        "disconnection",
        function(data)
            lu.error("should not be here")
        end
    )
    con:connect(1111, "22.22.22.22")
    nodemcu.advanceTime(5)
    con:TD_Send("1")
    nodemcu.advanceTime(5)
    con:TD_Send("2")
    nodemcu.advanceTime(5)

    lu.assertEquals(receivedData, {"1", "2"})
end

function testReceiveChunking()
    nodemcu.reset()

    local con = socketFactory(4444, "192.168.255.11")

    local wasConnected = false
    local wasClosed = false
    local receivedData = {}
    con:on(
        "connection",
        function(sck)
            wasConnected = true
        end
    )
    con:on(
        "receive",
        function(sck, data)
            assert(sck, "socket is nil")
            assert(data, "data is nil")
            table.insert(receivedData, data)
        end
    )
    con:on(
        "sent",
        function(sck)
            assert(sck, "socket is nil")
            lu.error("should not be here")
        end
    )
    con:on(
        "disconnection",
        function(sck)
            assert(sck, "socket is nil")
            wasClosed = true
        end
    )

    con:connect(1111, "22.22.22.22")
    lu.assertFalse(wasConnected)
    lu.assertFalse(wasClosed)
    nodemcu.advanceTime(5)
    lu.assertTrue(wasConnected)
    lu.assertFalse(wasClosed)

    con:TD_Send("123", 1)
    nodemcu.advanceTime(5)

    con:TD_Send("4")
    nodemcu.advanceTime(5)

    con:close()
    lu.assertFalse(wasClosed)
    nodemcu.advanceTime(5)
    lu.assertTrue(wasClosed)

    lu.assertEquals(receivedData, {"1", "2", "3", "4"})
end

function testConnectionConnect()
    nodemcu.reset()

    local localPort = 4444
    local localHost = "192.168.255.11"
    local con = socketFactory(localPort, localHost)

    local connectionWasCalled = false
    local disconnectionWasCalled = false
    local receivedData = {}
    con:on(
        "connection",
        function(sck)
            connectionWasCalled = true
        end
    )
    con:on(
        "receive",
        function(sck, data)
            table.insert(receivedData, data)
        end
    )
    con:on(
        "disconnection",
        function(sck)
            disconnectionWasCalled = true
        end
    )

    local remotePort = 1111
    local remoteHost = "22.22.22.22"
    con:connect(remotePort, remoteHost)
    nodemcu.advanceTime(5)
    con:TD_Send("1")
    nodemcu.advanceTime(5)
    con:TD_Send("2")
    nodemcu.advanceTime(5)
    con:close()
    nodemcu.advanceTime(3)

    lu.assertTrue(connectionWasCalled)
    lu.assertTrue(disconnectionWasCalled)
    lu.assertEquals(receivedData, {"1", "2"})
    local p, i = con:getaddr()
    lu.assertEquals(i, localHost)
    lu.assertEquals(p, localPort)
    local p, i = con:getpeer()
    lu.assertEquals(i, remoteHost)
    lu.assertEquals(p, remotePort)
end

function testConnectionTimeout()
    nodemcu.reset()

    local con = socketFactory(4444, "192.168.255.11", 1)

    local wasClosed = false
    con:on(
        "receive",
        function(sck, data)
            lu.error("should not be here")
        end
    )
    con:on(
        "sent",
        function(sck, data)
            lu.error("should not be here")
        end
    )
    con:on(
        "disconnection",
        function(sck)
            wasClosed = true
        end
    )
    con:connect(5555, "192.168.255.2")
    nodemcu.advanceTime(5)
    lu.assertTrue(wasClosed)
end

os.exit(lu.run())
