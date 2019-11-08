--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local lu = require("luaunit")
local nodemcu = require("nodemcu")

function testDynamicTimer()
  nodemcu.reset()
  local fncCalled = 0
  local t = tmr.create()
  t:register(
    1,
    tmr.ALARM_SINGLE,
    function(timerObj)
      fncCalled = 1
      timerObj:unregister()
    end
  )
  lu.assertTrue(t:start())
  nodemcu.advanceTime(100)
  lu.assertEquals(fncCalled, 1)
end

function testStaticTimer()
  nodemcu.reset()
  local fncCalled = 0
  tmr.register(
    3,
    1,
    tmr.ALARM_SINGLE,
    function(timerObj)
      fncCalled = 2
      tmr.unregister(3)
    end
  )
  lu.assertTrue(tmr.start(3))
  nodemcu.advanceTime(100)
  lu.assertEquals(fncCalled, 2)
end

function testDynamicAlarm()
  nodemcu.reset()
  local fncCalled = 0
  lu.assertTrue(
    tmr.create():alarm(
      1,
      tmr.ALARM_SINGLE,
      function(timerObj)
        fncCalled = 1
        timerObj:unregister()
      end
    )
  )
  nodemcu.advanceTime(100)
  lu.assertEquals(fncCalled, 1)
end

function testStaticAlarm()
  nodemcu.reset()
  local fncCalled = 0
  lu.assertTrue(
    tmr.alarm(
      5,
      1,
      tmr.ALARM_SINGLE,
      function(timerObj)
        fncCalled = 1
        tmr.unregister(5)
      end
    )
  )
  nodemcu.advanceTime(100)
  lu.assertEquals(fncCalled, 1)
end

os.exit(lu.run())
