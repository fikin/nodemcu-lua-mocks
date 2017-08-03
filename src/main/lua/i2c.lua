--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]

i2c = {}
i2c.__index = i2c

i2c.SLOW = 1

i2c.setup = function(indx, sdaPin, sclPin, connectionType)
end

return i2c