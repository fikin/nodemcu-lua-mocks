--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
-- ==========================
-- ==========================
-- ==========================
local lu = require("luaunit")
local nodemcu = require("nodemcu")

local uniformCallbacks = function(cb)
    local function emptyFnc()
    end
    cb = cb or {}
    cb.sent = cb.sent or emptyFnc
    cb.receive = cb.receive or emptyFnc
    cb.disconnection = cb.disconnection or emptyFnc
    cb.connection = cb.connection or emptyFnc
    cb.reconnection = cb.reconnection or emptyFnc
    return cb
end

local function wrapCon(con, cb)
    cb = uniformCallbacks(cb)
    local w = {
        sent = 0,
        received = {},
        connection = 0,
        disconnection = 0,
        reconnection = 0
    }
    con:on(
        "sent",
        function(con2)
            w.sent = w.sent + 1
            cb.sent(con2)
        end
    )
    con:on(
        "receive",
        function(con2, data)
            table.insert(w.received, data)
            cb.receive(con2, data)
        end
    )
    con:on(
        "disconnection",
        function(con2)
            w.disconnection = w.disconnection + 1
            cb.disconnection(con2, data)
        end
    )
    con:on(
        "connection",
        function(con2)
            w.connection = w.connection + 1
            cb.connection(con2, data)
        end
    )
    con:on(
        "reconnection",
        function(con2)
            w.reconnection = w.reconnection + 1
            cb.reconnection(con2, data)
        end
    )
    return w
end

function testConnectTo()
    nodemcu.reset()

    local con = net.createConnection(net.TCP, false)
    local w = wrapCon(con)

    local s2, w2
    nodemcu.net_tcp_listener_new(
        1111,
        "22.22.22.22",
        function(con2)
            assert(con2)
            s2 = con2
            w2 =
                wrapCon(
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
            w2 = wrapCon(s2)
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
    local w = wrapCon(con)

    local s2, w2
    nodemcu.net_tcp_listener_new(
        1111,
        "22.22.22.22",
        function(con2)
            s2 = con2
            w2 = wrapCon(s2)
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
