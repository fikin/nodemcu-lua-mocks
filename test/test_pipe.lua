--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
-- ==========================
-- ==========================
-- ==========================
local lu = require("luaunit")
local pipeFactory = require("pipe")
local nodemcu = require("nodemcu")
local tools = require("tools")

local function before(inData)
    nodemcu.reset()

    local o = {
        isEOF = false,
        dataCb = tools.arrayToFunc(inData, false),
        consumer = tools.collectDataToArray()
    }
    o.coro, o.tmr =
        pipeFactory.createTimerPipeline(
        function()
            return o.isEOF, o.dataCb()
        end,
        o.consumer.putCb,
        false
    )
    return o
end

function testCoroutine()
    local inputData = {"1", "2"}
    local o = before(inputData)

    coroutine.resume(o.coro)
    coroutine.resume(o.coro)
    coroutine.resume(o.coro)
    coroutine.resume(o.coro)

    lu.assertEquals(o.consumer.get(), inputData)
end

function testTimer()
    local o = before({"123", "456"})

    o.tmr:start()
    nodemcu.advanceTime(13)

    lu.assertEquals(o.consumer.get(), {"123", "456"})
end

function testStartWithNulThenPickSomeData()
    nodemcu.reset()

    local isEOF = false
    local value = nil
    local consumeCb = tools.collectDataToArray()
    local coro =
        pipeFactory.createCoroutinePipeline(
        function()
            return isEOF, value
        end,
        consumeCb.putCb
    )

    coroutine.resume(coro)
    lu.assertEquals(consumeCb.get(), {})
    value = "A"
    coroutine.resume(coro)
    lu.assertEquals(consumeCb.get(), {"A"})
end

os.exit(lu.run())
