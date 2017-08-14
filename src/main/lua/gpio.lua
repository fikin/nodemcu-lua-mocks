--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]

gpio = {}
gpio.__index = gpio

gpio.INT = 1
gpio.INPUT = 2

gpio.HIGH = 1
gpio.LOW = 0

gpio.PULLUP = 3

require('Timer')

gpio.TestData = {}
gpio.TestData.reset = function()
  gpio.TestData.pinTriggers = {}
  gpio.TestData.pinStates = {}
  gpio.TestData.pinBeforeReadTriggers = {}
  Timer.reset()
end
gpio.TestData.reset()

local function triggerPinCallback(pin, what)
  local trg = gpio.TestData.pinTriggers[pin]
  if trg and ( what == trg.what or trg.what == 'both' ) then
    trg.callback( gpio.TestData.pinStates[pin], os.time() )
  end
end
local function togglePin(pin)
  if gpio.read(pin) == gpio.HIGH then
    gpio.write(pin, gpio.LOW)
    triggerPinCallback(pin, "down")
  else
    gpio.write(pin, gpio.HIGH)
    triggerPinCallback(pin, "up")
  end
end

gpio.mode = function(pin,mode, level)
  gpio.TestData.pinStates[pin] = gpio.HIGH
  if level == gpio.PULLUP then
    gpio.write(pin,gpio.HIGH)
  end
end

gpio.trig = function(pin,what,callback)
  if what ~= "none" and callback then
    gpio.TestData.pinTriggers[pin] = { what = what, callback = callback }
  elseif gpio.TestData.pinTriggers[pin] then
    gpio.TestData.pinTriggers[pin] = nil
  end
end

gpio.write = function(pin, val)
  gpio.TestData.pinStates[pin] = val
end

gpio.read = function(pin)
  if gpio.TestData.pinBeforeReadTriggers[pin] then
    gpio.TestData.pinBeforeReadTriggers[pin](pin, gpio.TestData.pinStates[pin] and gpio.TestData.pinStates[pin] or gpio.HIGH)
  end
  if gpio.TestData.pinStates[pin] then
    return gpio.TestData.pinStates[pin]
  else
    return gpio.HIGH
  end
end

gpio.TestData.setHigh = function(pin)
  gpio.write(pin,gpio.HIGH)
  triggerPinCallback(pin,"up")
end
gpio.TestData.setLow = function(pin)
  gpio.write(pin,gpio.LOW)
  triggerPinCallback(pin,"down")
end
gpio.TestData.togglePinTimer = function(pin,interval,howManyTimes)
  local t = Timer.createReoccuring(interval,function(timerObj) 
    togglePin(pin)
  end, howManyTimes)
  t:start()
  return t
end
gpio.TestData.setBeforeReadCalback = function(pin, cb)
  gpio.TestData.pinBeforeReadTriggers[pin] = cb
end
gpio.TestData.setPinValueReadSequence = function(pin, valuesArr)
  local i = 0 
  gpio.TestData.setBeforeReadCalback(pin, function(pin2, val2)
    i = (i < table.getn(valuesArr) and i or 0) + 1
    gpio.write(pin2,valuesArr[i])
  end)
end

return gpio