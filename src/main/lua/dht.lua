--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]

dht = {}
dht.__index = dht

dht.OK = 1
dht.ERROR_CHECKSUM = 2
dht.ERROR_TIMEOUT = 3

dht.TestData = {}
dht.TestData.reset = function()
  dht.TestData.beforeReadCallback = function() return { dht.OK, 0, 0, 0, 0 } end
end
dht.TestData.reset()

dht.read = function(pin)
  return unpack(dht.TestData.beforeReadCallback())
end

dht.TestData.setBeforeReadCalback = function(cb)
  dht.TestData.beforeReadCallback = cb
end

dht.TestData.setValueReadSequence = function(valuesArr)
  local i = 0 
  dht.TestData.setBeforeReadCalback(function()
    i = (i < table.getn(valuesArr) and i or 0) + 1
    return valuesArr[i]
  end)
end

return dht