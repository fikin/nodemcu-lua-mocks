--[[
License : GPLv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local Timer = require("Timer")

---@alias TimerObj_fn fun(t:TimerObj)

---actual implementation of one timer object
---@class TimerObj
TimerObj = {
    id = 0,
    delay = 0,
    ---@type TimerObj_fn
    callback = function(_) end,
    startTime = 0,
    repetitionsCntWhenCreated = 0,
    repetitionsCnt = 0
}
TimerObj.__index = TimerObj

local createdTimersCnt = 0

---new timer object
---@param delay integer
---@param callback tmr_fn
---@param repetitionsCnt integer
---@return TimerObj
TimerObj.create = function(delay, callback, repetitionsCnt)
    assert(type(delay) == "number", "delay must be number")
    assert(type(callback) == "function", "callback must be a function")
    assert(type(repetitionsCnt) == "number", "repetitionsCnt must be number")
    createdTimersCnt = createdTimersCnt + 1
    local o = {
        id = createdTimersCnt,
        delay = delay,
        callback = callback,
        repetitionsCntWhenCreated = repetitionsCnt,
        repetitionsCnt = repetitionsCnt,
    }
    setmetatable(o, TimerObj)
    return o
end

---test if it is started
---@param self TimerObj
---@return boolean
TimerObj.isStarted = function(self)
    assert(type(self) == "table")
    return Timer._timers:contains(self)
end

---prepares for next schedule
---@param self TimerObj
TimerObj.beforeNextStart = function(self)
    assert(type(self) == "table")
    self.startTime = Timer.getCurrentTimeMs()
    self.repetitionsCnt = self.repetitionsCnt - 1
end

---starts the timer
---@param self TimerObj
TimerObj.start = function(self)
    assert(type(self) == "table")
    if self:isStarted() then
        return
    end
    self.repetitionsCnt = self.repetitionsCntWhenCreated
    Timer._timers:append(self)
    self:beforeNextStart()
end

---stops the timer
---@param self TimerObj
TimerObj.stop = function(self)
    assert(type(self) == "table")
    if self:isStarted() then
        Timer._timers:remove(self)
        self.repetitionsCnt = 0
    end
end

---resumes the timer
---@param self TimerObj
---@param currTimeStampMs integer
TimerObj.resume = function(self, currTimeStampMs)
    assert(type(self) == "table")
    assert(type(currTimeStampMs) == "number", "currTimeStampMs must be a number")
    assert(self:isStarted(), "TimerObj : resume() called before start() for timer " .. self.id)
    if Timer.hasDelayElapsedSince(currTimeStampMs, self.startTime, self.delay) then
        self.callback(self)
        if self.repetitionsCnt == 0 then
            self:stop()
        else
            self:beforeNextStart()
        end
    end
end

return TimerObj
