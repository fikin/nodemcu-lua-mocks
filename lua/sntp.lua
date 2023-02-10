--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local nodemcu = require("nodemcu-module")

---@class sntp
sntp = {}
sntp.__index = sntp

---sntp.register is stock nodemcu API
---@param server_ips string[]
---@param callbackOnOk? fun()
---@param errcallback? fun()
---@param autorepeat? any
sntp.sync = function(server_ips, callbackOnOk, errcallback, autorepeat)
  -- TODO add implementation
end

return sntp
