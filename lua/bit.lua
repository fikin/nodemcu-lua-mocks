--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
bit = {}
bit.__index = bit

--- bit.bnot is stock nodemcu API
bit.bnot = function(a)
    return bit32.bnot(a)
end

--- bit.bor is stock nodemcu API
bit.bor = function(a, b)
    return bit32.bor(a, b)
end

--- bit.bxor is stock nodemcu API
bit.bxor = function(a, b)
    return bit32.bxor(a, b)
end

return bit
