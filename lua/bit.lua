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

---stock api
---@param a number
---@param b number
---@return number
bit.band = function(a, b)
    return bit32.band(a, b)
end

---stock api
---@param a number
---@param b number
---@return number
bit.rshift = function(a, b)
    return bit32.rshift(a, b)
end

---stock api
---@param a number
---@param b number
---@return number
bit.lshift = function(a, b)
    return bit32.lshift(a, b)
end

---stock api
---@param a number
---@param b number
---@return boolean
bit.isset = function(a, b)
    return bit32.band(bit32.rshift(a, b), 1) == 1
end

---stock api
---@param a number
---@param b number
---@return boolean
bit.isclear = function(a, b)
    return bit32.band(bit32.rshift(a, b), 1) == 0
end

---stock api
---@param a number
---@param b number
---@return number
bit.clear = function(a, b)
    local mask = bit32.bnot(bit32.lshift(1, b))
    return bit32.band(a, mask)
end

---stock api
---@param a number
---@param b number
---@return number
bit.set = function(a, b)
    local mask = bit32.lshift(1, b)
    return bit32.bor(a, mask)
end

return bit
