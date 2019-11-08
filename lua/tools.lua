--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local tools = {}
tools.__index = tools

--- tools.cbReturnRingBuf serves array's items in ring-buffer way
-- @param arr is array of values
-- @return "function(...) item" which when called repeatedly serves next item from the array.
tools.cbReturnRingBuf = function(arr)
    assert(arr, "array is nil")
    local i = 0
    return function(...)
        i = (i < table.getn(arr) and i or 0) + 1
        return arr[i]
    end
end

tools.arrayToFunc = function(arr, recycleArray)
    assert(arr, "array is nil")
    recycleArray = (recycleArray == nil and true or recycleArray)
    local index = 0
    local function nextPayload(timerObj)
        if index >= table.getn(arr) then
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

return tools
