--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local contains = require("contains")
local PinState = {
    pin = 0,
    mode = 4, --gpio.OPENDRAIN,
    pullup = 6, -- gpio.FLOAT
    cbGetValue = function()
        return 1 --gpio.HIGH
    end,
    cbOnWrite = function()
    end,
    trigWhat = "none",
    trigCb = function()
    end
}

function PinState:new(pin, o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.pin = pin
    return o
end

PinState.writeEnum = {0, 1}

PinState.createPins = function()
    local arr = {}
    for i = 1, 12 do
        arr[i] = PinState:new(i)
    end
    return arr
end

PinState.assertPinRange = function(pin, pins)
    assert(type(pin) == "number", "pin must be number")
    assert(pin > 0 and pin < 13, "pin must be 0<pin<13")
    assert(pins[pin] ~= nil, "pin does not exists in test data array " .. pin)
    return pins[pin]
end

PinState.changePinValue = function(pinState, val)
    pinState.cbGetValue = function()
        return val
    end
    if
        (val == 1 and contains({"up", "high", "both"}, pinState.trigWhat)) or
            (val == 0 and contains({"down", "low", "both"}, pinState.trigWhat))
     then
        pinState.trigCb(val, os.time())
    end
end

return PinState

