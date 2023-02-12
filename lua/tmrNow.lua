--[[
    Only tmr.now() like function, to remove unhealty dependencies towards tmr module.
]]
local Timer = require("Timer")

local function tmrNow()
    -- return microsec, mimic 31 bit cycle over
    return (Timer.getCurrentTimeMs() % require("duration").TMR_SWAP_TIME) * 1000
end

return tmrNow
