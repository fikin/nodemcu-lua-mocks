--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
-- ==========================
-- ==========================
-- ==========================
local tokenize = require("tokenize")
local Timer = require("Timer")
local fifoArr = require("fifo-arr")
local netTools = require("net-tools")

---@alias udpsocket_fn fun(skt:udpsocket, data?: string)

---do nothing function, used as dummy udpsocket event handler
---@type udpsocket_fn
local function doNothingSelfFnc(_, _)
end

---table with event callbacks, used internally
---@class udpSocketCallbacksTbl
---@field connection    udpsocket_fn
---@field reconnection  udpsocket_fn
---@field disconnection udpsocket_fn
---@field receive       udpsocket_fn
---@field sent          udpsocket_fn
---@field dns           udpsocket_fn

---function used in tests to mimic dns lookup for a given socker
---@alias testDnsLookupFn fun(self:udpsocket,domain:string):string|nil

---represent net.tcp.udpsocket object
--@class udpsocket
--@field _localAddr addrObj private field
--@field _remoteAddr addrObj private field
--@field _sent fifoArr private field
--@field _received fifoArr private field
--@field _udpEvents fifoArr private field
--@field _holdOn boolean private field
--@field _ttl integer private field
--@field _isClosed boolean private field, true if socker is closed
--@field net_tcp_framesize integer tcp frame size, overwrite in test cases if needed
--@field _on udpSocketCallbacksTbl table with event callbacks, used internally, do not touch directly = {
--substitutes calling actual dns lookup in test cases.
--by default returns 11.22.33.44 for all requests.
--overwrite it in the unit test if different behaviour is needed.
--@field insteadOfDnsLookup testDnsLookupFn
--@field _tmr TimerObj timer object, running events/data exchange b/n remote and local
--timestamp tracking last io activity, used internally in conjection with _idleTimeout
--@private
--@field _lastActivityTs integer timestamp tracking last io activity, used internally in conjection with _idleTimeout
--@field idleTimeout integer idle io time before connection will be auto-closed. by default 10ms.
--                            overwrite in the unit test if different value is needed.

--@type udpsocket
---@class udpsocket
local udpsocket = {}
udpsocket._localAddr = netTools.newAddrObj()
udpsocket._remoteAddr = netTools.newAddrObj()
udpsocket._sent = fifoArr.new()
udpsocket._received = fifoArr.new()
udpsocket._tcpEvents = fifoArr.new()
udpsocket._udpEvents = fifoArr.new()
udpsocket._holdOn = false
udpsocket._ttl = 10
udpsocket._isClosed = false
udpsocket.net_tcp_framesize = 1024
udpsocket._on = {
    connection = doNothingSelfFnc,
    reconnection = doNothingSelfFnc,
    disconnection = doNothingSelfFnc,
    receive = doNothingSelfFnc,
    sent = doNothingSelfFnc,
    dns = doNothingSelfFnc
}
udpsocket.insteadOfDnsLookup = function(_, _) return "11.22.33.44"; end
udpsocket._tmr = Timer.createReoccuring(1, doNothingSelfFnc)
udpsocket._lastActivityTs = Timer.getCurrentTimeMs()
udpsocket.idleTimeout = 10
udpsocket.__index = udpsocket

---@param self udpsocket
local function dispathStackWithTcpEvents(self)
    while self._udpEvents:hasMore() do
        local data = assert(self._udpEvents:pop())
        if data.eventType == "dns-request" then
            local ip = self.insteadOfDnsLookup(self, data.payload)
            if ip then self._on.dns(self, ip); end
        else
            if data.eventType == "sent" then
                self._sent:push(data.payload);
            elseif data.eventType == "receive" then
                self._received:push(data.payload);
            end
            local fn = self._on[data.eventType]
            if fn == nil then
                error(string.format("unsupported tcp event type \"%s\" with payload \"%s\"", data.eventType, data
                    .payload))
            end
            fn(self, data.payload)
        end
    end
end

---@param self udpsocket
local function handleIoInactivity(self)
    local now = Timer.getCurrentTimeMs()
    if Timer.hasDelayElapsedSince(now, self._lastActivityTs, self.idleTimeout) then
        self.remoteCloses(self, "io inactivity timeout")
    else
        self._lastActivityTs = now
    end
end

---used internally to exchange data b/n remote and local
---@param self udpsocket
local function controlLoop(self)
    dispathStackWithTcpEvents(self)
    handleIoInactivity(self)
end

---used to instantiate new udpsocket, called by net.listener or net.createConnection
---@param idleTimeoutMs integer idle connection timeout in ms
---@return udpsocket
udpsocket.new = function(idleTimeoutMs)
    local o = {
        _localAddr = netTools.newAddrObj(),
        _remoteAddr = netTools.newAddrObj(),
        _sent = fifoArr.new(),
        _received = fifoArr.new(),
        _tcpEvents = fifoArr.new(),
        _holdOn = false,
        _ttl = 10,
        _isClosed = false,
        net_tcp_framesize = 1024,
        _on = {
            connection = doNothingSelfFnc,
            reconnection = doNothingSelfFnc,
            disconnection = doNothingSelfFnc,
            receive = doNothingSelfFnc,
            sent = doNothingSelfFnc,
            dns = doNothingSelfFnc
        },
        -- default dns lookup logic
        insteadOfDnsLookup = function(_, _) return "11.22.33.44"; end,
        _lastActivityTs = Timer.getCurrentTimeMs(),
        idleTimeout = idleTimeoutMs,
    }
    setmetatable(o, udpsocket)
    o._tmr = Timer.createReoccuring(1, function() controlLoop(o); end)
    return o
end

---used internally to signify that connection
---has been established b/n remote and local.
---called by udpsocket.connect or net.listener.
---@param self udpsocket
local function startControlLoop(self)
    self._tmr:start()
end

---used internally to exchange some commands b/n remote and local
---@param self udpsocket
---@param eventType string text name of any of the udpsocket events
---@param payload? string
---@private
udpsocket.sendTcpEvent = function(self, eventType, payload)
    assert(eventType)
    self._tcpEvents:push({ eventType = eventType, payload = payload })
end

---called by unit tests to simulate sending data to local
---@param self udpsocket
---@param data string|nil if nil, no data is being sent
---@param isEOF? boolean if true, EOF is sent to local, by default true
udpsocket.sentByRemote = function(self, data, isEOF)
    if data then
        for _, str in ipairs(tokenize(self.net_tcp_framesize, data)) do
            self:sendTcpEvent("receive", str)
        end
    end
    isEOF = (isEOF == nil) and true or isEOF
    if isEOF then
        self:sendTcpEvent("receive", nil)
    end
end

---called by unit tests to read sent by local data.
---this call returns data not read since last call.
---@param self udpsocket
---@return string[]
udpsocket.receivedByRemote = function(self)
    local arr = {}
    while self._sent:hasMore() do
        table.insert(arr, self._sent:pop())
    end
    return arr
end

---called by unit tests to read all sent by local data
---this method returns all received data, regadless is
---it has been read or not.
---@param self udpsocket
---@return table
udpsocket.receivedByRemoteAll = function(self)
    return self._sent:getAll()
end

---called by unit tests to read all sent by local data
---this method returns all received data, regadless is
---it has been read or not.
---"nil" item would indicate EOF.
---@param self udpsocket
---@return any[]
udpsocket.receivedByLocalAll = function(self)
    return self._received:getAll()
end

---called by unit tests to trigger connection closing
---initiated by remote. local receives an event.
---@param self udpsocket
---@param reason? string
udpsocket.remoteCloses = function(self, reason)
    self.sendTcpEvent(self, "disconnection", reason or "remote is closed")
end

---called by unit tests to trigger connection reconnection
---initiated by remote. local receives an event.
---@param self udpsocket
udpsocket.remoteReconnects = function(self)
    self.sendTcpEvent(self, "reconnection")
end

---called by unit tests to trigger "connection" event
---when client is connecting to some remote host.
---use can call also remoteCloses() instead to trigger disconnection event.
---if called right after skt:connect(), it indicates the connection did not happen.
---if remoteAcceptConnection() is called instead, it indicates connection happened
---and transfer of data can commense.
---@param self udpsocket
udpsocket.remoteAcceptConnection = function(self)
    self.sendTcpEvent(self, "connection", "remote accepted the connection")
end

---stock API
---@param self udpsocket
udpsocket.close = function(self)
    if not self._isClosed then
        self._isClosed = true
        self.sendTcpEvent(self, "disconnection", nil)
        controlLoop(self) -- ensure stack with events is over before closing
    end
end

---stock API.
---these requests are resolved by udpsocket._onDnsRequest function.
---unit test auther can assign new function logic here.
---@param self udpsocket
---@param domain any
---@param cb any
udpsocket.dns = function(self, domain, cb)
    self._on.dns = cb
    self:sendTcpEvent("dns-request", domain)
    startControlLoop(self)
end

---stock API
---@param self udpsocket
---@return integer port
---@return  string ip
udpsocket.getpeer = function(self)
    local a = self._remoteAddr
    return a.port, a.ip
end

---stock API
---@param self udpsocket
---@return integer
---@return string
udpsocket.getaddr = function(self)
    local a = self._localAddr
    return a.port, a.ip
end

---stock API
---@param self udpsocket
---@param on string
---@param cb socket_fn|nil
udpsocket.on = function(self, on, cb)
    self._on[on] = cb or doNothingSelfFnc
end

---stock API
---@param self udpsocket
---@param port integer
---@param ip string
---@param data string
udpsocket.send = function(self, port, ip, data)
    assert(type(port) == "number")
    assert(type(ip) == "string")
    if cb then
        self._on.sent = cb
    end
    self:sendTcpEvent("sent", data)
end

---stock API
---@param self udpsocket
---@param ttl any
---@return integer
udpsocket.ttl = function(self, ttl)
    if ttl then
        self._ttl = ttl
    end
    return self._ttl
end

return udpsocket
