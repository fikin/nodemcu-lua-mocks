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
  ---server's timeput
  ---@type integer
  _timeout = 10,
  ---listener's ip if provided
  ---@type string|nil
  _ip = nil,
  ---server's listener function
  ---@type socket_fn
  _listener = nil,
}
tcpServer.__index = tcpServer

---new instance of tcp server
---@param timeout? integer
---@return tcpServer
tcpServer.new = function(timeout)
  return setmetatable({ _timeout = timeout or 30 }, tcpServer)
end

---stock net.tcp server API
---@param self tcpServer
---@param port integer
---@param cb socket_fn
tcpServer.listen = function(self, port, cb)
  assert(port)
  assert(cb, string.format("missing listener function for port %d", port))
  self._listener = cb
  nodemcu.net_tcp_srv[port] = self
end



--- net.createServer is stock nodemcu API
---@param timeoutSec? integer
---@return tcpServer
net.createServer = function(timeoutSec)
  timeoutSec = timeoutSec or 30
  return tcpServer.new(timeoutSec)
end

---net.createConnection is stock nodemcu API
---@return socket
net.createConnection = function()
  return socket.new(30000)
end

return net
