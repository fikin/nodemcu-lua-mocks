--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]

---bookeep all active TimerObj
---advances the time for all of them
---@class Timer
---@field _timers LinkedList
local Timer = {}
Timer.__index = Timer

---return current time
---@return integer
Timer.getCurrentTimeMs = function()
  local a, ms = math.modf(os.clock() * 1000)
  return a
end

---calculates elapsed time
---@param endTimeMs integer
---@param startTimeMs integer
---@return integer
Timer.getElapsedTime = function(endTimeMs, startTimeMs)
  local e = endTimeMs - startTimeMs
  assert(e >= 0, "Elapsed time negative !!! " .. e)
  return e
end

---test if time has elapsed
---@param elapsedMs integer
---@param delayMs integer
---@return boolean
Timer.hasDelayElapsed = function(elapsedMs, delayMs)
  return elapsedMs >= delayMs
end

---test if time has elapsed since
---@param endTimeMs integer
---@param startTimeMs integer
---@param delayMs integer
---@return boolean
Timer.hasDelayElapsedSince = function(endTimeMs, startTimeMs, delayMs)
  return Timer.hasDelayElapsed(Timer.getElapsedTime(endTimeMs, startTimeMs), delayMs)
end

---reset timer's timers
Timer.reset = function()
  Timer._timers = require("LinkedList").create()
end
Timer.reset()

---create single schedule timer
---@param delay integer
---@param callback TimerObj_fn
---@return TimerObj
Timer.createSingle = function(delay, callback)
  return require("TimerObj").create(delay, callback, 1)
end

---create reoccuring timer
---@param delay integer
---@param callback fun(t:TimerObj)
---@return TimerObj
Timer.createReoccuring = function(delay, callback)
  return require("TimerObj").create(delay, callback, 1000000000)
end

---advance the time of the timer and fire ready timers
---@param waitTimeMs integer
Timer.joinAll = function(waitTimeMs)
  assert(type(waitTimeMs) == "number", "waitTimeMs must be a number")
  if not waitTimeMs or waitTimeMs <= 0 then
    waitTimeMs = 1000000000
  end
  local enterLoopTime = 0
  while true do
    local currLoopTime = Timer.getCurrentTimeMs()
    if enterLoopTime == 0 then
      enterLoopTime = currLoopTime
    end
    if Timer._timers:size() == 0 then
      break
    end
    for _, v in ipairs(Timer._timers:toArray()) do
      ---@cast v TimerObj
      v:resume(currLoopTime)
    end
    if Timer.hasDelayElapsedSince(currLoopTime, enterLoopTime, waitTimeMs) then
      break
    end
  end
end

return Timer
