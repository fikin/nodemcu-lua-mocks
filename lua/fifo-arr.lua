--[[
License : GPLv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]

---FIFO array with marker for read data
---keeps all data in, only marker advances
---indicating it is being read
---@class fifoArr
local fifoArr = {
    ---@type any[]
    _data = {},
    _mark = 0
}
fifoArr.__index = fifoArr

---instantiate new FIFO array instance
---@return fifoArr
fifoArr.new = function()
    return setmetatable({ _data = {} }, fifoArr)
end

---push a value to the end of the stack
---@param self fifoArr
---@param data any
fifoArr.push = function(self, data)
    table.insert(self._data, data)
end

---pop first element in the stack
---@param self fifoArr
---@return any
fifoArr.pop = function(self)
    if self.hasMore(self) then
        self._mark = self._mark + 1
        return self._data[self._mark]
    end
    return nil
end

---test if there are any elements in the stack
---@param self fifoArr
---@return boolean
fifoArr.hasMore = function(self)
    return self._mark < #self._data
end

---get all elements in the stack
---@param self fifoArr
---@return any[]
fifoArr.getAll = function(self)
    return self._data
end

return fifoArr
