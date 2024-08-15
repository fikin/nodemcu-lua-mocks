--[[
License : GPLv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local nodemcu = require("nodemcu")
local lu = require("luaunit")

local node = require("node")

function testOk()
    nodemcu.reset()

    lu.assertEquals(node.heap(), 32096)
end

function testRestart()
    nodemcu.reset()

    local ok, err = pcall(node.restart)
    lu.assertIsFalse(ok)
    lu.assertStrContains(err, "node.restart")
end

function testInput()
    nodemcu.reset()

    local stdout

    node.output(function(opipe)
        stdout = opipe;
        return false;
    end, 1)

    -- these return statements are needed in mock testing only
    -- because node.output() is not natively connected with Lua output stream.
    -- in real NodeMCU firmware, "print()" will directly print to node.output.
    node.input("return 11, 'bb'")
    node.input("return node.heap()")

    node.output()

    node.input("return 22, 'cc'")

    lu.assertEquals(stdout:read(2000), "11 bb\n32096\n")
end

function testCompile()
    nodemcu.reset()

    local file = require("file")

    local f1 = "f1.lua"
    local f2 = "f1.lc"

    file.remove(f1)
    file.remove(f2)

    local ok = file.putcontents(f1, "return { a=1, b={ c=2, d=\"dd\" } }")
    lu.assertIsTrue(ok)

    node.compile(f1)

    local bytecode = file.getcontents(f2)
    assert(bytecode)
    local f = load(bytecode)
    assert(f)
    lu.assertEquals(f(), { a = 1, b = { c = 2, d = "dd" } })
end

os.exit(lu.run())
