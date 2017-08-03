--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]

mdns = {}
mdns.__index = mdns

mdns.TestData = {}
mdns.TestData.reset = function()
  mdns.TestData.hostname = nil
  mdns.TestData.attributes = nil
end
mdns.TestData.reset()

mdns.register = function(hostname, attributes)
  mdns.TestData.hostname = hostname
  mdns.TestData.attributes = attributes
end

return mdns