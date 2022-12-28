--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local nodemcu = require("nodemcu-module")
local inspect = require("inspect")
local contains = require("contains")
local pinState = require("gpio_pin_state")

---@class gpio
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

local defaultTrigCb = function(_, _) end
---@enum gpio_trig_type
local trigTypeEnum = { "none", "up", "down", "both", "high", "low" }


---gpio.mode is stock nodemcu API
---@param pin integer
---@param mode integer
---@param pullup? integer
gpio.mode = function(pin, mode, pullup)
  local p = nodemcu.getDefinedPin(pin)
  p.mode = mode
  p.pullup = pullup or gpio.FLOAT
end

---gpio.trig is stock nodemcu API
---@param pin integer
---@param what gpio_trig_type
---@param cb gpio_trig_fn
gpio.trig = function(pin, what, cb)
  local p = nodemcu.getDefinedPin(pin)
  assert(type(what) == "string", "what must be string")
  assert(contains(trigTypeEnum, what), "expects what " .. inspect(trigTypeEnum) .. " but found " .. what)
  cb = cb or defaultTrigCb
  assert(type(cb) == "function", "callback must be a function")
  p.trigWhat = what
  p.trigCb = (what == "none") and defaultTrigCb or cb
end

---gpio.write is stock nodemcu API
---@param pin integer
---@param val integer
gpio.write = function(pin, val)
  local p = nodemcu.getDefinedPin(pin)
  assert(p.mode == gpio.OUTPUT, string.format("expects pin %d mode to be OUTPUT but found %d", pin, p.mode))
  assert(val == gpio.HIGH or val == gpio.LOW,
    string.format("expects value of gpio.HIGH or LOW for pin %d but found %d", pin, val))
  p.cbGetValue = function() return val; end
  p.cbOnWrite(pin, val)
end

---gpio.read is stock nodemcu API
---@param pin integer
---@return number
gpio.read = function(pin)
  local p = nodemcu.getDefinedPin(pin)
  assert(p.mode == gpio.INPUT, string.format("expects pin %d mode to be INPUT but found %d", pin, p.mode))
  return p.cbGetValue()
end

return gpio
