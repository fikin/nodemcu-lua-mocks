--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
-- ==========================
-- ==========================
-- ==========================
local lu = require("luaunit")
local contains = require("contains")
local inspect = require("inspect")
local pipe = require("pipe")
local Timer = require("Timer")

Socket = {}
Socket.__index = Socket

local eventEnum = {"connection", "reconnection", "disconnection", "sent", "receive"}

local function doNothingFnc()
end
local function doNothingSelfFnc(self)
    lu.assertNotNil(self)
end

local function queueFnc(idleIoTimeoutMs, cb)
    assert(type(idleIoTimeoutMs) == "number", "idleIoTimeoutMs must be a number")
    assert(type(cb) == "function", "callback cb must be a function")
    Timer.createSingle(idleIoTimeoutMs, cb):start()
end

--- newConnection instantiates new socket object
-- @param localPort is the local port this connection is bound to
-- @param localIp is the local ip this connection is bound to
-- @param idleIoTimeoutMs before auto-disconnecting idle connections, default to 30000ms
local function newConnection(localPort, localIp, idleIoTimeoutMs)
    assert(type(localPort) == "number", "localPort must be a number")
    assert(type(localIp) == "string", "localIp must be a string")
    idleIoTimeoutMs = idleIoTimeoutMs or 30000
    assert(type(idleIoTimeoutMs) == "number", "idleIoTimeoutMs must be a number")
    local o = {
        TestData = {
            idleIoTimeoutMs = idleIoTimeoutMs,
            localIp = localIp,
            localPort = localPort,
            remotePort = nil, --remotePort or math.random(1000, 5000),
            remoteIp = nil, --remoteIp or "192.168.01." .. math.random(1, 127),
            wasClosed = false,
            wasOpened = false,
            eofPipeline = false,
            activityTs = nil,
            events = {
                connection = doNothingSelfFnc,
                reconnection = doNothingSelfFnc,
                disconnection = doNothingSelfFnc,
                receive = doNothingSelfFnc,
                sent = doNothingSelfFnc
            },
            receivedDataArr = {},
            collectedDataArr = {}
        }
    }
    setmetatable(o, Socket)
    return o
end

--- Socket.getaddr is stock nodemcu API
Socket.getaddr = function(self)
    assert(self ~= nil)
    return self.TestData.localPort, self.TestData.localIp
end

--- Socket.getpeer is stock nodemcu API
Socket.getpeer = function(self)
    assert(self ~= nil)
    return self.TestData.remotePort, self.TestData.remoteIp
end

--- Socket.close is stock nodemcu API
Socket.close = function(self)
    assert(self ~= nil)
    assert(self.TestData.wasOpened, "socket not opened")
    assert(not self.TestData.wasClosed, "socket already closed")
    queueFnc(
        1,
        function()
            self.TestData.wasClosed = true
            self.TestData.eofPipeline = true
            self.TestData.events["disconnection"](self)
        end
    )
end

--- Socket.on is stock nodemcu API
Socket.on = function(self, event, cb)
    assert(self ~= nil)
    assert(contains(eventEnum, event), "expected event one of " .. inspect(eventEnum) .. " but found " .. event)
    cb = cb or doNothingFnc
    assert(type(cb) == "function", "callback cb must be a function")
    self.TestData.events[event] = cb
end

--- Socket.connect is stock nodemcu API
-- When called a pipeline is established to :
--   - collect all data from Socket.send() method to given at construction time sentDataCollectorCb
--   - read and distpatch to callbacks any data provided to Socket.TestDataReceive() method
Socket.connect = function(self, remotePort, remoteIp)
    assert(self ~= nil)
    assert(type(remotePort) == "number", "remotePort must be a number")
    assert(type(remoteIp) == "string", "remoteIp must be a string")
    assert(not self.TestData.wasClosed, "Socket already closed.")
    assert(not self.TestData.wasOpened, "Socket already connected.")
    self.TestData.remoteIp = remoteIp
    self.TestData.remotePort = remotePort
    self.TestData.activityTs = Timer.getCurrentTimeMs()
    queueFnc(
        1,
        function()
            self.TestData.wasOpened = true
            self.TestData.eofPipeline = false
            self.TestData.events["connection"](self)
            self:td_StartInactiveClientTimeout()
            pipe.createTimerPipeline(
                function()
                    return self.TestData.eofPipeline, self:td_PopReceivedData()
                end,
                function(data)
                    if data then
                        self.TestData.activityTs = Timer.getCurrentTimeMs()
                        self.TestData.events["receive"](self, data)
                    end
                end,
                true,
                1
            )
        end
    )
end

--- Socket.send is stock nodemcu API
Socket.send = function(self, data, callback)
    assert(self ~= nil)
    assert(type(data) == "string", "data must be a string")
    callback = callback or self.TestData.events["sent"]
    assert(type(callback) == "function", "callback must be a function")
    assert(self.TestData.wasOpened, "Socket not connected.")
    assert(not self.TestData.wasClosed, "Socket already closed.")
    self.TestData.activityTs = Timer.getCurrentTimeMs()
    queueFnc(
        1,
        function()
            self:td_PushSentData(data)
            callback(self)
        end
    )
end

--- Socket.td_StartInactiveClientTimeout starts a watchdog timer to disconned after inactivity
-- this method backs up stock nodemuc API net.createServer()
Socket.td_StartInactiveClientTimeout = function(self)
    assert(self ~= nil)
    Timer.createReoccuring(
        self.TestData.idleIoTimeoutMs + 2,
        function(timerObj)
            if self.TestData.wasClosed then
                timerObj:stop()
            end
            if
                self.TestData.wasOpened and
                    Timer.hasDelayElapsedSince(
                        Timer.getCurrentTimeMs(),
                        self.TestData.activityTs,
                        self.TestData.idleIoTimeoutMs
                    )
             then
                self:close()
            end
        end
    ):start()
end

Socket.td_PopReceivedData = function(self)
    assert(self ~= nil)
    assert(self.TestData.wasOpened, "Socket not connected.")
    local a = self.TestData.eofPipeline and nil or table.remove(self.TestData.receivedDataArr, 1)
    return a
end

--- Socket.td_PushSentData is called by Socket:send() to collect sent data
-- called internally, do not use outside
-- @param data is data to push to collected data (FIFO)
Socket.td_PushSentData = function(self, data)
    assert(self ~= nil)
    assert(type(data) == "string", "data must be a string")
    assert(self.TestData.wasOpened, "Socket not connected.")
    table.insert(self.TestData.collectedDataArr, data)
end

--- Socket.TD_PopSentData is returning all collected to this moment Socket:send() data
-- use it in test cases to pop all collected up to this moment data for verification purposes
-- @return array with each Socket:send(data) in order to appearance
Socket.TD_PopSentData = function(self)
    assert(self ~= nil)
    local arr = self.TestData.collectedDataArr
    self.TestData.collectedDataArr = {}
    return arr
end

--- Socket.TD_Send_EOF is sending EOF to the connection
-- the connection object threats this data as EOF
Socket.TD_Send_EOF = function(self)
    assert(self ~= nil)
    self.TestData.eofPipeline = true
    self.TestData.events["disconnection"](self)
end

--- Socket.TD_Send is sending given data to the connection
-- the connection object threats this data as incoming from the remote host
-- after sendind data via this methof, one should expect Socket:on triggers to trigger.
-- @param data to be received by this connection object. Data is chunked in given size chunks before being received.
-- @param chunkSize is the max size of single Socket:on("receive") message. By default 64 bytes.
Socket.TD_Send = function(self, data, chunkSize)
    assert(self ~= nil)
    assert(type(data) == "string", "data must be a string")
    chunkSize = chunkSize or 64
    assert(type(chunkSize) == "number", "chunkSize must be a number")
    assert(self.TestData.wasOpened, "Socket not connected.")
    while true do
        local head, tail =
            string.len(data) <= chunkSize and data or string.sub(data, 1, chunkSize),
            string.len(data) > chunkSize and string.sub(data, chunkSize + 1) or nil
        if not head then
            break
        end
        table.insert(self.TestData.receivedDataArr, head)
        if not tail then
            break
        end
        data = tail
    end
end

return newConnection
