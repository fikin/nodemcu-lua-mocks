--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local nodemcu = require("nodemcu")
local lu = require("luaunit")
local tools = require("tools")

local bit = require("bit")

function testBit()
  nodemcu.reset()
  lu.assertEquals(bit.bnot(1), 4294967294)
  lu.assertEquals(bit.bor(1, 2), 3)
  lu.assertEquals(bit.bxor(1, 3), 2)
end

os.exit(lu.run())
