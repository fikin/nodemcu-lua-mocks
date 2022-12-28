--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local nodemcu = require("nodemcu-module")

---@class mdns
mdns = {}
mdns.__index = mdns

---mdns.register is stock nodemcu API
---@param hostname string
---@param attributes? table
mdns.register = function(hostname, attributes)
  -- TODO add implementation
end

return mdns
