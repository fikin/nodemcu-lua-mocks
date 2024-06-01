--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local nodemcu = require("nodemcu")
local lu = require("luaunit")
local tools = require("tools")

function testBeforeReadCallback()
  nodemcu.reset()
  nodemcu.dht_read_cb = function(_)
    return { dht.OK, 11, 22, 33, 44 }
  end
  local status, temperature, humi, temp_decimial, humi_decimial = dht.read(1)
  lu.assertEquals(status, dht.OK)
  lu.assertEquals(temperature, 11)
  lu.assertEquals(humi, 22)
  lu.assertEquals(temp_decimial, 33)
  lu.assertEquals(humi_decimial, 44)
end

function testReadSequence()
  nodemcu.reset()
  nodemcu.dht_read_cb =
      tools.cbReturnRingBuf(
        {
          { dht.OK,            10, 70, 0, 0 },
          { dht.ERROR_TIMEOUT, 33, 11, 0, 0 },
          { dht.OK,            22, 55, 0, 0 }
        }
      )
  local status, temperature, humi, temp_decimial, humi_decimial = dht.read(1)
  lu.assertEquals(status, dht.OK)
  lu.assertEquals(temperature, 10)
  lu.assertEquals(humi, 70)
  lu.assertEquals(temp_decimial, 0)
  lu.assertEquals(humi_decimial, 0)
  status, temperature, humi, temp_decimial, humi_decimial = dht.read(1)
  lu.assertEquals(status, dht.ERROR_TIMEOUT)
  lu.assertEquals(temperature, 33)
  lu.assertEquals(humi, 11)
  lu.assertEquals(temp_decimial, 0)
  lu.assertEquals(humi_decimial, 0)
  status, temperature, humi, temp_decimial, humi_decimial = dht.read(1)
  lu.assertEquals(status, dht.OK)
  lu.assertEquals(temperature, 22)
  lu.assertEquals(humi, 55)
  lu.assertEquals(temp_decimial, 0)
  lu.assertEquals(humi_decimial, 0)
  status, temperature, humi, temp_decimial, humi_decimial = dht.read(1)
  lu.assertEquals(status, dht.OK)
  lu.assertEquals(temperature, 10)
  lu.assertEquals(humi, 70)
  lu.assertEquals(temp_decimial, 0)
  lu.assertEquals(humi_decimial, 0)
end

os.exit(lu.run())
