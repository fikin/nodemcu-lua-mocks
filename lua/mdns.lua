--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local nodemcu = require("nodemcu-module")
mdns = {}
mdns.__index = mdns

--- mdns.register is stock nodemcu API
mdns.register = function(hostname, attributes)
  nodemcu.mdns_hostname = hostname
  nodemcu.mdns_attributes = attributes
end

return mdns
