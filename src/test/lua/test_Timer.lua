--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]

luaunit = require('luaunit')

require('Timer')

function testEmptyListOfTimers()
  Timer.reset()
  Timer.joinAll(1)
end

function testSingle()
  Timer.reset()
  local callsCnt = 0
  local tt = nil
  local t = Timer.createSingle(1,function(timerObj)
    luaunit.assertEquals(tt,timerObj)
    callsCnt = callsCnt + 1
  end)
  tt = t
  t:start()
  Timer.joinAll(2)
  luaunit.assertEquals( callsCnt, 1 )
end

function testReoccuring()
  Timer.reset()
  local callsCnt = 0
  local t = Timer.createReoccuring(1,function(timerObj)
    callsCnt = callsCnt + 1
  end)
  t:start()
  Timer.joinAll(3)
  luaunit.assertEquals( callsCnt, 3 )
end

function testStopFromWithinCallback()
  Timer.reset()
  local callsCnt = 0
  local t = Timer.createReoccuring(1,function(timerObj)
    timerObj:stop()
    callsCnt = callsCnt + 1
  end)
  t:start()
  Timer.joinAll(5)
  luaunit.assertEquals( callsCnt, 1 )
end

os.exit( luaunit.LuaUnit.run() )
