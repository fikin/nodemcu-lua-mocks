--[[
License : GPLv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local duration = {}

-- A fancy way to declare 2147483647 (31 bits cycle-over value for tmr.now)
-- node.compiler fails with "unexpected end in precompiled chunk"
-- if the value is given in source code
-- if lua code is interpreted i.e. not compiled, there are no errors ... strange ...
duration.TMR_SWAP_TIME = 1073741823
duration.TMR_SWAP_TIME = duration.TMR_SWAP_TIME * 2

---calculates delta between two times
---@param startTime integer
---@param endTime integer
---@return integer
duration.getDelta = function(startTime, endTime)
    local deltaTime = endTime - startTime
    if deltaTime < 0 then
        deltaTime = deltaTime + duration.TMR_SWAP_TIME
    end
    return deltaTime
end

return duration
