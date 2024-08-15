--[[
License : GPLv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local lu = require("luaunit")
local tools = require("tools")

function testInputArrayFnc()
  local f = tools.arrayToFunc({ "1", "2", "3" }, false)
  lu.assertEquals(f(), "1")
  lu.assertEquals(f(), "2")
  lu.assertEquals(f(), "3")
  lu.assertIsNil(f())
end

function testNilInputArrayFnc()
  lu.assertErrorMsgContains("array is nil", tools.arrayToFunc, nil, false)
end

function testInputArrayCycleFnc()
  local f = tools.arrayToFunc({ "1", "2", "3" }, true)
  lu.assertEquals(f(), "1")
  lu.assertEquals(f(), "2")
  lu.assertEquals(f(), "3")
  lu.assertEquals(f(), "1")
  lu.assertEquals(f(), "2")
end

function testCollectDataFnc()
  local o = tools.collectDataToArray()
  lu.assertNotIsNil(o)
  lu.assertEquals(o.get(), {})
  o.put("1")
  o.put("2")
  lu.assertEquals(o.get(), { { "1" }, { "2" } })
  o.put("3")
  lu.assertEquals(o.get(), { { "3" } })
end

os.exit(lu.run())
