--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]

luaunit = require('luaunit')

require('tmr')

function testDynamicTimer()
  tmr.TestData.reset()
  local fncCalled = 0
  local t = tmr.create()
  t:register( 1, tmr.ALARM_SINGLE, function(timerObj)
    fncCalled = 1
    timerObj:unregister()
  end)
  luaunit.assertTrue( t:start() )
  Timer.joinAll(100)
  luaunit.assertEquals(fncCalled,1)
end

function testStaticTimer()
  tmr.TestData.reset()
  local fncCalled = 0
  tmr.register( 3, 1, tmr.ALARM_SINGLE, function(timerObj)
    fncCalled = 2
    tmr.unregister(3)
  end)
  luaunit.assertTrue( tmr.start(3) )
  Timer.joinAll(100)
  luaunit.assertEquals(fncCalled,2)
end

function testDynamicAlarm()
  tmr.TestData.reset()
  local fncCalled = 0
  luaunit.assertTrue(  tmr.create():alarm( 1, tmr.ALARM_SINGLE, function(timerObj)
    fncCalled = 1
    timerObj:unregister()
  end) )
  Timer.joinAll(100)
  luaunit.assertEquals(fncCalled,1)
end

function testStaticAlarm()
  tmr.TestData.reset()
  local fncCalled = 0
  luaunit.assertTrue( tmr.alarm( 5, 1, tmr.ALARM_SINGLE, function(timerObj)
    fncCalled = 1
    tmr.unregister(5)
  end) )
  Timer.joinAll(100)
  luaunit.assertEquals(fncCalled,1)
end

os.exit( luaunit.LuaUnit.run() )
