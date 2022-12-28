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


---looks up static timers and returns the one with given index
---@param indx integer
---@return tmr_instance
local function getExistingTimerObj(indx)
  local tmrInst = nodemcu.staticTimers[indx + 1]
  if not tmrInst then
    error("Cannot start not registered timer with index " .. indx)
  end
  return tmrInst
end

---if timerObj is index, returns static timer, othewise timerObj is returned
---@param tmrInst tmr_instance|integer
---@return tmr_instance
local function resolveTimerObj(tmrInst)
  if type(tmrInst) == "number" then
    return getExistingTimerObj(tmrInst)
  else
    ---@cast tmrInst tmr_instance
    return tmrInst
  end
end

--- tmr.create is stock nodemcu API
---@return tmr_instance
tmr.create = function()
  --print('tmr create')
  local o = {}
  setmetatable(o, tmr)
  return o
end

--- tmr.register is stock nodemcu API
---@param tmrInst integer|tmr_instance
---@param delay integer
---@param reoccurType integer
---@param cb tmr_fn
tmr.register = function(tmrInst, delay, reoccurType, cb)
  --  print('tmr register '..tostring(timerObj)..' '..tostring(delay)..' '..tostring(reoccurType)..' '..tostring(callback))
  if type(tmrInst) == "number" then
    local indx = tmrInst + 1
    tmrInst = tmr.create()
    tmrInst.indx = indx
    nodemcu.staticTimers[indx] = tmrInst
  end
  local cbWrapper = function()
    ---@cast tmrInst tmr_instance
    cb(tmrInst)
  end
  tmrInst.timer =
  reoccurType == tmr.ALARM_AUTO and Timer.createReoccuring(delay, cbWrapper) or Timer.createSingle(delay, cbWrapper)
end

--- tmr.unregister is stock nodemcu API
---@param tmrInst tmr_instance|integer
tmr.unregister = function(tmrInst)
  --print('tmr unregister '..tostring(timerObj))
  tmrInst = resolveTimerObj(tmrInst)
  tmrInst.timer:stop()
  tmrInst.timer = nil
  if tmrInst.indx then
    nodemcu.staticTimers[tmrInst.indx] = nil
    tmrInst.indx = nil
  end
end

--- tmr.start is stock nodemcu API
---@param tmrInst tmr_instance|integer
---@return boolean
tmr.start = function(tmrInst)
  tmrInst = resolveTimerObj(tmrInst)
  tmrInst.timer:start()
  return true
end

--- tmr.stop is stock nodemcu API
---@param tmrInst tmr_instance|integer
---@return boolean
tmr.stop = function(tmrInst)
  tmrInst = resolveTimerObj(tmrInst)
  tmrInst.timer:stop()
  return true
end

--- tmr.alarm is stock nodemcu API
---@param tmrInst tmr_instance|integer
---@param delay integer
---@param reoccurType integer
---@param cb tmr_fn
---@return boolean
tmr.alarm = function(tmrInst, delay, reoccurType, cb)
  --print('tmr alarm '..tostring(timerObj)..' '..tostring(delay)..' '..tostring(reoccurType)..' '..tostring(callback))
  tmr.register(tmrInst, delay, reoccurType, cb)
  return tmr.start(tmrInst)
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
