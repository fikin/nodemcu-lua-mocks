--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local nodemcu = require("nodemcu-module")
rotary = {}
rotary.__index = rotary

rotary.PRESS = 1 -- The eventtype for the switch press.
rotary.LONGPRESS = 2 -- The eventtype for a long press.
rotary.RELEASE = 4 -- The eventtype for the switch release.
rotary.TURN = 8 -- The eventtype for the switch rotation.
rotary.CLICK = 16 -- The eventtype for a single click (after release)
rotary.DBLCLICK = 32 -- The eventtype for a double click (after second release)
rotary.ALL = 63 -- All event types.

--- rotary.setup is stock nodemcu API
rotary.setup = function(channel, pina, pinb, pinpress, longpress_time_ms, dblclick_time_ms)
  assert(type(channel) == "number", "channel must be number")
  nodemcu.rotary[channel + 1] = {
    pina = pina,
    pinb = pinb,
    pinpress = pinpress,
    longpress_time_ms = longpress_time_ms,
    dblclick_time_ms = dblclick_time_ms,
    callbacks = {},
    pos = 0
  }
end

--- rotary.on is stock nodemcu API
rotary.on = function(channel, eventtype, callback)
  assert(type(channel) == "number", "channel must be number")
  assert(type(eventtype) == "number", "eventType must be number")
  if callback then
    assert(type(callback) == "function")
  end
  nodemcu.rotary[channel + 1].callbacks[eventtype] = callback
end

--- rotary.getpos is stock nodemcu API
rotary.getpos = function(channel)
  assert(type(channel) == "number", "channel must be number")
  return nodemcu.rotary[channel + 1].pos
end

--- rotary.close is stock nodemcu API
rotary.close = function(channel)
  assert(type(channel) == "number", "channel must be number")
  nodemcu.rotary[channel + 1] = nil
end

return rotary
