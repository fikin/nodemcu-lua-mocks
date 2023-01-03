--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local lu = require("luaunit")
local fifoArr = require("fifo-arr")

function testFifo()
    local f = fifoArr.new()
    lu.assertIsFalse(f:hasMore())
    f:push("aa")
    lu.assertIsTrue(f:hasMore())
    lu.assertEquals(f:pop(), "aa")
    lu.assertIsFalse(f:hasMore())
    lu.assertIsNil(f:pop())
    f:push("bb")
    lu.assertEquals(f:getAll(), { "aa", "bb" })
    lu.assertEquals(f:pop(), "bb")
end

os.exit(lu.run())
