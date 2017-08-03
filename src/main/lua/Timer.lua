--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]

Timer = {}
Timer.__index = Timer

Timer.getCurrentTimeMs = function()
  local a, ms = math.modf(os.clock()*1000)
  return a
end

Timer.getElapsedTime = function(endTimeMs, startTimeMs)
  local e = endTimeMs - startTimeMs
  assert(e >= 0, 'Elapsed time negative !!! '..e)
  return e
end

Timer.hasDelayElapsed = function(elapsedMs, delayMs)
  return elapsedMs >= delayMs
end

Timer.hasDelayElapsedSince = function(endTimeMs, startTimeMs, delayMs)
  return Timer.hasDelayElapsed( Timer.getElapsedTime(endTimeMs,startTimeMs),delayMs)
end

Timer.reset = function()
  Timer._timers = require('LinkedList').create()
end
Timer.reset()

TimerObj = {}
TimerObj.__index = TimerObj
local createdTimersCnt = 0
TimerObj.create = function(delay, callback, repetitionCnt)
  local o = {}
  setmetatable(o, TimerObj)
  createdTimersCnt = createdTimersCnt + 1
  o.id = createdTimersCnt
  o.delay = delay
  o.callback = callback
  o.repetitionCnt = repetitionCnt
  return o
end
TimerObj.isStarted = function(self)
  return Timer._timers:contains(self)
end
TimerObj.beforeNextStart = function(self)
  self.startTime = Timer.getCurrentTimeMs()
  self.repetitionCnt = self.repetitionCnt - 1
end
TimerObj.start = function(self)
  if self:isStarted() then return end
  Timer._timers:append(self)
  self:beforeNextStart()
end
TimerObj.stop = function(self)
  if self:isStarted() then
    Timer._timers:remove(self)
    self.repetitionCnt = 0
  end
end
TimerObj.resume = function(self, currTimeStampMs)
  assert( self:isStarted(), 'TimerObj : resume() called before start() for timer '..self.id )
  if Timer.hasDelayElapsedSince(currTimeStampMs, self.startTime, self.delay) then
    self.callback(self)
    if self.repetitionCnt == 0 then
      self:stop()
    else
      self:beforeNextStart()
    end
  end
end

Timer.createSingle = function(delay, callback)
  return TimerObj.create(delay, callback, 1)
end
Timer.createReoccuring = function(delay, callback)
  return TimerObj.create(delay, callback, 1000000000)
end

Timer.joinAll = function(waitTimeMs)
  if not waitTimeMs or waitTimeMs <= 0 then
    waitTimeMs = 1000000000
  end
  local enterLoopTime = 0
  while true do
    local currLoopTime = Timer.getCurrentTimeMs()
    if enterLoopTime == 0 then enterLoopTime = currLoopTime end
    if Timer._timers:size() == 0 then break end
    for i, v in ipairs(Timer._timers:toArray()) do
      v:resume(currLoopTime)
    end
    if Timer.hasDelayElapsedSince(currLoopTime, enterLoopTime, waitTimeMs) then break end 
  end
end
