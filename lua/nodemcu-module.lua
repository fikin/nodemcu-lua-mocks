--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local Timer = require("Timer")
local pinState = require("gpio_pin_state")
local socket = require("net-tcp-socket")

---NodeMCU is class providing simulated/mocked implementation of nodemcu-firmware functionality
---@class NodeMCU
local NodeMCU = {
    ---contains all reset functions provided by modules
    ---@private
    _reset_fn = {},
}
NodeMCU.__index = NodeMCU

---called by modules upon initial load to register their test-case reset logic.
---@param moduleName string
---@param fn fun()
NodeMCU.add_reset_fn = function(moduleName, fn)
    NodeMCU._reset_fn[moduleName] = fn
end

---called before each test case to reset state of NodeMcu itself.
NodeMCU.reset = function()
    Timer.reset()
    for _, v in pairs(NodeMCU._reset_fn) do
        v()
    end
end

---NodeMCU.advanceTime advances the internal NodeMCU time.
---Effect is that all time-based events like timers and triggers will experience time advance.
---@param ms integer is milliseconds to advance
NodeMCU.advanceTime = function(ms)
    Timer.joinAll(ms)
end

--=======================
--=======================

---Register nodemcu state reset for the module.
---Overwrite in the test case if needed.
NodeMCU.add_reset_fn("adc", function()
    ---called each time someone uses adc module.
    ---overwrite on the test cases if required.
    ---@return integer
    NodeMCU.adc_read_cb = function() return 1024; end
end)

---register nodemcu state reset for the module
---overwrite in the test case if needed.
NodeMCU.add_reset_fn("dht", function()
    ---called each time someone is using dht module.
    ---overwrite in test cases if needed.
    ---@param pin integer
    ---@return integer[]
    NodeMCU.dht_read_cb = function(pin) return { 1, 0, 0, 0, 0 } end
end)

---register nodemcu state reset for the module
NodeMCU.add_reset_fn("file-nodemcu", function()
    NodeMCU.t_file_workDir = os.getenv("NODEMCU_MOCKS_SPIFFS_DIR")
end)

---register nodemcu state reset for the module
NodeMCU.add_reset_fn("gpio", function()
    NodeMCU.gpio_pins = require("gpio_pin_state").createPins()
end)

---register nodemcu state reset for the module
---overwrite in the test case if needed.
NodeMCU.add_reset_fn("net", function()
    ---@type tcpServer
    NodeMCU.net_tcp_srv = nil
end)

---register nodemcu state reset for the module
---overwrite in the test case if needed.
NodeMCU.add_reset_fn("pwm", function()
    NodeMCU.pwm = {
        history = {},
        duties = {},
        clock = nil
    }
end)

---register nodemcu state reset for the module
---overwrite in the test case if needed.
NodeMCU.add_reset_fn("rotary", function()
    ---@type rotary_rec[]
    NodeMCU.rotary = {}
end)

---register nodemcu state reset for the module
---overwrite in the test case if needed.
NodeMCU.add_reset_fn("rtcmem", function()
    ---@type integer[]
    NodeMCU.rtcmem = {}
end)

---register nodemcu state reset for the module
---overwrite in the test case if needed.
NodeMCU.add_reset_fn("tmr", function()
    NodeMCU.staticTimers = {}
end)

---register nodemcu state reset for the module
---overwrite in the test case if needed.
NodeMCU.add_reset_fn("wifi", function()
    NodeMCU.wifi = {
        mode = wifi.NULLMODE
    }
end)

---register nodemcu state reset for the module
---overwrite in the test case if needed.
NodeMCU.add_reset_fn("wifi-sta", function()
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
        alreadyConnected = false,
        accessPoints = {},
        configStaFnc = NodeMCU.wifiSTAdefaultNoConfigStaFnc
    }
end)

---register nodemcu state reset for the module
---overwrite in the test case if needed.
NodeMCU.add_reset_fn("wifi-eventmon", function()
    ---@type wifi_eventmon_fn[]
    NodeMCU.eventmonCb = {}
end)

---register nodemcu state reset for the module
---overwrite in the test case if needed.
NodeMCU.add_reset_fn("wifi-ap", function()
    NodeMCU.wifiAP = {
        mac = "AA:BB:CC:DD:EE:FF",
        clients = {},
        ip = nil,
        gateway = nil,
        netmask = nil,
        ---@type wifi_ap_config_config
        cfg = nil,
        configApFnc = function(cfg)
            return false
        end
    }
end)

--=======================
--=======================

---asserts the given pin value is within valid range
---@param pin integer
---@return gpio_pin_state
NodeMCU.getDefinedPin = function(pin)
    return pinState.assertPinRange(pin, NodeMCU.gpio_pins)
end

---returns the mode assigned to the given pin
---@param pin integer
---@return integer
NodeMCU.gpio_get_mode = function(pin)
    return NodeMCU.getDefinedPin(pin).mode
end

---sets pin to LOW or HIGH or to callback
---@param pin integer
---@param val integer|fun(pin:integer,val?:integer) one of : gpio.HIGH, gpio.LOW, callback function(pin)int or function(int,int)void
NodeMCU.gpio_set = function(pin, val)
    local p = NodeMCU.getDefinedPin(pin)
    if type(val) == "function" then
        p.cbGetValue = val
        p.cbOnWrite = val
    else
        pinState.changePinValue(p, val)
    end
end

---captures values writen to an output pin
---@param pin any
---@param val fun(pin:integer,val:integer)
NodeMCU.gpio_capture = function(pin, val)
    local p = NodeMCU.getDefinedPin(pin)
    assert(type(val) == "function")
    p.cbOnWrite = val
end

---called by unit tests to simulate remote client connecting to some listener
---@param listenerPort integer
---@param remoteIp string
---@return socket
NodeMCU.net_tpc_connect_to_listener = function(listenerPort, remoteIp)
    local cb = NodeMCU.net_tcp_srv._listeners[tostring(listenerPort)]
    assert(cb, string.format("no listener on port %s found", listenerPort))
    local skt = socket.new(NodeMCU.net_tcp_srv._timeout * 1000)
    skt:connect(math.random(22000, 22999), remoteIp)
    cb(skt)
    skt:remoteAcceptConnection()
    return skt
end

---Returns pwm-module generated events since last time this method was called.
---@return table of gathered pwm events since last call to that method
NodeMCU.pwm_get_history = function()
    local ret = NodeMCU.pwm.history
    NodeMCU.pwm.history = {}
    return ret
end

--- NodeMCU.net_ip_get returns IP address assigned to nodemcu
---@return string sta.ip or ap.ip or "0.0.0.0" if not connected
NodeMCU.net_ip_get = function()
    if NodeMCU.wifi.mode == wifi.NULLMODE then
        return "0.0.0.0"
    elseif NodeMCU.wifi.mode == wifi.STATION or NodeMCU.wifi.mode == wifi.STATIONAP then
        return NodeMCU.wifiSTA.ip
    else
        return NodeMCU.wifiAP.ip
    end
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

--- NodeMCU.wifiAPsetClients assigns clients table connected to AP
---lst is list of {mac="..",ip="..."} object
---@param lst any
NodeMCU.wifiAPsetClients = function(lst)
    NodeMCU.wifiAP.clients = lst
end

--- NodeMCU.wifiAPsetConfigFnc assigns callback used by Ap.config
---cb is function(cfg) true|false
NodeMCU.wifiAPsetConfigFnc = function(cb)
    NodeMCU.wifiAP.configApFnc = cb
end

--=======================
--=======================

return NodeMCU
