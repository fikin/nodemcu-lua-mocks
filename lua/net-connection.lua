--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
-- ==========================
-- ==========================
-- ==========================
local contains = require("contains")
local inspect = require("inspect")
local Timer = require("Timer")
local nodemcu = require("nodemcu-module")

Socket = {}
Socket.__index = Socket

local eventEnum = {"connection", "reconnection", "disconnection", "sent", "receive"}

local function tokenize(chunkSize, data)
    assert(type(chunkSize) == "number")
    assert(type(data) == "string")
    local arr = {}
    while true do
        local head, tail =
            string.len(data) <= chunkSize and data or string.sub(data, 1, chunkSize),
            string.len(data) > chunkSize and string.sub(data, chunkSize + 1) or nil
        if not head then
            break
        end
        table.insert(arr, head)
        if not tail then
            break
        end
        data = tail
    end
    return arr
end

local function queueFnc(idleIoTimeoutMs, cb)
    assert(type(idleIoTimeoutMs) == "number", "idleIoTimeoutMs must be a number")
    assert(type(cb) == "function", "callback cb must be a function")
    Timer.createSingle(idleIoTimeoutMs, cb):start()
end

local function spawn(cb)
    assert(type(cb) == "function")
    Timer.createSingle(1, cb):start()
end

local function newInactivityWatchdog(timeout, socket)
    return {
        _idleTimeout = timeout,
        _socket = socket,
        _lastActivityTs = 0,
        _tmr = nil,
        _onTimer = function(self)
            assert(type(self) == "table")
            assert(not self._wasClosed, "someone did not close the io-inact watchdog when socket was closed")
            if Timer.hasDelayElapsedSince(Timer.getCurrentTimeMs(), self._lastActivityTs, self._idleTimeout) then
                print("[WARN] : socket io inactivity timeout detected, closing the socket")
                self._socket:close()
            end
        end,
        _assertTmr = function(self)
            assert(type(self) == "table")
            if not self._tmr then
                self._tmr =
                    Timer.createReoccuring(
                    self._idleTimeout + 1,
                    function()
                        self._onTimer(self)
                    end
                )
            end
        end,
        reset = function(self)
            assert(type(self) == "table")
            self._lastActivityTs = Timer.getCurrentTimeMs()
        end,
        start = function(self)
            assert(type(self) == "table")
            self:_assertTmr()
            self:reset()
            self._tmr:start()
        end,
        stop = function(self)
            assert(type(self) == "table")
            assert(self._tmr)
            self._tmr:stop()
        end
    }
end

local function newFifoArray()
    return {
        _arr = {},
        add = function(self, value)
            assert(type(self) == "table")
            assert(type(value) == "function")
            assert(self._arr)
            table.insert(self._arr, value)
        end,
        remove = function(self)
            assert(type(self) == "table")
            assert(self._arr)
            assert(#self._arr > 0)
            return table.remove(self._arr, 1)
        end,
        hasData = function(self)
            assert(type(self) == "table")
            assert(self._arr)
            return #self._arr > 0
        end
    }
end

local function newIoPipe(consumerCb)
    local o = {
        _queue = newFifoArray(),
        _onTimer = function(self)
            assert(type(self) == "table")
            if self._queue:hasData() then
                consumerCb(self._queue:remove()())
            end
        end,
        send = function(self, v)
            assert(type(self) == "table")
            self._queue:add(v)
        end,
        start = function(self)
            assert(type(self) == "table")
            self._tmr:start()
        end,
        stop = function(self)
            assert(type(self) == "table")
            self._tmr:stop()
        end
    }
    o._tmr =
        Timer.createReoccuring(
        1,
        function()
            o:_onTimer()
        end
    )
    return o
end

--- newConnection instantiates new socket object
-- @param idleIoTimeoutMs before auto-disconnecting idle connections
Socket.new = function(idleIoTimeoutMs)
    assert(idleIoTimeoutMs)
    local function doNothingSelfFnc(self)
        assert(type(self) == "table")
    end
    local o = {
        _addr = {
            port = nil,
            host = nil
        },
        _peer = {
            _addr = {
                port = nil,
                host = nil
            }
        },
        _wasConnected = false,
        _wasClosed = false,
        _events = {
            connection = doNothingSelfFnc,
            reconnection = doNothingSelfFnc,
            disconnection = doNothingSelfFnc,
            receive = doNothingSelfFnc,
            sent = doNothingSelfFnc
        },
        _outPipe = nil
    }
    o._timeoutTimer = newInactivityWatchdog(idleIoTimeoutMs, o)
    setmetatable(o, Socket)
    return o
end

--- Socket.getaddr is stock nodemcu API
Socket.getaddr = function(self)
    assert(type(self) == "table")
    assert(self._addr)
    return self._addr.port, self._addr.host
end

--- Socket.getpeer is stock nodemcu API
Socket.getpeer = function(self)
    assert(type(self) == "table")
    assert(self._peer)
    assert(self._peer._addr)
    return self._peer._addr.port, self._peer._addr.host
end

--- Socket.on is stock nodemcu API
Socket.on = function(self, event, cb)
    assert(type(self) == "table")
    assert(type(event) == "string")
    assert(contains(eventEnum, event), "expected event one of " .. inspect(eventEnum) .. " but found " .. event)
    cb = cb or function()
        end
    assert(type(cb) == "function")
    self._events[event] = cb
end

--- Socket.send is stock nodemcu API
Socket.send = function(self, data, callback)
    assert(type(self) == "table")
    assert(type(data) == "string")
    for _, token in ipairs(tokenize(nodemcu.net_tcp_framesize, data)) do
        self:_doSend(token, callback)
    end
end

--- Socket.connect is stock nodemcu API
-- When called a pipeline is established to :
--   - collect all data from Socket.send() method to given at construction time sentDataCollectorCb
--   - read and distpatch to callbacks any data provided to Socket.TestDataReceive() method
Socket.connect = function(self, remotePort, remoteIp)
    assert(type(self) == "table")
    assert(not self._wasClosed)
    assert(not self._wasOpened)
    local function newRemoteSocket(remoteSrv)
        assert(remoteSrv)
        assert(type(remoteSrv._port) == "number")
        assert(type(remoteSrv._ip) == "string")
        assert(type(remoteSrv._timeoutMs) == "number")
        assert(type(remoteSrv._cb) == "function")
        local peer = Socket.new(math.random(62000, 62999), remoteSrv._ip, remoteSrv._timeoutMs)
        spawn(
            function()
                remoteSrv._cb(peer) -- server.listen callback call
            end
        )
        return peer
    end
    self._addr.port = math.random(61000, 61999)
    self._addr.host = nodemcu.net_ip_get()
    local remoteSrv = nodemcu.net_tcp_listener_get(remotePort, remoteIp)
    if remoteSrv then
        local peer = newRemoteSocket(remoteSrv)
        self:_doConnect(peer)
        peer:_onRemoteConnect(self)
    end
end

--- Socket.close is stock nodemcu API
Socket.close = function(self)
    assert(type(self) == "table")
    spawn(
        function()
            self._peer:_onRemoteClose()
        end
    )
    self:_doClose()
end

Socket._doSend = function(self, data, callback)
    assert(type(self) == "table")
    assert(type(data) == "string")
    callback = callback or self._events["sent"]
    assert(type(callback) == "function")
    assert(self._wasConnected)
    assert(not self._wasClosed)
    self._timeoutTimer:reset()
    self._outPipe:send(
        function()
            spawn(
                function()
                    callback(self)
                end
            )
            return data
        end
    )
end

Socket._onRemoteClose = function(self)
    assert(type(self) == "table")
    self:_doClose()
end

Socket._doClose = function(self)
    assert(type(self) == "table")
    assert(self._wasConnected)
    assert(not self._wasClosed)
    spawn(
        function()
            self._wasClosed = true
            self._timeoutTimer:stop()
            self._outPipe._tmr:stop()
            self._events["disconnection"](self)
        end
    )
end

Socket._receiveDataCb = function(self)
    assert(type(self) == "table")
    return function(data)
        if data then
            self._timeoutTimer:reset()
            self._events["receive"](self, data)
        end
    end
end

Socket._onRemoteConnect = function(self, peer)
    assert(type(self) == "table")
    assert(peer)
    self:_doConnect(peer)
end

Socket._doConnect = function(self, peer)
    assert(type(self) == "table")
    assert(peer)
    assert(not self._wasConnected)
    assert(not self._wasClosed)
    assert(self._timeoutTimer)
    self._peer = peer
    self._outPipe = newIoPipe(peer:_receiveDataCb())
    spawn(
        function()
            self._wasConnected = true
            self._timeoutTimer:start()
            self._outPipe:start()
            self._events["connection"](self)
        end
    )
end

return Socket
