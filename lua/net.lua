--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local newTcpServer = require("net_tcp_server")
local nodemcu = require("nodemcu-module")

net = {}
net.__index = net

net.TCP = 1
net.UDP = 2

-- ==========================
-- ==========================
-- ==========================

--- net.createServer is stock nodemcu API
net.createServer = function(netType, timeoutSec)
  netType = netType or net.TCP
  assert(netType == net.TCP, "netType : only supported is net.TCP")
  timeoutSec = timeoutSec or 30
  assert(type(timeoutSec) == "number", "timeoutSec must be number")
  return newTcpServer(timeoutSec * 1000, nodemcu.netTCPListeners) -- ms format
end

return net
