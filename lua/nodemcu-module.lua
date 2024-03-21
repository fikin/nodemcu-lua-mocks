--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local Timer = require("Timer")
local pinState = require("gpio_pin_state")
local socket = require("net-tcp-socket")
local fifoArr = require("fifo-arr")

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

NodeMCU.add_reset_fn("adc", function()
    ---called each time someone uses adc module.
    ---overwrite on the test cases if required.
    ---@return integer
    NodeMCU.adc_read_cb = function() return 1024; end
end)

NodeMCU.add_reset_fn("dht", function()
    ---called each time someone is using dht module.
    ---overwrite in test cases if needed.
    ---@param _ integer pin
    ---@return integer[]
    NodeMCU.dht_read_cb = function(_) return { 1, 0, 0, 0, 0 } end
end)

NodeMCU.add_reset_fn("file-nodemcu", function()
    NodeMCU.t_file_workDir = os.getenv("NODEMCU_MOCKS_SPIFFS_DIR")
    assert(NodeMCU.t_file_workDir, "env.NODEMCU_MOCKS_SPIFFS_DIR is not defined")
end)

NodeMCU.add_reset_fn("gpio", function()
    NodeMCU.gpio_pins = require("gpio_pin_state").createPins()
end)

NodeMCU.add_reset_fn("net", function()
    ---@type {[integer]:tcpServer}
    NodeMCU.net_tcp_srv = {}
end)

NodeMCU.add_reset_fn("pwm", function()
    NodeMCU.pwm = {
        history = {},
        duties = {},
        clock = nil
    }
end)

NodeMCU.add_reset_fn("rotary", function()
    ---@type rotary_rec[]
    NodeMCU.rotary = {}
end)

NodeMCU.add_reset_fn("rtcmem", function()
    ---@type integer[]
    NodeMCU.rtcmem = {}
    for i = 0, 255 do
        NodeMCU.rtcmem[i] = math.random(0, 255)
    end
end)

---data object used by nodemcu.fireWifiEvent.
---do not use directly!
---@class wifi_internal_event
---@field eventType integer
---@field payload {[string]:string|integer}

NodeMCU.add_reset_fn("wifi", function()
    NodeMCU.wifi = {
        ---@type wifi_country
        country = nil,
        phymode = wifi.PHYMODE_B,
        maxpower = 128,
        mode = wifi.NULLMODE,
        ---this is internal eventsQueue event type
        ConnectingEvent = 101,
        eventsQueue = fifoArr.new(),
    }
end)

---definition of an Access Point to which wifi.sta would "connect" to.
---@class wifi_internal_sta_ap
---@field ssid string
---if left nil it leads to disconnected-wrong-pwd event.
---@field pwd string
---@field bssid string
---@field channel integer
---by default one must define the IP wifi.sta would get assigned.
---if left nil, it signifies that test case will send got-ip event
---on its own or dhcp-timeout event will trigger (connectingTimeout).
---@field dhcp? wifi_ip

NodeMCU.add_reset_fn("wifi-sta", function()
    NodeMCU.wifiSTA = {
        ---@type wifi_sta_config
        cfg = nil,
        ---@type string
        hostname = nil,
        mac = "AA:BB:CC:DD",
        ---@type wifi_ip
        staticIp = nil,
        sleepType = 0,
        status = wifi.STA_IDLE,
        ---field assigned once connect() starts.
        ---it is used internally to track wifi connection timeout.
        connectionStartTs = 0,
        ---timeout to auto-fail sta.connecting if AccessPoint or AccessPoint.dhcp are not defined meantime.
        connectingTimeout = 2,
        ---when has got ip, it is assigned either to AccessPoint.dhcp or staticIp
        ---@type wifi_ip
        assignedIp = nil,
        ---backs wifi.sta.getapindex/changeap
        ap_index = 1,
        ---test cases assign this setting to simulate AP to which wifi.sta will connect to.
        ---if left nil, it indicates that test case will send (dis)connected event on its own.
        ---of wifi control loop will send disconnected/ap-not-found after connectingTimeout.
        ---@type wifi_internal_sta_ap
        AccessPoint = nil,
        ---backs wifi.sta.getap(), test cases can assign any function they want.
        ---@param cfg? {[string]:string}
        ---@param format? integer
        ---@param cb fun(tbl:{[string]:string})
        GetAP = function(cfg, format, cb)
            assert(cfg ~= nil)
            assert(format ~= nil)
            assert(type(cb) == "function")
        end,
    }
end)

NodeMCU.add_reset_fn("wifi-eventmon", function()
    ---@type wifi_eventmon_fn[]
    NodeMCU.wifiEventmonTbl = {}
end)

NodeMCU.add_reset_fn("wifi-ap", function()
    NodeMCU.wifiAP = {
        ---@type wifi_ap_config
        cfg = nil,
        ---@type string
        hostname = nil,
        ---@type wifi_ip
        staticIp = nil,
        ---@type table
        dhcpConfig = {},
        mac = "AA:BB:CC:DD:EE:FF",
        ---@type wifi_ap_clients
        clients = {},
    }
end)

NodeMCU.add_reset_fn("rtctime", function()
    ---@type rtctime_ts
    NodeMCU.rtctime = {
        sec = 0,
        usec = 0,
        rate = 0
    }
end)

NodeMCU.add_reset_fn("wifi-eventmon", function()
    ---@type wifi_eventmon_fn[]
    NodeMCU.wifiEventmonTbl = {}
end)

NodeMCU.add_reset_fn("node", function()
    ---overwrite in the test case if some other values are needed
    NodeMCU.node = {
        ---@type node_parttable
        parttable = {
            lfs_addr = 0x1000,
            lfs_size = 0x2000,
            spiffs_addr = 0x10000,
            spiffs_size = 0x2000
        },
        bootreason = {
            rawcode = 0,
            reason = 0
        },
        chipid = 1234567890,
        restartRequested = false,
        outputPipe = require("tools").new_pipe(),
        outputFn = false,
        outputToSerial = true,
        inputStr = "",
        cpufreq = 80,
    }
end)

NodeMCU.add_reset_fn("ow", function()
    NodeMCU.ow = {
        ---@type integer
        pin = nil,
        ---value of select(rom)
        ---@type ow_rom
        selected_rom = nil,
        ---ROM code returned by search() function.
        ---test cases can assign value they expect here.
        ---@type ow_rom
        Rom = nil,
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
---@param val integer|fun(pin:integer,val?:integer) one of : gpio.HIGH, gpio.LOW,
--             callback function(pin)int or function(int,int)void
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
    local srv = NodeMCU.net_tcp_srv[listenerPort]
    assert(srv, string.format("no listener on port %s found", listenerPort))
    local skt = socket.new(srv._timeout * 1000)
    skt:connect(math.random(22000, 22999), remoteIp)
    srv._listener(skt)
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

---Dispatch Wifi event to control loop.
---@param eventType integer
---@param payload {[string]:any}
NodeMCU.fireWifiEvent = function(eventType, payload)
    NodeMCU.wifi.eventsQueue:push({ eventType = eventType, payload = payload })
end

---NodeMCU.wifiAPsetClients assigns clients table connected to AP
---lst is list of {mac="..",ip="..."} object
---@param lst {[string]:string}
NodeMCU.wifiAPsetClients = function(lst)
    NodeMCU.wifiAP.clients = lst
end

--=======================
--=======================

return NodeMCU
