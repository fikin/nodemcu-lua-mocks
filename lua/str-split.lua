--[[
    https://stackoverflow.com/questions/1426954/split-string-in-lua
]]

---split string
---@param str string
---@param sep string
---@return string[]
function str_split(str, sep)
    if sep == nil then
        sep = '%s'
    end

    local res = {}
    local func = function(w)
        table.insert(res, w)
    end

    local _, _ = string.gsub(str, '[^' .. sep .. ']+', func)
    return res
end

return str_split
