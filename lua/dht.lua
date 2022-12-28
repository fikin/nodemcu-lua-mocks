--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local nodemcu = require("nodemcu-module")

---dht module
---@class dht
dht = {}
dht.__index = dht

dht.OK = 1
dht.ERROR_CHECKSUM = 2
dht.ERROR_TIMEOUT = 3

--- dht.read serves values provided by cb (see dht.TestData.setOnReadCalback)
---@param pin integer pin to read from
---@return integer status from nodemcu.dht_value(pin) or dht.OK
---@return integer temp from nodemcu.dht_value(pin) or 0
---@return integer humi nodemcu.dht_value(pin) or 0
---@return integer temp_dec nodemcu.dht_value(pin) or 0
---@return integer humi_dec nodemcu.dht_value(pin) or 0
dht.read = function(pin)
  return table.unpack(nodemcu.dht_read_cb(pin))
end

return dht
