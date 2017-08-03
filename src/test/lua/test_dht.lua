--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]

luaunit = require('luaunit')

require('dht')

function testBeforeReadCallback()
  dht.TestData.reset()
  dht.TestData.setBeforeReadCalback(function()
    return { dht.OK, 11, 22, 33, 44 }
  end)
  local status, temperature, humi, temp_decimial, humi_decimial = dht.read(1)
  luaunit.assertEquals( status, dht.OK)
  luaunit.assertEquals( temperature, 11)
  luaunit.assertEquals( humi, 22)
  luaunit.assertEquals( temp_decimial, 33)
  luaunit.assertEquals( humi_decimial, 44)
end

function testReadSequence()
  dht.TestData.reset()
  dht.TestData.setValueReadSequence({ { dht.OK, 10, 70, 0, 0 }, { dht.ERROR_TIMEOUT, 33, 11, 0, 0 }, { dht.OK, 22, 55, 0, 0 } })
  local status, temperature, humi, temp_decimial, humi_decimial = dht.read(1)
  luaunit.assertEquals( status, dht.OK)
  luaunit.assertEquals( temperature, 10)
  luaunit.assertEquals( humi, 70)
  status, temperature, humi, temp_decimial, humi_decimial = dht.read(1)
  luaunit.assertEquals( status, dht.ERROR_TIMEOUT)
  luaunit.assertEquals( temperature, 33)
  luaunit.assertEquals( humi, 11)
  status, temperature, humi, temp_decimial, humi_decimial = dht.read(1)
  luaunit.assertEquals( status, dht.OK)
  luaunit.assertEquals( temperature, 22)
  luaunit.assertEquals( humi, 55)
  status, temperature, humi, temp_decimial, humi_decimial = dht.read(1)
  luaunit.assertEquals( status, dht.OK)
  luaunit.assertEquals( temperature, 10)
  luaunit.assertEquals( humi, 70)
end

os.exit( luaunit.LuaUnit.run() )
