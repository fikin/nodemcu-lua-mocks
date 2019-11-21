--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
-- ==========================
-- ==========================
-- ==========================
local lu = require("luaunit")
local nodemcu = require("nodemcu")
local tools = require("tools")

function testConnectTo()
    nodemcu.reset()

    local con = net.createConnection(net.TCP, false)
    local w = tools.wrapConnection(con)

    local s2, w2
    nodemcu.net_tcp_listener_new(
        1111,
        "22.22.22.22",
        function(con2)
            assert(con2)
            s2 = con2
            w2 =
                tools.wrapConnection(
                s2,
                {
                    receive = function(con3, data)
                        con3:send(data .. "1")
                    end
                }
            )
            return s2
        end
    )

    con:connect(1111, "22.22.22.22")

    nodemcu.advanceTime(5)
    lu.assertEquals(table.pack(con:getaddr()), table.pack(s2:getpeer()))
    lu.assertEquals(table.pack(con:getpeer()), table.pack(s2:getaddr()))

    nodemcu.advanceTime(5)
    con:send("1")
    nodemcu.advanceTime(5)
    con:send("2")
    nodemcu.advanceTime(5)
    con:close()
    nodemcu.advanceTime(5)

    lu.assertEquals(w.sent, 2)
    lu.assertEquals(w.received, {"11", "21"})
    lu.assertEquals(w.connection, 1)
    lu.assertEquals(w.disconnection, 1)
    lu.assertEquals(w.reconnection, 0)

    lu.assertEquals(w2.sent, 2)
    lu.assertEquals(w2.received, {"1", "2"})
    lu.assertEquals(w2.connection, 1)
    lu.assertEquals(w2.disconnection, 1)
    lu.assertEquals(w2.reconnection, 0)
end

function testTCPNetFrameSize()
    nodemcu.reset()
    nodemcu.net_tcp_framesize = 1

    local con = net.createConnection(net.TCP, false)

    local s2, w2
    nodemcu.net_tcp_listener_new(
        1111,
        "22.22.22.22",
        function(con2)
            s2 = con2
            w2 = tools.wrapConnection(s2)
            return s2
        end
    )

    con:connect(1111, "22.22.22.22")
    nodemcu.advanceTime(5)
    con:send("123")
    nodemcu.advanceTime(5)
    con:close()
    nodemcu.advanceTime(5)

    lu.assertEquals(w2.received, {"1", "2", "3"})
end

function testConnectionTimeout()
    nodemcu.reset()

    nodemcu.net_tcp_idleiotimeout = 1

    local con = net.createConnection(net.TCP, false)
    local w = tools.wrapConnection(con)

    local s2, w2
    nodemcu.net_tcp_listener_new(
        1111,
        "22.22.22.22",
        function(con2)
            s2 = con2
            w2 = tools.wrapConnection(s2)
            return s2
        end
    )

    con:connect(1111, "22.22.22.22")
    nodemcu.advanceTime(5)

    lu.assertEquals(w.sent, 0)
    lu.assertEquals(w.received, {})
    lu.assertEquals(w.connection, 1)
    lu.assertEquals(w.disconnection, 1)
    lu.assertEquals(w.reconnection, 0)

    lu.assertEquals(w2.sent, 0)
    lu.assertEquals(w2.received, {})
    lu.assertEquals(w2.connection, 1)
    lu.assertEquals(w2.disconnection, 1)
    lu.assertEquals(w2.reconnection, 0)
end

os.exit(lu.run())
