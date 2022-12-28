--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]

---i2c module
---@class i2c
i2c = {}
i2c.__index = i2c

i2c.SLOW = 1
i2c.FAST = 2
i2c.FASTPLUS = 3

---i2c.setup is stock nodemcu API
---@param indx integer
---@param sdaPin integer
---@param sclPin integer
---@param speed number
i2c.setup = function(indx, sdaPin, sclPin, speed)
    -- TODO add implementation
end

return i2c
