--[[
License : GPLv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local nodemcu = require("nodemcu-module")

---adc module
---@class adc
adc = {}
adc.__index = adc

---adc.read serves values provided by cb (see adc.TestData.setOnReadCalback)
---@param channel integer must be 0
---@return integer value from cb. If cb is not assigned, returns fixed 1024.
adc.read = function(channel)
  assert(channel == 0, "expects adc channel to be 0 but found " .. tostring(channel))
  return nodemcu.adc_read_cb()
end

return adc
