--[[
License : GPLv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local nodemcu = require("nodemcu-module")

---@class rotary_rec
---@field pina integer
---@field pinb integer
---@field pinpress integer
---@field longpress_time_ms integer
---@field dblclick_time_ms integer
---@field callbacks fun(event:integer,pos:integer,ts:integer)
---@field pos integer

---@class rotary
rotary = {}
rotary.__index = rotary

rotary.PRESS = 1     -- The eventtype for the switch press.
rotary.LONGPRESS = 2 -- The eventtype for a long press.
rotary.RELEASE = 4   -- The eventtype for the switch release.
rotary.TURN = 8      -- The eventtype for the switch rotation.
rotary.CLICK = 16    -- The eventtype for a single click (after release)
rotary.DBLCLICK = 32 -- The eventtype for a double click (after second release)
rotary.ALL = 63      -- All event types.

---Emulates rotary switch turn with delta steps.
---It recalculates the new position and fires set callbacks.
---@param channel integer
---@param deltaSteps integer
nodemcu.rotary_turn = function(channel, deltaSteps)
  assert(type(channel) == "number", "channel must be number")
  assert(type(deltaSteps) == "number", "deltaSteps must be number")
  ch = nodemcu.rotary[channel + 1]
  assert(ch, "channel not setup yet")
  ch.pos = ch.pos + deltaSteps
  for _, v in pairs({ rotary.TURN, rotary.ALL }) do
    cb = ch.callbacks[v]
    if cb then
      cb(v, ch.pos, os.time())
    end
  end
end

---Emulates rotary switch press event.
---It fires set callbacks.
---@param channel integer
---@param eventType integer
nodemcu.rotary_press = function(channel, eventType)
  assert(type(channel) == "number", "channel must be number")
  assert(type(eventType) == "number", "eventType must be number")
  ch = nodemcu.rotary[channel + 1]
  assert(ch, "channel not setup yet")
  for _, v in pairs({ eventType, rotary.ALL }) do
    cb = ch.callbacks[v]
    if cb then
      cb(v, ch.pos, os.time())
    end
  end
end


--- rotary.setup is stock nodemcu API
---@param channel integer
---@param pina integer
---@param pinb integer
---@param pinpress integer
---@param longpress_time_ms integer
---@param dblclick_time_ms integer
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
---@param channel integer
---@param eventtype integer
---@param callback fun()
rotary.on = function(channel, eventtype, callback)
  assert(type(channel) == "number", "channel must be number")
  assert(type(eventtype) == "number", "eventType must be number")
  if callback then
    assert(type(callback) == "function")
  end
  nodemcu.rotary[channel + 1].callbacks[eventtype] = callback
end

---rotary.getpos is stock nodemcu API
---@param channel integer
rotary.getpos = function(channel)
  assert(type(channel) == "number", "channel must be number")
  return nodemcu.rotary[channel + 1].pos
end

--- rotary.close is stock nodemcu API
---@param channel integer
rotary.close = function(channel)
  assert(type(channel) == "number", "channel must be number")
  nodemcu.rotary[channel + 1] = nil
end

return rotary
