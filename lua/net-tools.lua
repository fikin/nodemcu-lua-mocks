--[[
License : GPLv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
-- ==========================
-- ==========================
-- ==========================

---represents port+ip pair
---@class addrObj
local addrObj = {
    port = math.random(61000, 61999),
    ip = "localhost"
}
addrObj.__index = addrObj

local M = {}

M.newAddrObj = function(ip)
    return setmetatable({ ip = ip or "localhost" }, addrObj)
end

---base class for tcp and udp sockets
---@class socket

---socket callback function
---@alias socket_fn fun(skt:socket, data?: string)

return M
