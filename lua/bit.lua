--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local bit32 = require("bit32")

---bit module
---@class bit
bit = {}
bit.__index = bit

---stock api
---@param a number
---@return number
bit.bnot = function(a)
    return bit32.bnot(a)
end

---stock api
---@param a number
---@param b number
---@return number
bit.bor = function(a, b)
    return bit32.bor(a, b)
end

---stock api
---@param a number
---@param b number
---@return number
bit.bxor = function(a, b)
    return bit32.bxor(a, b)
end

return bit
