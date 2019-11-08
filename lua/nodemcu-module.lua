--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local pinState = require("gpio_pin_state")
local contains = require("contains")
local inspect = require("inspect")
local Timer = require("Timer")

-- ######################
-- ######################
-- ######################

--- NodeMCU is class providing simulated/mocked implementation of nodemcu-firmware functionality
local NodeMCU = {}
NodeMCU.__index = NodeMCU

-- ######################
-- ######################
-- ######################

NodeMCU.reset = function()
    Timer.reset()

    --- NodeMCU.adc_read_cb is callback called each time adc is being read
    -- one can re-assign it to custom function
    -- @param channel must be 0
    -- @return 0-1024 range value (by default 1024)
    NodeMCU.adc_read_cb = function()
        return 1024
    end

    --- NodeMCU.dht_on_read_cb is callback called each time adc is being read
    -- one can re-assign it to custom function
    -- @param pin number
    -- @return obj of {status, temp, humi, temp_dec, humi_dec} (by default 1,0,0,0,0)
    NodeMCU.dht_read_cb = function()
        return {1, 0, 0, 0, 0}
    end

    --- NodeMCU.file_opened is storing the last file.open() file
    NodeMCU.file_opened = {
        _fd = nil,
        _in = nil
    }

    --- NodeMCU.gpio_pins is a table pin=PinState
    NodeMCU.gpio_pins = pinState.createPins()

    --- NodeMCU.netTCPListeners is table for net tcp listeners
    NodeMCU.netTCPListeners = {}

    --- NodeMCU.staticTimers contains all static timers defined so far
    NodeMCU.staticTimers = {}

    --- NodeMCU.eus_manual contains End-User-Setup data
    NodeMCU.eus_manual = nil

    --- NodeMCU.eventmonCb constains callbacks assigned via wifi.Eventmon
    NodeMCU.eventmonCb = {}

    --- NodeMCU.wifiAP contains assigned and default wifi.ap data
    NodeMCU.wifiAP = {
        mac = "AA:BB:CC:DD:EE:FF",
        clients = {},
        ip = nil,
        gateway = nil,
        netmask = nil,
        cfg = nil,
        configApFnc = function(cfg)
            return false
        end
    }

    --- NodeMCU.wifiSTA contains assigned and default wifi.sta data
    NodeMCU.wifiSTA = {
        ConnectTimeout = 1,
        autoconnect = false,
        ap_index = 0,
        hostname = nil,
        cfg = nil,
        isConfigOk = false,
        isConnectOk = false,
        bssid = nil,
        channel = 0,
        ip = nil,
        netmask = nil,
        gateway = nil,
        hostname = nil,
        alreadyConnected = false,
        configStaFnc = NodeMCU.wifiSTAdefaultNoConfigStaFnc
    }

    --- NodeMCU.wifi constains assigned to wifi module data
    NodeMCU.wifi = {mode = 0}
end

NodeMCU.reset()

-- ######################
-- ######################
-- ######################

--- NodeMCU.gpio_set sets pin to LOW or HIGH or to callback
-- @param pin
-- @param val is one of : gpio.HIGH, gpio.LOW, callback function(pin)int or function(int,int)void
NodeMCU.gpio_set = function(pin, val)
    local p = pinState.assertPinRange(pin, NodeMCU.gpio_pins)
    if type(val) == "function" then
        p.cbGetValue = val
        p.cbOnWrite = val
    else
        assert(
            contains(pinState.writeEnum, val),
            "expects pin value " .. inspect(pinState.writeEnum) .. " but found " .. val
        )
        pinState.changePinValue(p, val)
    end
end

--- NodeMCU.gpio_capture captures values writen to an output pin
-- @param pin
-- @param val is a callback function(pin,val)void
NodeMCU.gpio_capture = function(pin, val)
    local p = pinState.assertPinRange(pin, NodeMCU.gpio_pins)
    assert(type(val) == "function")
    p.cbOnWrite = val
end

--- NodeMCU.assertPinRange asserts the given pin value is within valid range
-- @param pin
NodeMCU.assertPinRange = function(pin)
    return pinState.assertPinRange(pin, NodeMCU.gpio_pins)
end

--- NodeMCU.wifiAPsetClients assigns clients table connected to AP
-- lst is list of {mac="..",ip="..."} object
NodeMCU.wifiAPsetClients = function(lst)
    NodeMCU.wifiAP.clients = lst
end

--- NodeMCU.wifiAPsetConfigFnc assigns callback used by Ap.config
-- cb is function(cfg) true|false
NodeMCU.wifiAPsetConfigFnc = function(cb)
    NodeMCU.wifiAP.configApFnc = cb
end

--- NodeMCU.wifiSTA defaultConfigStaFnc is simulating connection to some AP
-- @return isConfigOk boolean indicating if cfg is ok
-- following values are meaningful if isConfigOk = true
-- @return isConnectOk boolean indicating that nodemcu can connect to AP (credentials ok)
-- following values are meaningful if isConnectOk = true
-- @return bssid defaults to "AA:BB:CC:DD:EE:FF"
-- @return channel defaults to 11
-- @return ip defaults to "192.168.255.11"
-- @return nestmask defaults to "255.255.255.0"
-- @return gateway defaults to "192.168.255.1"
NodeMCU.wifiSTAdefaultConfigStaFnc = function(cfg)
    return false, true, "AA:BB:CC:DD:EE:FF", 11, "192.168.255.11", "255.255.255.0", "192.168.255.1"
end
NodeMCU.wifiSTAdefaultNoConfigStaFnc = function(cfg)
    return false, false, nil, 0, nil, nil, nil
end

--- wifiSTAsetConfigFnc is callback to simulate wifi connection to an AP
-- cb = function(cfg) isConfigOk, isConnectOk, bssid, channel, ip, netmask, gateway
-- it is called each time Sta.config(cfg) is called to determine what to do with that connection request.
-- see also defaultConfigStaFnc
NodeMCU.wifiSTAsetConfigFnc = function(cb)
    NodeMCU.wifiSTA.configStaFnc = cb
end

--- NodeMCU.advanceTime advances the internal NodeMCU time
-- effect is that all time-based events like timers and triggers will experience time advance.
-- @param ms is milliseconds to advance
NodeMCU.advanceTime = function(ms)
    Timer.joinAll(ms)
end

-- ######################
-- ######################
-- ######################

return NodeMCU
