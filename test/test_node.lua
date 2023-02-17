--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local nodemcu = require("nodemcu")
local lu = require("luaunit")
local tools = require("tools")

local node = require("node")

function testOk()
    nodemcu.reset()

    lu.assertEquals(node.heap(), 32096)
end

function testRestart()
    nodemcu.reset()

    lu.assertIsFalse(nodemcu.node.restartRequested)
    node.restart()
    lu.assertIsTrue(nodemcu.node.restartRequested)
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

os.exit(lu.run())
