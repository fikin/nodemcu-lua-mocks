--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local nodemcu = require("nodemcu-module")
local inspect = require("inspect")
local contains = require("contains")
local pinState = require("gpio_pin_state")

gpio = {}
gpio.__index = gpio

gpio.INT = 1
gpio.INPUT = 2
gpio.OUTPUT = 3
gpio.OPENDRAIN = 4

gpio.PULLUP = 5
gpio.FLOAT = 6

gpio.HIGH = 1
gpio.LOW = 0

local pullupEnum = {gpio.PULLUP, gpio.FLOAT}
local modeEnum = {gpio.INT, gpio.INPUT, gpio.OUTPUT, gpio.OPENDRAIN}
local trigTypeEnum = {"none", "up", "down", "both", "high", "low"}

--- gpio.mode is stock nodemcu API
gpio.mode = function(pin, mode, pullup)
  local p = nodemcu.assertPinRange(pin)
  assert(contains(modeEnum, mode), "expects mode " .. inspect(modeEnum) .. " but found " .. mode)
  if pullup ~= nil then
    assert(contains(pullupEnum, pullup), "expects pullup " .. inspect(pullupEnum) .. " but found " .. pullup)
  end
  p.mode = mode
  p.pullup = pullup or gpio.FLOAT
end

--- gpio.trig is stock nodemcu API
gpio.trig = function(pin, what, callback)
  local p = nodemcu.assertPinRange(pin)
  assert(type(what) == "string", "what must be string")
  assert(contains(trigTypeEnum, what), "expects what " .. inspect(trigTypeEnum) .. " but found " .. what)
  if callback ~= nil then
    assert(type(callback) == "function", "callback must be a function")
  end
  p.trigWhat = what
  if what == "none" then
    p.trigCb = defaultTrigCb
  else
    p.trigCb = callback or defaultTrigCb
  end
end

--- gpio.write is stock nodemcu API
gpio.write = function(pin, val)
  local p = nodemcu.assertPinRange(pin)
  assert(contains(pinState.writeEnum, val), "expects pin value " .. inspect(pinState.writeEnum) .. " but found " .. tostring(val))
  p.cbGetValue = function()
    return val
  end
  p.cbOnWrite(pin, val)
end

--- gpio.read is stock nodemcu API
gpio.read = function(pin)
  local p = nodemcu.assertPinRange(pin)
  assert(p.mode == gpio.INPUT, "expects pin mode = INPUT but found " .. p.mode)
  return p.cbGetValue(pin)
end

return gpio
