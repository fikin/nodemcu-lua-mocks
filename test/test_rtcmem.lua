--[[
License : GPLv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local nodemcu = require("nodemcu")
local lu = require("luaunit")

local rtcmem = require("rtcmem")

function testOk()
  nodemcu.reset()
  lu.assertNotIsNaN(rtcmem.read32(10))
  rtcmem.write32(1, 0xABCDEF12)
  rtcmem.write32(2, 0x11223344, 0x55667788)
  lu.assertEquals(rtcmem.read32(2), 0x11223344)
  lu.assertEquals(table.pack(rtcmem.read32(1, 3)), table.pack(0xABCDEF12, 0x11223344, 0x55667788))
end

os.exit(lu.run())
