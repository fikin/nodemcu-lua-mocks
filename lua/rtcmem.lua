--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local nodemcu = require("nodemcu-module")

---@class rtcmem
rtcmem = {}
rtcmem.__index = rtcmem

---stock API
-- @param channel must be 0
-- @return value from cb. If cb is not assigned, returns fixed 1024.
---@param indx integer
---@param num? integer
---@return integer
rtcmem.read32 = function(indx, num)
  -- TODO add support for num
  return nodemcu.rtcmem[indx]
end

return rtcmem
