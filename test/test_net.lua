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

function testListen()
    nodemcu.reset()

    local conn = nil
    local listenerCalled = false
    local function listenerFn(con2)
        listenerCalled = true
        conn = con2
    end

    local srv = net.createServer()
    srv:listen(1111, listenerFn)

    -- simulate remote connected to the listener
    skt = nodemcu.net_tpc_connect_to_listener(1111, "22.22.22.22")

    -- 1byte frame size to test tokenization on receive
    skt.net_tcp_framesize = 1

    -- track the events in the connection
    ---@cast ww net_socket_wrapper
    local ww = {
        --server side handler of "receive" event
        receive = function(con3, data)
            -- echo the data back to remote
            if data then con3:send(data .. "1"); end
        end
    }
    local w = tools.wrapConnection(skt, ww)

    -- simulate remote sent some data
    skt:sentByRemote("123", true)
    -- unfold all tcp events in one go (connect+(3+1)xReceived+3xSent+1)
    nodemcu.advanceTime(9)
    -- simulate remote closed the connection
    skt:remoteCloses()
    nodemcu.advanceTime(2)

    lu.assertIsTrue(listenerCalled)
    lu.assertEquals(conn, skt)
    lu.assertEquals(w.sent, 3)
    lu.assertEquals(w.received, { "1", "2", "3" })
    lu.assertEquals(w.connection, 1)
    lu.assertEquals(w.disconnection, 1)
    lu.assertEquals(w.reconnection, 0)
    lu.assertEquals(skt:receivedByRemoteAll(), { "11", "21", "31" })
end

function testConnectClient()
    nodemcu.reset()

    local skt = net.createConnection()

    -- track the events in the connection
    local w = tools.wrapConnection(skt)
    ---simulates dns lookup
    skt.insteadOfDnsLookup = function(self, domain)
        assert(self ~= nil)
        lu.assertEquals(domain, "dummy.local")
        return "22.22.22.22"
    end

    skt:dns("dummy.local", function(skt2, ip)
        assert(skt2 ~= nil)
        lu.assertEquals(ip, "22.22.22.22")
        skt:connect(1111, ip)
    end)
    nodemcu.advanceTime(3)
    skt:remoteAcceptConnection() -- simulate remote accepting the connection
    skt:send("1.2")
    skt:sentByRemote("3.4")
    nodemcu.advanceTime(4)
    skt:close()
    nodemcu.advanceTime(2)

    lu.assertEquals(w.sent, 1)
    lu.assertEquals(w.received, { "3.4" })
    lu.assertEquals(w.connection, 1)
    lu.assertEquals(w.disconnection, 1)
    lu.assertEquals(w.reconnection, 0)
    lu.assertEquals(skt:receivedByRemoteAll(), { "1.2" })
end

function testTimeout()
    local skt = net.createConnection()

    -- 1ms idle timeout
    skt.idleTimeout = 1

    -- track the events in the connection
    local w = tools.wrapConnection(skt)

    skt:connect(1111, "1.2.3.4")
    nodemcu.advanceTime(2)

    lu.assertEquals(w.sent, 0)
    lu.assertEquals(w.received, {})
    lu.assertEquals(w.connection, 0)
    lu.assertEquals(w.disconnection, 1)
    lu.assertEquals(w.reconnection, 0)
end

os.exit(lu.run())
