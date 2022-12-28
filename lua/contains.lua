--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]

---helper to test if table field has value like given one
---@param table table
---@param val any
---@return boolean true if value exists, else false
return function(table, val)
    for i = 1, #table do
        if table[i] == val then
            return true
        end
    end
    return false
end
