--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local nodemcu = require("nodemcu-module")
local Socket = require("net-connection")

net = {}
net.__index = net

net.TCP = 1
net.UDP = 2

-- ==========================
-- ==========================
-- ==========================

local NetTCPServer = {}
NetTCPServer.__index = NetTCPServer

--- NetTCPServer.getaddr is stock nodemcu API
NetTCPServer.getaddr = function(self)
  assert(type(self) == "table")
  return self._port, self._ip
end

--- NetTCPServer.close is stock nodemcu API
NetTCPServer.close = function(self)
  assert(type(self) == "table")
  assert(not self._isClosed, "listener already closed")
  self._isClosed = true
  nodemcu.net_tcp_listener_remove(self)
end

--- NetTCPServer.listen is stock nodemcu API
NetTCPServer.listen = function(self, port, ip, cb)
  assert(type(self) == "table")
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
  assert(type(cb) == "function", "cb must be a function(net.socket)")
  self._port = port
  self._ip = ip
  self._cb = cb
  self._isListening = true
  nodemcu.net_tcp_listener_add(self)
end

NetTCPServer.new = function(timeoutMs)
  local o = {
    _timeoutMs = timeoutMs,
    _isListening = false,
    _isClosed = false
  }
  setmetatable(o, NetTCPServer)
  return o
end

-- ==========================
-- ==========================
-- ==========================

--- net.createServer is stock nodemcu API
net.createServer = function(netType, timeoutSec)
  netType = netType or net.TCP
  assert(netType == net.TCP, "netType : only supported is net.TCP")
  timeoutSec = timeoutSec or 30
  assert(type(timeoutSec) == "number", "timeoutSec must be number")
  return NetTCPServer.new(timeoutSec * 1000)
end

--- net.createConnection is stock nodemcu API
net.createConnection = function(netType, secure)
  netType = netType or net.TCP
  assert(netType == net.TCP, "net.UDP is not supported yet")
  secure = secure or false
  assert(not secure, "secure is not supported yet")
  return Socket.new(nodemcu.net_tcp_idleiotimeout)
end

return net
