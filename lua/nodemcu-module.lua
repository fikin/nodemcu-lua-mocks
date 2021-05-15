--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local pinState = require("gpio_pin_state")
local contains = require("contains")
local inspect = require("inspect")
local Timer = require("Timer")
local wifi = require("wifi-constants")

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
        accessPoints = {},
        configStaFnc = NodeMCU.wifiSTAdefaultNoConfigStaFnc
    }

    --- NodeMCU.wifi constains assigned to wifi module data
    NodeMCU.wifi = {
        mode = wifi.NULLMODE
    }

    -- NodeMCU.netTcpRemoteListeners contains all remote listeners defined by test cases
    NodeMCU.netTcpRemoteListeners = {}

    --- NodeMCU.net_tcp_idleiotimeout is the idle timeout in ms before connection is autoclosed
    NodeMCU.net_tcp_idleiotimeout = 30000 -- 30sec

    --- NodeMCU.net_tcp_framesize is the TCP stack frame size
    NodeMCU.net_tcp_framesize = 450

    --- NodeMCU.pwm contains pwm-module data
    NodeMCU.pwm = {history = {}, duties = {}, clock = nil}

    --- NodeMCU.rotary contains rotary-module data
    NodeMCU.rotary = {}
end

NodeMCU.reset()

-- ######################
-- ######################
-- ######################

--- NodeMCU.gpio_get_mode returns the mode assigned to the given pin
-- @param pin
NodeMCU.gpio_get_mode = function(pin)
    local p = pinState.assertPinRange(pin, NodeMCU.gpio_pins)
    return p.mode
end

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
-- @return mac defaults to "AA:BB:CC:DD:EE:FF"
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

--- NodeMCU.wifiSTAsetAP assigns access points list to be returned by Sta.getap()
-- @param tbl is table in the format of key=bssid and value="ssid, rssi, authmode, channel"
NodeMCU.wifiSTAsetAP = function(tbl)
    NodeMCU.wifiSTA.accessPoints = tbl
end

--- NodeMCU.net_tcp_listener_new creates a new TCP server and registers with global listeners table
-- This method is convenience on top of net.createServer and NodeMCU.net_tcp_listener_add
-- @param remotePort to which the listener responds to
-- @param remoteHost to which the listener responds to
-- @param listenerCb is stock NodeMCU net.server.listen function(net.socket)(void) listener callback
-- @param timeoutSec is idle io timeout
NodeMCU.net_tcp_listener_new = function(remotePort, remoteHost, listenerCb, timeoutSec)
    assert(type(remotePort) == "number", "remotePort must be number")
    assert(type(remoteHost) == "string", "remoteHost must be string")
    assert(type(listenerCb) == "function")
    timeoutSec = timeoutSec or 30
    local srv = net.createServer(net.TCP, timeoutSec)
    srv:listen(remotePort, remoteHost, listenerCb)
    NodeMCU.net_tcp_listener_add(srv)
end

--- NodeMCU.net_tcp_listener_add registes a net.tcp server responding to given port and host in global table of listeners
-- @param tcpServer is NetTCPServer
NodeMCU.net_tcp_listener_add = function(tcpServer)
    assert(tcpServer)
    assert(type(tcpServer._port) == "number")
    assert(type(tcpServer._ip) == "string")
    assert(type(tcpServer._cb) == "function")
    local key = tostring(tcpServer._port) .. "-" .. tcpServer._ip
    NodeMCU.netTcpRemoteListeners[key] = tcpServer
end

--- NodeMCU.net_tcp_listener_remove removes a net.tcp server from global table of listeners
-- @param tcpServer is listening to
NodeMCU.net_tcp_listener_remove = function(tcpServer)
    assert(tcpServer)
    assert(type(tcpServer._port) == "number")
    assert(type(tcpServer._ip) == "string")
    local key = tostring(tcpServer._port) .. "-" .. tcpServer._ip
    NodeMCU.netTcpRemoteListeners[key] = nil
end

--- NodeMCU.net_tcp_listener_get returns a net.tcp server from global table of listeners if defined.
-- @param remotePort to which the listener responds to
-- @param remoteHost to which the listener responds to
-- @return NetTCPServer object or nil if no such bound to given port and host
NodeMCU.net_tcp_listener_get = function(remotePort, remoteHost)
    assert(type(remotePort) == "number", "remotePort must be number")
    assert(type(remoteHost) == "string", "remoteHost must be string")
    local key = tostring(remotePort) .. "-" .. remoteHost
    return NodeMCU.netTcpRemoteListeners[key]
end

--- NodeMCU.net_ip_get returns IP address assigned to nodemcu
-- @return sta.ip or ap.ip or "0.0.0.0" if not connected
NodeMCU.net_ip_get = function()
    if NodeMCU.wifi.mode == wifi.NULLMODE then
        return "0.0.0.0"
    elseif NodeMCU.wifi.mode == wifi.STATION or NodeMCU.wifi.mode == wifi.STATIONAP then
        return NodeMCU.wifiSTA.ip
    else
        return NodeMCU.wifiAP.ip
    end
end

--- NodeMCU.pwm_get_history is returning pwm-module generated events since last time this method was called
-- @return list of gathered pwm events since last call to that method
NodeMCU.pwm_get_history = function()
    local ret = NodeMCU.pwm.history
    NodeMCU.pwm.history = {}
    return ret
end

--- NodeMCU.rotary_turn is emulating rotary switch turn with delta steps.
-- it recalculates the new position and fires set callbacks.
NodeMCU.rotary_turn = function(channel, deltaSteps)
    assert(type(channel) == "number", "channel must be number")
    assert(type(deltaSteps) == "number", "deltaSteps must be number")
    NodeMCU.rotary[channel + 1].pos = NodeMCU.rotary[channel + 1].pos + deltaSteps
    for k, v in pairs({8, 63}) do
        c = NodeMCU.rotary[channel + 1].callbacks[v]
        if c then
            c(v, NodeMCU.rotary[channel + 1].pos, os.time())
        end
    end
end

--- NodeMCU.rotary_press is emulating rotary switch press event.
-- it fires set callbacks.
NodeMCU.rotary_press = function(channel, eventType)
    assert(type(channel) == "number", "channel must be number")
    assert(type(eventType) == "number", "eventType must be number")
    for k, v in pairs({eventType, 63}) do
        c = NodeMCU.rotary[channel + 1].callbacks[v]
        if c then
            c(v, NodeMCU.rotary[channel + 1].pos, os.time())
        end
    end
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
