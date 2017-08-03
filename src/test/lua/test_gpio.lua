--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]

luaunit = require('luaunit')

require('gpio')

function testReadWrite()
  gpio.TestData.reset()
  luaunit.assertEquals(gpio.read(1),gpio.HIGH)
  gpio.write(1,gpio.LOW)
  luaunit.assertEquals(gpio.read(1),gpio.LOW)
end

function testTrigger()
  gpio.TestData.reset()
  local callCnt = 0
  gpio.trig(1,"both",function(level, time)
    callCnt = callCnt + 1 
  end)
  gpio.TestData.setLow(1)
  gpio.TestData.setHigh(1)
  luaunit.assertEquals(callCnt,2)
end

function testBeforeReadCallback()
  gpio.TestData.reset()
  gpio.TestData.setBeforeReadCalback(1,function(pin,value)
    assert(pin == 1, 'callback is for pin 1 only')
    assert(value == gpio.HIGH, 'defalt value expected for pin 1')
    gpio.write(pin, gpio.LOW) 
  end)
  luaunit.assertEquals( gpio.read(1), gpio.LOW)
end

function testPinValueToggleTimer()
  gpio.TestData.reset()
  gpio.TestData.togglePinTimer(1, 1, 4)
  luaunit.assertEquals( gpio.read(1), gpio.HIGH)
  Timer.joinAll(1)
  luaunit.assertEquals( gpio.read(1), gpio.LOW)
  Timer.joinAll(1)
  luaunit.assertEquals( gpio.read(1), gpio.HIGH)
end

function testReadSequence()
  gpio.TestData.reset()
  gpio.TestData.setPinValueReadSequence(1, { gpio.LOW, gpio.HIGH, gpio.HIGH })
  luaunit.assertEquals( gpio.read(1), gpio.LOW)
  luaunit.assertEquals( gpio.read(1), gpio.HIGH)
  luaunit.assertEquals( gpio.read(1), gpio.HIGH)
  luaunit.assertEquals( gpio.read(1), gpio.LOW)
end

os.exit( luaunit.LuaUnit.run() )
