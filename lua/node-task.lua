--[[
License : GPLv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local tmr = require("tmr")

---@class node_task
local Task = {
    LOW_PRIORITY = 0,
    MEDIUM_PRIORITY = 1,
    HIGH_PRIORITY = 2,
}
Task.__index = Task

---stock API
---@param prio? integer
---@param fnc fun()
Task.post = function(prio, fnc)
    if type(prio) == "function" then fnc = prio; end
    tmr.create():alarm(1, tmr.ALARM_SINGLE, fnc)
end

return Task
