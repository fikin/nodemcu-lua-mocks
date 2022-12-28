--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local nodemcu = require("nodemcu")
local lu = require("luaunit")
local tools = require("tools")

function testGetPutOk()
    nodemcu.reset()
    local loc = "aa.txt"
    local data = "1234"
    lu.assertIsTrue(file.putcontents(loc, data))
    lu.assertEquals(file.getcontents(loc), data)
end

function testReadWriteOk()
    nodemcu.reset()
    local loc = "aa.bin"
    local data = "abcd"

    local f = file.open(loc, "w")
    assert(f)
    lu.assertNotIsNil(f)
    f:write(data)
    f:close()

    f = file.open(loc, "r")
    assert(f)
    local arr = f:read()
    lu.assertEquals(arr, data)
end

function testRenameRemoveExistsStatOk()
    nodemcu.reset()
    local loc = "aa.txt"
    local data = "1234"
    lu.assertIsTrue(file.putcontents(loc, data))
    lu.assertIsTrue(file.exists(loc))
    lu.assertEquals(4, file.stat(loc).size)
    local newLoc = "bak_" .. loc
    lu.assertIsTrue(file.rename(loc, newLoc))
    lu.assertEquals(file.getcontents(newLoc), data)
    file.remove(newLoc)
end

os.exit(lu.run())
