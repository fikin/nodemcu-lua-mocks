--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local nodemcu = require("nodemcu-module")

---@class rtcmem
rtcmem = {}
rtcmem.__index = rtcmem

---stock API
---@param indx integer
---@param num? integer
---@return integer ...
rtcmem.read32 = function(indx, num)
  local arr = {}
  for i = 1, num or 1 do
    table.insert(arr, nodemcu.rtcmem[indx + i - 1])
  end

  return table.unpack(arr)
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
