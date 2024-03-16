--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local nodemcu = require("nodemcu-module")
local bit32 = require("bit32")

---@class rtcmem
rtcmem = {}
rtcmem.__index = rtcmem

---stock API
---@param indx integer
---@param num? integer
---@return integer
rtcmem.read32 = function(indx, num)
  -- TODO add support for num
  num = num or 1

  local val = nodemcu.rtcmem[indx]
  for i = 2, num do
    val = nodemcu.rtcmem[indx + i] + bit32.lshift(val, 8)
  end
  return val
end

---stock API
---@param indx integer index
---@param ... integer byte values, each in own position
rtcmem.write32 = function(indx, ...)
  for i, val in ipairs(table.pack(...)) do
    nodemcu.rtcmem[indx + i - 1] = val
  end
end

return rtcmem
