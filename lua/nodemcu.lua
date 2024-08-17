--[[
License : GPLv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]

-- imports all global variables
-- and returns nodemcu mock which is used in test cases
-- to interact with device functionality.

local nodemcu = require("nodemcu-module")
require("bit")
require("adc")
require("ads1115")
require("dht")
require("i2c")
require("mdns")
require("u8g")
require("u8g2")
require("rotary")
require("node")
require("sjson")
require("file")
require("enduser_setup")
require("gpio")
require("pwm")
require("net")
require("tmr")
require("wifi")
require("wifi-control")
require("rtcmem")
require("rtctime")
require("crypto")
require("encoder")
require("ow")
require("sntp")

return nodemcu
