--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local modname = ...
local Timer = require("Timer")
local nodemcu = require("nodemcu-module")

---@class tmr_instance
---@field timer TimerObj
tmr = {}
tmr.__index = tmr

---@alias tmr_fn fun(t:tmr_instance)

tmr.ALARM_SINGLE = 1
tmr.ALARM_SEMI = 2
tmr.ALARM_AUTO = 3


--- tmr.create is stock nodemcu API
---@return tmr_instance
tmr.create = function()
  local o = {}
  setmetatable(o, tmr)
  return o
end

--- tmr.register is stock nodemcu API
---@param self tmr_instance
---@param delay integer
---@param reoccurType integer
---@param cb tmr_fn
tmr.register = function(self, delay, reoccurType, cb)
  local cbWrapper = function()
    cb(self)
  end
  self.timer = (reoccurType == tmr.ALARM_AUTO)
      and Timer.createReoccuring(delay, cbWrapper)
      or Timer.createSingle(delay, cbWrapper)
end

--- tmr.unregister is stock nodemcu API
---@param self tmr_instance
tmr.unregister = function(self)
  self.timer:stop()
  self.timer = nil
end

--- tmr.start is stock nodemcu API
---@param self tmr_instance
---@return boolean
tmr.start = function(self)
  self.timer:start()
  return true
end

--- tmr.stop is stock nodemcu API
---@param self tmr_instance
---@return boolean
tmr.stop = function(self)
  self.timer:stop()
  return true
end

--- tmr.alarm is stock nodemcu API
---@param self tmr_instance
---@param delay integer
---@param reoccurType integer
---@param cb tmr_fn
---@return boolean
tmr.alarm = function(self, delay, reoccurType, cb)
  tmr.register(self, delay, reoccurType, cb)
  return tmr.start(self)
end

--- tmr.now is stock nodemcu API
---@return integer
tmr.now = function()
  return (Timer.getCurrentTimeMs() % require("duration").TMR_SWAP_TIME) * 1000 -- return microsec, mimic 31 bit cycle over
end

--- tmr.delay is stock nodemcu API
---@param us integer
tmr.delay = function(us)
  local t0 = tmr.now()
  while tmr.now() - t0 <= us do
  end
end

return tmr
