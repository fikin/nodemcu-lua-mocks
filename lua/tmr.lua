--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local Timer = require("Timer")
local nodemcu = require("nodemcu-module")

tmr = {}
tmr.__index = tmr

tmr.ALARM_SINGLE = 1
tmr.ALARM_SEMI = 2
tmr.ALARM_AUTO = 3

local function getExistingTimerObj(indx)
  local timerObj = nodemcu.staticTimers[indx + 1]
  if not timerObj then
    error("Cannot start not registered timer with index " .. indx)
  end
  return timerObj
end

local function resolveTimerObj(timerObj)
  return type(timerObj) == "number" and getExistingTimerObj(timerObj) or timerObj
end

--- tmr.create is stock nodemcu API
tmr.create = function()
  --print('tmr create')
  local o = {}
  setmetatable(o, tmr)
  return o
end

--- tmr.register is stock nodemcu API
tmr.register = function(timerObj, delay, reoccurType, callback)
  --  print('tmr register '..tostring(timerObj)..' '..tostring(delay)..' '..tostring(reoccurType)..' '..tostring(callback))
  if type(timerObj) == "number" then
    local indx = timerObj + 1
    timerObj = tmr.create()
    timerObj.indx = indx
    nodemcu.staticTimers[indx] = timerObj
  end
  local cbWrapper = function(realTimerObj)
    callback(timerObj)
  end
  timerObj.timer =
    reoccurType == tmr.ALARM_SINGLE and Timer.createSingle(delay, cbWrapper) or Timer.createReoccuring(delay, cbWrapper)
end

--- tmr.unregister is stock nodemcu API
tmr.unregister = function(timerObj)
  --print('tmr unregister '..tostring(timerObj))
  timerObj = resolveTimerObj(timerObj)
  timerObj.timer:stop()
  timerObj.timer = nil
  if timerObj.indx then
    nodemcu.staticTimers[timerObj.indx] = nil
    timerObj.indx = nil
  end
end

--- tmr.start is stock nodemcu API
tmr.start = function(timerObj)
  timerObj = resolveTimerObj(timerObj)
  timerObj.timer:start()
  return true
end

--- tmr.stop is stock nodemcu API
tmr.stop = function(timerObj)
  timerObj = resolveTimerObj(timerObj)
  timerObj.timer:stop()
  return true
end

--- tmr.alarm is stock nodemcu API
tmr.alarm = function(timerObj, delay, reoccurType, callback)
  --print('tmr alarm '..tostring(timerObj)..' '..tostring(delay)..' '..tostring(reoccurType)..' '..tostring(callback))
  tmr.register(timerObj, delay, reoccurType, callback)
  return tmr.start(timerObj)
end

--- tmr.now is stock nodemcu API
tmr.now = function()
  return (Timer.getCurrentTimeMs() % require("duration").TMR_SWAP_TIME) * 1000 -- return microsec, mimic 31 bit cycle over
end

return tmr
