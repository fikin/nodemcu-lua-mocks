--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local lu = require("luaunit")
local tools = require("tools")
local nodemcu = require("nodemcu")

function testReadWrite()
  nodemcu.reset()
  gpio.mode(1, gpio.INPUT, gpio.PULLUP)
  lu.assertEquals(nodemcu.gpio_get_mode(1), gpio.INPUT)
  lu.assertEquals(gpio.read(1), gpio.HIGH)
  gpio.write(1, gpio.LOW)
  lu.assertEquals(gpio.read(1), gpio.LOW)
  gpio.write(1, gpio.HIGH)
  lu.assertEquals(gpio.read(1), gpio.HIGH)
end

function testTrigger()
  nodemcu.reset()
  for i = 1, 5 do
    gpio.mode(i, gpio.OUTPUT)
    lu.assertEquals(nodemcu.gpio_get_mode(i), gpio.OUTPUT)
  end
  local function collectLevelsFor(pin, what)
    local str = ""
    gpio.trig(
      pin,
      what,
      function(level, time)
        str = str .. tostring(level)
      end
    )
    return function()
      return str
    end
  end
  local both = collectLevelsFor(1, "both")
  local up = collectLevelsFor(2, "up")
  local down = collectLevelsFor(3, "down")
  local low = collectLevelsFor(4, "low")
  local high = collectLevelsFor(5, "high")
  local signal = {gpio.LOW, gpio.HIGH, gpio.LOW, gpio.HIGH}
  for i = 1, #signal do
    for j = 1, 5 do
      nodemcu.gpio_set(j, signal[i])
    end
  end
  lu.assertEquals(both(), "0101")
  lu.assertEquals(up(), "11")
  lu.assertEquals(down(), "00")
  lu.assertEquals(low(), "00")
  lu.assertEquals(up(), "11")
end

function testToggleCallbackFnc()
  nodemcu.reset()
  gpio.mode(2, gpio.INPUT, gpio.PULLUP)
  local val = gpio.HIGH
  nodemcu.gpio_set(
    2,
    function(pin)
      assert(pin == 2, "callback is for pin 1 only")
      val = (val == gpio.LOW) and gpio.HIGH or gpio.LOW
      return val
    end
  )
  lu.assertEquals(gpio.read(2), gpio.LOW)
  lu.assertEquals(gpio.read(2), gpio.HIGH)
  lu.assertEquals(gpio.read(2), gpio.LOW)
  lu.assertEquals(gpio.read(2), gpio.HIGH)
end

function testReadSequence()
  nodemcu.reset()
  nodemcu.gpio_set(1, tools.cbReturnRingBuf({gpio.LOW, gpio.HIGH, gpio.HIGH}))
  gpio.mode(1, gpio.INPUT, gpio.PULLUP)
  lu.assertEquals(gpio.read(1), gpio.LOW)
  lu.assertEquals(gpio.read(1), gpio.HIGH)
  lu.assertEquals(gpio.read(1), gpio.HIGH)
  lu.assertEquals(gpio.read(1), gpio.LOW)
end

function testWriteSequence()
  nodemcu.reset()
  local data = tools.collectDataToArray()
  nodemcu.gpio_capture(1, data.putCb)
  gpio.mode(1, gpio.OUTPUT, gpio.PULLUP)
  local seq = {gpio.LOW, gpio.HIGH, gpio.HIGH, gpio.LOW}
  for i = 1, #seq do
    gpio.write(1, seq[i])
  end
  lu.assertEquals(data.get(), {{1, seq[1]}, {1, seq[2]}, {1, seq[3]}, {1, seq[4]}})
end

os.exit(lu.run())
