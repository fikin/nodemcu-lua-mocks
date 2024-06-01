--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]

---@class mdns
mdns = {}
mdns.__index = mdns

---mdns.register is stock nodemcu API
---@param hostname string
---@param attributes? table
mdns.register = function(hostname, attributes)
  assert(hostname ~= nil)
  assert(type(hostname) == "string")
  if attributes then
    assert(type(attributes) == "table")
  end
  -- TODO add implementation
end

---stock nodemcu API
mdns.close = function()
  -- TODO add implementation
end

return mdns
