--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]

luaunit = require('luaunit')

require('adc')

function testBeforeReadCallback()
  adc.TestData.reset()
  adc.TestData.setBeforeReadCalback(function()
    return 44
  end)
  luaunit.assertEquals( adc.read(1), 44)
end

function testReadSequence()
  adc.TestData.reset()
  adc.TestData.setValueReadSequence({ 1001, 0, 99 })
  luaunit.assertEquals( adc.read(1), 1001)
  luaunit.assertEquals( adc.read(1), 0)
  luaunit.assertEquals( adc.read(1), 99)
  luaunit.assertEquals( adc.read(1), 1001)
end

os.exit( luaunit.LuaUnit.run() )
