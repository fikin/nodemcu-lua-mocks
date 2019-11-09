--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
-]]
local socketFactory = require("socket")

--- TcpServer is structure representing net.TCP server
TcpServer = {
    TestData = {
        listeners = nil,
        timeoutMs = nil,
        port = nil,
        ip = nil,
        cb = function()
        end
        -- assigned when created new : listeners
        -- assigned on listen : cb
    }
}
TcpServer.__index = TcpServer

local function doCreateNewServer(timeoutMs, listenersTbl)
    assert(type(timeoutMs) == "number", "timeoutMs must be number")
    local o = {}
    setmetatable(o, TcpServer)
    o.TestData.listeners = listenersTbl
    o.TestData.timeoutMs = timeoutMs
    return o
end

local function getKey(srv)
    return srv.TestData.ip .. ":" .. srv.TestData.port
end

--- TcpServer.close is stock nodemcu API
TcpServer.close = function(self)
    assert(self)
    self.TestData.listeners[getKey(self)] = nil
end

--- TcpServer.listen is stock nodemcu API
TcpServer.listen = function(self, port, ip, cb)
    assert(self)
    if type(port) == "function" then
        cb = port
        port = nil
    elseif type(port) == "number" and type(ip) == "function" then
        cb = ip
        ip = nil
    elseif type(port) == "string" and type(ip) == "function" then
        ip = port
        cb = ip
    end
    port = port or math.random(1000, 50000)
    assert(type(port) == "number", "port must be number")
    ip = ip or "0.0.0.0"
    assert(type(ip) == "string", "ip must be string")
    assert(type(cb) == "function", "cb must be a function")
    self.TestData.port = port
    self.TestData.ip = ip
    self.TestData.cb = cb
    local key = getKey(self)
    assert(not self.TestData.listeners[key], "Port already assingned to another listener : " .. key)
    self.TestData.listeners[key] = self
end

--- TcpServer.getaddr is stock nodemcu API
TcpServer.getaddr = function(self)
    assert(self)
    return self.TestData.port, self.TestData.ip
end

--- TcpServer.TD_ConnectFrom is simulating accepting connection on listenr's port from a remote place
-- This method is used by test cases.
-- @param self is the listener object
-- @param remotePort is the port of simulated client
-- @param remoteIp is the ip of simulated client
-- @return socket connection object which one can use to send and receive data with the listener
TcpServer.TD_ConnectFrom = function(self, remotePort, remoteIp)
    assert(self)
    local con = socketFactory(self.TestData.port, self.TestData.ip, self.TestData.timeoutMs)
    self.TestData.cb(con)
    con:connect(remotePort, remoteIp)
    return con
end

return doCreateNewServer
