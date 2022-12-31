--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local nodemcu = require("nodemcu-module")

---@class rtctime
rtctime = {}
rtctime.__index = rtctime

---@class rtctime_ts
---@field sec integer seconds since the Unix epoch
---@field usec integer the microseconds part
---@field rate integer the current clock rate offset.

---stock API
---@return rtctime_ts
rtctime.get = function()
  return nodemcu.rtctime
end

---stock API
---@param ts integer
---@return osdate
rtctime.epoch2cal = function(ts)
  local dt = os.date("*t", nodemcu.rtctime.sec)
  dt.mon = dt.month
  ---@cast dt osdate
  return dt
end

---stock API
---@param sec integer
---@param usec? integer
---@param rate? integer
rtctime.set = function(sec, usec, rate)
  nodemcu.rtctime.sec = sec or nodemcu.rtctime.sec
  nodemcu.rtctime.usec = usec or nodemcu.rtctime.usec
  nodemcu.rtctime.rate = rate or nodemcu.rtctime.rate
end

return rtctime
