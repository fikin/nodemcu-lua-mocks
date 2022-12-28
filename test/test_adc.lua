--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local nodemcu = require("nodemcu")
local lu = require("luaunit")
local tools = require("tools")

function testBeforeReadCallback()
  nodemcu.reset()
  nodemcu.adc_read_cb = function() return 44; end
  lu.assertEquals(adc.read(0), 44)
end

function testReadSequence()
  nodemcu.reset()
  nodemcu.adc_read_cb = tools.cbReturnRingBuf({ 1001, 0, 99 })
  lu.assertEquals(adc.read(0), 1001)
  lu.assertEquals(adc.read(0), 0)
  lu.assertEquals(adc.read(0), 99)
  lu.assertEquals(adc.read(0), 1001)
end

os.exit(lu.run())
