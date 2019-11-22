--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local nodemcu = require("nodemcu-module")

pwm = {}
pwm.__index = pwm

local function assertNumber(n, min, max)
  assert(type(n) == "number")
  assert(n >= min)
  assert(n <= max)
end

local function assertPin(pin)
  assertNumber(pin, 1, 12)
end

--- pwm.setup is stock NodeMCU API
pwm.setup = function(pin, clock, duty)
  assertPin(pin)
  assertNumber(clock, 1, 1000)
  assertNumber(duty, 0, 1024)
  nodemcu.pwm.duties[pin] = {duty = duty, started = false}
  nodemcu.pwm.clock = clock
  table.insert(nodemcu.pwm.history, {event = "setup", pin = pin, clock = clock, duty = duty})
end

--- pwm.start is stock NodeMCU API
pwm.start = function(pin)
  assertPin(pin)
  assert(nodemcu.pwm.duties[pin], "pin not setup yet")
  nodemcu.pwm.duties[pin].started = true
  table.insert(nodemcu.pwm.history, {event = "start", pin = pin})
end

--- pwm.stop is stock NodeMCU API
pwm.stop = function(pin)
  assertPin(pin)
  assert(nodemcu.pwm.duties[pin], "pin not setup yet")
  nodemcu.pwm.duties[pin].started = false
  table.insert(nodemcu.pwm.history, {event = "stop", pin = pin})
end

--- pwm.close is stock NodeMCU API
pwm.close = function(pin)
  assertPin(pin)
  assert(nodemcu.pwm.duties[pin], "pin not setup yet")
  nodemcu.pwm.duties[pin] = nil
  table.insert(nodemcu.pwm.history, {event = "close", pin = pin})
end

--- pwm.setduty is stock NodeMCU API
pwm.setduty = function(pin, duty)
  assertPin(pin)
  assertNumber(duty, 0, 1024)
  assert(nodemcu.pwm.duties[pin], "pin not setup yet")
  nodemcu.pwm.duties[pin].duty = duty
  table.insert(nodemcu.pwm.history, {event = "setduty", pin = pin, duty = duty})
end

--- pwm.setclock is stock NodeMCU API
pwm.setclock = function(pin, clock)
  assertPin(pin)
  assertNumber(clock, 1, 1000)
  nodemcu.pwm.clock = clock
  table.insert(nodemcu.pwm.history, {event = "setclock", pin = pin, clock = clock})
end

--- pwm.getduty is stock NodeMCU API
pwm.getduty = function(pin)
  assertPin(pin)
  assert(nodemcu.pwm.duties[pin], "pin not setup yet")
  return nodemcu.pwm.duties[pin].duty
end

--- pwm.getclock is stock NodeMCU API
pwm.getclock = function(pin)
  assertPin(pin)
  return nodemcu.pwm.clock
end

return pwm
