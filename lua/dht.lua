--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local nodemcu = require("nodemcu-module")

dht = {}
dht.__index = dht

dht.OK = 1
dht.ERROR_CHECKSUM = 2
dht.ERROR_TIMEOUT = 3

--- dht.read serves values provided by cb (see dht.TestData.setOnReadCalback)
-- @param is pin to read from
-- @return value from cb. If cb is not assigned, returns "dht.OK, 0, 0, 0, 0".
dht.read = function(pin)
  nodemcu.assertPinRange(pin)
  return unpack(nodemcu.dht_read_cb(pin))
end

return dht
