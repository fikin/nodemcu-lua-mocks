--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local contains = require("contains")

---@alias gpio_trig_fn fun(newValue:number, ts: integer)

---Represents a single pin, mocks internal and external interactions via callbacks
---@class gpio_pin_state
local PinState = {
    pin = 0,
    mode = 4, --gpio.OPENDRAIN,
    pullup = 6, -- gpio.FLOAT
    ---@type fun():number
    cbGetValue = function()
        return 1 --gpio.HIGH
    end,
    ---@type fun(pin:integer, value:integer)
    cbOnWrite = function(_)
    end,
    trigWhat = "none",
    ---@type gpio_trig_fn
    trigCb = function()
    end
}

---new pin
---@param pin integer
---@param o? table
---@return gpio_pin_state
function PinState:new(pin, o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.pin = pin
    return o
end

---create array with all valid PinState*
---@return gpio_pin_state[]
PinState.createPins = function()
    local arr = {}
    for i = 1, 12 do
        arr[i] = PinState:new(i)
    end
    return arr
end

---assert pin number is within valid range
---@param pin integer
---@param pins gpio_pin_state[]
---@return gpio_pin_state
PinState.assertPinRange = function(pin, pins)
    assert(type(pin) == "number", "pin must be number")
    assert(pin > 0 and pin < 13, "pin must be 0<pin<13")
    assert(pins[pin] ~= nil, "pin does not exists in test data array " .. pin)
    return pins[pin]
end

---simulate extenal input on the pin
---@param pinState gpio_pin_state
---@param val number to represent external value
PinState.changePinValue = function(pinState, val)
    pinState.cbGetValue = function()
        return val
    end
    if (val == 1 and contains({ "up", "high", "both" }, pinState.trigWhat)) or
        (val == 0 and contains({ "down", "low", "both" }, pinState.trigWhat))
    then
        pinState.trigCb(val, require("tmrNow")())
    end
end

return PinState
