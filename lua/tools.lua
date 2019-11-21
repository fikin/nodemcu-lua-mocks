--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local tools = {}
tools.__index = tools

local function size(arr)
    return (table.getn and table.getn(arr)) or #arr
end

--- tools.cbReturnRingBuf serves array's items in ring-buffer way
-- @param arr is array of values
-- @return "function(...) item" which when called repeatedly serves next item from the array.
tools.cbReturnRingBuf = function(arr)
    assert(arr, "array is nil")
    local i = 0
    return function(...)
        i = (i < size(arr) and i or 0) + 1
        return arr[i]
    end
end

tools.arrayToFunc = function(arr, recycleArray)
    assert(arr, "array is nil")
    recycleArray = (recycleArray == nil and true or recycleArray)
    local index = 0
    local function nextPayload(timerObj)
        if index >= size(arr) then
            if recycleArray then
                index = 0
            else
                return nil
            end
        end
        index = index + 1
        return arr[index]
    end
    return nextPayload
end

tools.collectDataToArray = function()
    local o = {
        data = {}
    }
    o.putCb = function(...)
        table.insert(o.data, {...})
    end
    o.get = function()
        return o.data
    end
    return o
end

tools.wrapConnection = function(con, cb)
    local uniformCallbacks = function(cb)
        local function emptyFnc()
        end
        cb = cb or {}
        cb.sent = cb.sent or emptyFnc
        cb.receive = cb.receive or emptyFnc
        cb.disconnection = cb.disconnection or emptyFnc
        cb.connection = cb.connection or emptyFnc
        cb.reconnection = cb.reconnection or emptyFnc
        return cb
    end

    cb = uniformCallbacks(cb)
    local w = {
        sent = 0,
        received = {},
        connection = 0,
        disconnection = 0,
        reconnection = 0
    }
    con:on(
        "sent",
        function(con2)
            w.sent = w.sent + 1
            cb.sent(con2)
        end
    )
    con:on(
        "receive",
        function(con2, data)
            table.insert(w.received, data)
            cb.receive(con2, data)
        end
    )
    con:on(
        "disconnection",
        function(con2)
            w.disconnection = w.disconnection + 1
            cb.disconnection(con2, data)
        end
    )
    con:on(
        "connection",
        function(con2)
            w.connection = w.connection + 1
            cb.connection(con2, data)
        end
    )
    con:on(
        "reconnection",
        function(con2)
            w.reconnection = w.reconnection + 1
            cb.reconnection(con2, data)
        end
    )
    return w
end

return tools
