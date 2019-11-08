--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local nodemcu = require("nodemcu-module")

enduser_setup = {}
enduser_setup.__index = enduser_setup

--- enduser_setup.manual is stock nodemcu API
enduser_setup.manual = function(on_off)
  nodemcu.eus_manual = on_off
end

--- enduser_setup.start is stock nodemcu API
-- @param onConnected()
-- @param onError(err_num, string)
-- @param onDebug(string)
enduser_setup.start = function(onConnected, onError, onDebug)
end

--- enduser_setup.stop is stock nodemcu API
enduser_setup.stop = function()
end

return enduser_setup
