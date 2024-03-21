--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local nodemcu = require("nodemcu")
local lu = require("luaunit")

function test()
  nodemcu.reset()

  lu.assertEquals(nodemcu.pwm_get_history(), {})

  pwm.setup(1, 2, 3)
  lu.assertEquals(nodemcu.pwm_get_history(), {{event = "setup", pin = 1, clock = 2, duty = 3}})

  pwm.start(1)
  pwm.setduty(1, 21)
  pwm.stop(1)
  pwm.close(1)
  lu.assertEquals(
    nodemcu.pwm_get_history(),
    {
      {event = "start", pin = 1},
      {event = "setduty", pin = 1, duty = 21},
      {event = "stop", pin = 1},
      {event = "close", pin = 1}
    }
  )
end

os.exit(lu.run())
