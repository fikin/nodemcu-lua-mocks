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
---@return integer
---@return integer
---@return integer
rtctime.get = function()
  local ts = nodemcu.rtctime
  return ts.sec, ts.usec, ts.rate
end

---stock API
---@param ts integer
---@return osdate
rtctime.epoch2cal = function(ts)
  assert(type(ts) == "number")
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
