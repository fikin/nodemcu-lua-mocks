--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]

adc = {}
adc.__index = adc

adc.TestData = {}
adc.TestData.reset = function()
  adc.TestData.beforeReadCallback = function() return 1024 end
end
adc.TestData.reset()

adc.read = function(pin)
  return adc.TestData.beforeReadCallback()
end

adc.TestData.setBeforeReadCalback = function(cb)
  adc.TestData.beforeReadCallback = cb
end

adc.TestData.setValueReadSequence = function(valuesArr)
  local i = 0 
  adc.TestData.setBeforeReadCalback(function()
    i = (i < table.getn(valuesArr) and i or 0) + 1
    return valuesArr[i]
  end)
end

return adc