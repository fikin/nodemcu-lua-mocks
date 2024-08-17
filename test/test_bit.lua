--[[
License : GPLv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local nodemcu = require("nodemcu")
local lu = require("luaunit")

local bit = require("bit")

function testBit()
  nodemcu.reset()
  lu.assertEquals(bit.bnot(1), 4294967294)
  lu.assertEquals(bit.bor(1, 2), 3)
  lu.assertEquals(bit.bxor(1, 3), 2)
  lu.assertEquals(bit.band(3, 2), 2)
  lu.assertEquals(bit.rshift(3, 1), 1)
  lu.assertTrue(bit.isset(3, 0))
  lu.assertFalse(bit.isset(2, 0))
  lu.assertFalse(bit.isclear(3, 0))
  lu.assertTrue(bit.isclear(2, 0))
  lu.assertEquals(bit.clear(3, 0), 2)
  lu.assertEquals(bit.clear(3, 1), 1)
  lu.assertEquals(bit.set(2, 0), 3)
  lu.assertEquals(bit.set(2, 1), 2)
end

os.exit(lu.run())
