--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]

local tools = {}
tools.__index = tools

---size of the array
---@param arr any[]
---@return integer
local function size(arr)
    return #arr
end

--- tools.cbReturnRingBuf serves array's items in ring-buffer way
---@param arr any[] is data to iterate over
---@return fun():any next item in the data list, starts from beginning if it reaches end
tools.cbReturnRingBuf = function(arr)
    assert(arr, "array is nil")
    local i = 0
    return function()
        i = (i < size(arr) and i or 0) + 1
        return arr[i]
    end
end

---iterate over array items. starts from beginning if recycleArray is true.
---@param arr any[]
---@param recycleArray boolean
---@return fun():any is next item from the array
tools.arrayToFunc = function(arr, recycleArray)
    assert(arr, "array is nil")
    recycleArray = (recycleArray == nil and true or recycleArray)
    local index = 0
    return function()
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
end

---returns function which collects data into internal array
---each call to get() will empty the internal array.
---@return tools_collected_data
tools.collectDataToArray = function()
    ---@class tools_collected_data
    ---@field private data any[]
    local o = {
        data = {}
    }
    ---add item to the array
    ---@param ... unknown
    o.put = function(...)
        table.insert(o.data, { ... })
    end
    ---get all items in the array
    ---@return any[]
    o.get = function()
        local ret = o.data
        o.data = {}
        return ret
    end
    return o
end

local function emptyFnc() end

---@class net_socket_wrapper
---@field sent socket
---@field receive socket
---@field disconnection socket
---@field connection socket
---@field reconnection socket

---new socket wrapper
---@param cb net_socket_wrapper?
---@return net_socket_wrapper
local function uniformCallbacks(cb)
    cb = cb or {}
    cb.sent = cb.sent or emptyFnc
    cb.receive = cb.receive or emptyFnc
    cb.disconnection = cb.disconnection or emptyFnc
    cb.connection = cb.connection or emptyFnc
    cb.reconnection = cb.reconnection or emptyFnc
    return cb
end

---TODO
---@param con socket
---@param cb? net_socket_wrapper
---@return table
tools.wrapConnection = function(con, cb)
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
        function(con2, errMsg)
            w.disconnection = w.disconnection + 1
            cb.disconnection(con2, errMsg)
        end
    )
    con:on(
        "connection",
        function(con2)
            w.connection = w.connection + 1
            cb.connection(con2)
        end
    )
    con:on(
        "reconnection",
        function(con2, errMsg)
            w.reconnection = w.reconnection + 1
            cb.reconnection(con2, errMsg)
        end
    )
    return w
end

return tools
