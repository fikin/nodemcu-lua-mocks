--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local nodemcu = require("nodemcu")
local lu = require("luaunit")

function test()
  nodemcu.reset()

  expPos = 0
  rotary.setup(0, 1, 2, 3)
  rotary.on(0, rotary.TURN, function(eventType, pos, _)
    lu.assertEquals(eventType, rotary.TURN)
    lu.assertEquals(pos, expPos)
  end)
  rotary.on(0, rotary.CLICK, function(eventType, pos, _)
    lu.assertEquals(eventType, rotary.CLICK)
    lu.assertEquals(pos, expPos)
  end)

  nodemcu.rotary_press(0, rotary.CLICK)
  expPos = 100
  nodemcu.rotary_turn(0, 100)
  expPos = 1
  nodemcu.rotary_turn(0, -99)

  rotary.on(0, rotary.TURN)
  nodemcu.rotary_turn(0, 0)
end

os.exit(lu.run())
