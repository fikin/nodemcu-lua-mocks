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

---@alias socket_fn fun(skt:socket, data?: string)

---do nothing function, used as dummy socket event handler
---@type socket_fn
local function doNothingSelfFnc(self, data)
end

---represents port+ip pair
---@class addrObj
local addrObj = {
    port = math.random(61000, 61999),
    ip = "localhost"
}
addrObj.__index = addrObj

addrObj.new = function(ip)
    return setmetatable({ ip = ip or "localhost" }, addrObj)
end

---represent net.tcp.socket object
---@class socket
local socket = {
    ---@private
    _localAddr = addrObj.new(),
    ---@private
    _remoteAddr = addrObj.new(),
    ---@private
    _sent = fifoArr.new(),
    ---@private
    _received = fifoArr.new(),
    ---@private
    _tcpEvents = fifoArr.new(),
    ---@private
    _holdOn = false,
    ---@private
    _ttl = 10,
    ---true if the connection is closed
    ---@private
    _isClosed = false,
    ---tcp frame size, overwrite in test cases if needed
    net_tcp_framesize = 1024,
    ---table with event callbacks, used internally, do not touch directly
    ---@private
    _on = {
        connection = doNothingSelfFnc,
        reconnection = doNothingSelfFnc,
        disconnection = doNothingSelfFnc,
        receive = doNothingSelfFnc,
        sent = doNothingSelfFnc,
        dns = doNothingSelfFnc
    },
    ---substitutes calling actual dns lookup in test cases.
    ---by default returns 11.22.33.44 for all requests.
    ---overwrite it in the unit test if different behaviour is needed.
    ---@param self socket
    ---@param domain string
    ---@return string|nil ip address which will be passed to "dns" callback. if nil, dns cb is not called.
    insteadOfDnsLookup = function(self, domain) return "11.22.33.44"; end,
    ---timer object, running events/data exchange b/n remote and local
    ---@private
    _tmr = Timer.createReoccuring(1, doNothingSelfFnc),
    ---timestamp tracking last io activity, used internally in conjection with _idleTimeout
    ---@private
    _lastActivityTs = Timer.getCurrentTimeMs(),
    ---idle io time before connection will be auto-closed.
    ---by default 10ms
    ---overwrite in the unit test if different value is needed.
    idleTimeout = 10,
}
socket.__index = socket

---@param self socket
local function dispathStackWithTcpEvents(self)
    while self._tcpEvents:hasMore() do
        local data = assert(self._tcpEvents:pop())
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

---@param self socket
local function handleIoInactivity(self)
    local now = Timer.getCurrentTimeMs()
    if Timer.hasDelayElapsedSince(now, self._lastActivityTs, self.idleTimeout) then
        self.remoteCloses(self, "io inactivity timeout")
    else
        self._lastActivityTs = now
    end
end

---used internally to exchange data b/n remote and local
---@param self socket
local function controlLoop(self)
    dispathStackWithTcpEvents(self)
    handleIoInactivity(self)
end

---used to instantiate new socket, called by net.listener or net.createConnection
---@param idleTimeoutMs integer idle connection timeout in ms
---@return socket
socket.new = function(idleTimeoutMs)
    local o = {
        _localAddr = addrObj.new(),
        _remoteAddr = addrObj.new(),
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
        insteadOfDnsLookup = function(self, domain) return "11.22.33.44"; end,
        _lastActivityTs = Timer.getCurrentTimeMs(),
        idleTimeout = idleTimeoutMs,
    }
    setmetatable(o, socket)
    o._tmr = Timer.createReoccuring(1, function() controlLoop(o); end)
    return o
end

---used internally to signify that connection
---has been established b/n remote and local.
---called by socket.connect or net.listener.
---@param self socket
local function startControlLoop(self)
    self._tmr:start()
end

---used internally to exchange some commands b/n remote and local
---@param self socket
---@param eventType string text name of any of the socket events
---@param payload? string
---@private
socket.sendTcpEvent = function(self, eventType, payload)
    assert(eventType)
    self._tcpEvents:push({ eventType = eventType, payload = payload })
end

---called by unit tests to simulate sending data to local
---@param self socket
---@param data string|nil if nil, no data is being sent
---@param isEOF? boolean if true, EOF is sent to local, by default true
socket.sentByRemote = function(self, data, isEOF)
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
---@param self socket
---@return string[]
socket.receivedByRemote = function(self)
    local arr = {}
    while self._sent:hasMore() do
        table.insert(arr, self._sent:pop())
    end
    return arr
end

---called by unit tests to read all sent by local data
---this method returns all received data, regadless is
---it has been read or not.
---@param self socket
---@return table
socket.receivedByRemoteAll = function(self)
    return self._sent:getAll()
end

---called by unit tests to read all sent by local data
---this method returns all received data, regadless is
---it has been read or not.
---"nil" item would indicate EOF.
---@param self socket
---@return any[]
socket.receivedByLocalAll = function(self)
    return self._received:getAll()
end

---called by unit tests to trigger connection closing
---initiated by remote. local receives an event.
---@param self socket
---@param reason? string
socket.remoteCloses = function(self, reason)
    self.sendTcpEvent(self, "disconnection", reason or "remote is closed")
end

---called by unit tests to trigger connection reconnection
---initiated by remote. local receives an event.
---@param self socket
socket.remoteReconnects = function(self)
    self.sendTcpEvent(self, "reconnection")
end

---called by unit tests to trigger "connection" event
---when client is connecting to some remote host.
---use can call also remoteCloses() instead to trigger disconnection event.
---if called right after skt:connect(), it indicates the connection did not happen.
---if remoteAcceptConnection() is called instead, it indicates connection happened
---and transfer of data can commense.
---@param self socket
socket.remoteAcceptConnection = function(self)
    self.sendTcpEvent(self, "connection", "remote accepted the connection")
end

---stock API
---@param self socket
socket.close = function(self)
    if not self._isClosed then
        self._isClosed = true
        self.sendTcpEvent(self, "disconnection", nil)
        controlLoop(self) -- ensure stack with events is over before closing
    end
end

---stock API
---@param self socket
---@param port integer
---@param ip string
socket.connect = function(self, port, ip)
    self._remoteAddr = addrObj.new(ip)
    startControlLoop(self)
end

---stock API.
---these requests are resolved by socket._onDnsRequest function.
---unit test auther can assign new function logic here.
---@param self socket
---@param domain any
---@param cb any
socket.dns = function(self, domain, cb)
    self._on.dns = cb
    self:sendTcpEvent("dns-request", domain)
    startControlLoop(self)
end

---stock API
---@param self socket
---@return integer port
---@return  string ip
socket.getpeer = function(self)
    local a = self._remoteAddr
    return a.port, a.ip
end

---stock API
---@param self socket
---@return integer
---@return string
socket.getaddr = function(self)
    local a = self._localAddr
    return a.port, a.ip
end

---stock API
---@param self socket
socket.hold = function(self)
    self._holdOn = true
end

---stock API
---@param self socket
---@param on string
---@param cb socket_fn|nil
socket.on = function(self, on, cb)
    self._on[on] = cb or doNothingSelfFnc
end

---stock API
---@param self socket
---@param data any
---@param cb? socket_fn
socket.send = function(self, data, cb)
    if cb then
        self._on.sent = cb
    end
    self:sendTcpEvent("sent", data)
end

---stock API
---@param self socket
---@param ttl any
---@return integer
socket.ttl = function(self, ttl)
    if ttl then
        self._ttl = ttl
    end
    return self._ttl
end

---stock API
---@param self socket
socket.unhold = function(self)
    self._holdOn = false
end

return socket
