--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
-- ==========================
-- ==========================
-- ==========================
local Timer = require("Timer")

--- createCoroutinePipeline creates a pipe (implemented as coroutine) and timer
-- Piping coroutine is reading from inputCb and putting it to outputCb.
-- @param inputCb is "function()(isEOF,data)" where data is next patch of information and isEOF indicates end of data
-- @param outputCb is "function(data)void" where data is next patch of information, not bigger than chunkSize
-- @return coroutine object
local function createCoroutinePipeline(inputCb, outputCb)
    assert(type(inputCb) == "function", "inputCb must be a function")
    assert(type(outputCb) == "function", "inputCb must be a function")

    return coroutine.create(
        function()
            while true do
                local isEOF, data = inputCb()
                if isEOF then
                    break
                end
                outputCb(data)
                coroutine.yield()
            end
        end
    )
end

--- wrapInTimerLoop is wrapping a coroutine in timemer to execute its resume() periodically
-- @param coro is coroutine to wrap in timer loop
-- @param autoStart if true it starts the timer, by defualt true
-- @param timerDelayMs is timer loop delay in ms. by default 1
-- @return timer object
local function wrapInTimerLoop(coro, autoStart, timerDelayMs)
    assert(type(coro) == "thread", "coro must be a coroutine")
    autoStart = (autoStart == nil and true or autoStart)
    assert(type(autoStart) == "boolean", "autoStart must be boolean")
    timerDelayMs = timerDelayMs or 1
    assert(type(timerDelayMs) == "number", "timerDelayMs must be number")
    local tmr =
        Timer.createReoccuring(
        timerDelayMs,
        function(timerObj)
            if coroutine.status(coro) == "dead" then
                timerObj:stop()
            else
                coroutine.resume(coro)
            end
        end
    )

    if autoStart then
        tmr:start()
    end

    return tmr
end

--- createTimerPipeline is creating a pipeline coroutine and timer associated with it
-- see createCoroutinePipeline and wrapInTimerLoop for more details
-- @param inputCb is "function()(isEOF,data)" where data is next patch of information and isEOF indicates end of data
-- @param outputCb is "function(data)void" where data is next patch of information, not bigger than chunkSize
-- @param autoStart if true it starts the timer, by defualt true
-- @param timerDelayMs is timer loop delay in ms. by default 1
-- @return two arguments : coro, tmr
local function createTimerPipeline(inputCb, outputCb, autoStart, timerDelayMs)
    local coro = createCoroutinePipeline(inputCb, outputCb)
    local tmr = wrapInTimerLoop(coro, autoStart, timerDelayMs)
    return coro, tmr
end

return {
    createCoroutinePipeline = createCoroutinePipeline,
    wrapInTimerLoop = wrapInTimerLoop,
    createTimerPipeline = createTimerPipeline
}
