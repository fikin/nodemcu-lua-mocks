--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local nodemcu = require("nodemcu-module")
local wifi = require("wifi")
local tmr = require("tmr")
local hasDelayElapsedSince = require("Timer").hasDelayElapsedSince
local fireWifiEvent = nodemcu.fireWifiEvent

---type casting function
---@param v string|integer
---@return integer
local function toInt(v)
    ---@cast v integer
    return v
end

---convert STA_DISCONNECT event reason to status.status
---@param reason integer
---@return integer
local function staFromReasonToStatus(reason)
    if reason == wifi.eventmon.reason.NO_AP_FOUND then
        return wifi.STA_APNOTFOUND
    elseif reason == wifi.eventmon.reason.AUTH_FAIL then
        return wifi.STA_WRONGPWD
    elseif reason == wifi.eventmon.reason.UNSPECIFIED then
        return wifi.STA_IDLE
    end
    return wifi.STA_FAIL
end

---checks that ap/sta.config() is being prepared
---@param mode integer
---@return boolean true if config is ok, else false
local function toSetWifiModeOk(mode)
    if mode == wifi.SOFTAP or mode == wifi.STATIONAP then
        if not (nodemcu.wifiAP.cfg and nodemcu.wifiAP.cfg.ssid) then return false; end
    end
    if mode == wifi.STATION or mode == wifi.STATIONAP then
        if not (nodemcu.wifiSTA.cfg and nodemcu.wifiSTA.cfg.ssid) then return false; end
    end
    return true
end

---special handling for some events
---@param e wifi_internal_event
local function eventSpecificHandling(e)
    if e.eventType == wifi.eventmon.WIFI_MODE_CHANGED then
        local nm = toInt(e.payload.new_mode)
        if toSetWifiModeOk(nm) then
            nodemcu.wifi.mode = nm
        end
    elseif e.eventType == wifi.eventmon.STA_DISCONNECTED then
        -- TODO for future : close associated net sockets
        nodemcu.wifiSTA.status = staFromReasonToStatus(toInt(e.payload.reason))
    elseif e.eventType == nodemcu.wifi.ConnectingEvent then
        nodemcu.wifiSTA.status = wifi.STA_CONNECTING
        -- reset timeout timer
        nodemcu.wifiSTA.connectionStartTs = tmr.now()
    elseif e.eventType == wifi.eventmon.STA_CONNECTED then
        -- reset timeout timer
        nodemcu.wifiSTA.connectionStartTs = tmr.now()
    elseif e.eventType == wifi.eventmon.STA_GOT_IP then
        nodemcu.wifiSTA.assignedIp = e.payload
        nodemcu.wifiSTA.status = wifi.STA_GOTIP
    end
end

local function handleStaAutoConnectLogic()
    if not (nodemcu.wifi.mode == wifi.STATION or nodemcu.wifi.mode == wifi.STATIONAP) then return; end
    local cfg = nodemcu.wifiSTA
    if cfg == nil then return; end -- sta.cfg not set yet
    if cfg.status == wifi.STA_CONNECTING then
        local ap = cfg.AccessPoint
        if ap then
            -- try to establish connection against defined by test case access point
            if ap.ssid ~= cfg.cfg.ssid then
                fireWifiEvent(wifi.eventmon.STA_DISCONNECTED, { reason = wifi.eventmon.reason.NO_AP_FOUND })
            elseif ap.pwd ~= cfg.cfg.pwd then
                fireWifiEvent(wifi.eventmon.STA_DISCONNECTED, { reason = wifi.eventmon.reason.AUTH_FAIL })
            else
                fireWifiEvent(wifi.eventmon.STA_CONNECTED, ap)
                local ip = cfg.staticIp or ap.dhcp
                if ip then
                    fireWifiEvent(wifi.eventmon.STA_GOT_IP, ip)
                -- else
                    --- wait for test case to send got-ip event or for timeout to fail with dhcp-timeout
                end
            end
        else
            -- disconnect after some timeout, meantime test case could either set AccessPoint
            -- or fire STA_DISCONNECTED event with appropriate reason.
            local f = hasDelayElapsedSince(tmr.now(), cfg.connectionStartTs, cfg.connectingTimeout)
            if f then
                if ap then
                    -- if AccessPoint is defined, timeout happens after connected
                    -- but not having staticIp or AccessPoint.dhcp.
                    -- test cases must recover this by sending got-ip or disconnect event.
                    fireWifiEvent(wifi.eventmon.STA_DHCP_TIMEOUT, {})
                else
                    fireWifiEvent(wifi.eventmon.STA_DISCONNECTED, { reason = wifi.eventmon.reason.NO_AP_FOUND })
                end
            end
        end
    elseif cfg.status ~= wifi.STA_GOTIP and cfg.cfg.auto then
        -- auto connect if not connected already or in process of connecting
        fireWifiEvent(nodemcu.wifi.ConnectingEvent, {})
    end
end

---Control loop dispatching all queued Wifi events.
---@param _ tmr_instance
local function controlLoop(_)
    local fifo = nodemcu.wifi.eventsQueue
    while fifo:hasMore() do
        ---@type wifi_internal_event
        local e = fifo:pop()
        eventSpecificHandling(e)
        -- fire callbacks associated with the actual event
        wifi.eventmon.fire(e.eventType, e.payload)
    end
    handleStaAutoConnectLogic()
end

nodemcu.add_reset_fn("wifi-control", function()
    --start event loop for wifi
    assert(tmr.create():alarm(1, tmr.ALARM_AUTO, controlLoop))
end)

return wifi
