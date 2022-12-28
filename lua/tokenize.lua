--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]

---splits data into chunkSize and returns the array
---@param chunkSize integer
---@param data string
---@return string[]
local function tokenize(chunkSize, data)
    assert(type(chunkSize) == "number")
    assert(type(data) == "string")
    local arr = {}
    while true do
        local head, tail =
        string.len(data) <= chunkSize and data or string.sub(data, 1, chunkSize),
            string.len(data) > chunkSize and string.sub(data, chunkSize + 1) or nil
        if not head then
            break
        end
        table.insert(arr, head)
        if not tail then
            break
        end
        data = tail
    end
    return arr
end

return tokenize
