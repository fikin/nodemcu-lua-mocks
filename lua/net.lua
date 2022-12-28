--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local nodemcu = require("nodemcu-module")
local socket = require("net-tcp-socket")

---stock API, implements net package
---@class net
net = {}
net.__index = net

net.TCP = 1
net.UDP = 2

---stock API, implements net.tcp server
---@class tcpServer
local tcpServer = {
  ---@private
  _timeout = 10,
  ---@private
  ---@type table<string,socket_fn>
  _listeners = {},
}
tcpServer.__index = tcpServer

---new instance of tcp server
---@param timeout any
---@return tcpServer
tcpServer.new = function(timeout)
  return setmetatable({
    _timeout = timeout,
    _listeners = {},
  }, tcpServer)
end

---stock net.tcp server API
---@param self tcpServer
---@param port? integer
---@param ip? string
---@param cb socket_fn
tcpServer.listen = function(self, port, ip, cb)
  local ccc = (type(cb) == "function" and cb) or
      (type(ip) == "function" and ip) or
      (type(port) == "function" and port)
  assert(ccc, string.format("missing listener function for port %d", port))
  ip = (type(ip) == "string" and ip) or
      (type(port) == "string" and tostring(port))
      or "localhost"
  port = (type(port) == "number" and port) or math.random(10000, 20000)
  ---@cast ccc socket_fn
  self._listeners[tostring(port)] = ccc
end



--- net.createServer is stock nodemcu API
---@param timeoutSec? integer
---@return tcpServer
net.createServer = function(timeoutSec)
  timeoutSec = timeoutSec or 30
  local o = tcpServer.new(timeoutSec)
  nodemcu.net_tcp_srv = o
  return o
end

---net.createConnection is stock nodemcu API
---@return socket
net.createConnection = function()
  return socket.new(30000)
end

return net
