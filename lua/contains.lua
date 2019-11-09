--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
return function(table, val)
    for i = 1, #table do
        if table[i] == val then
            return true
        end
    end
    return false
end
