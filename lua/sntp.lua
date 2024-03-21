--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]

---@class sntp
sntp = {}
sntp.__index = sntp

---sntp.register is stock nodemcu API
---@param server_ips string[]|nil
---@param callbackOnOk? fun()
---@param errcallback? fun()
---@param _? any autorepeat
sntp.sync = function(server_ips, callbackOnOk, errcallback, _)
  assert(type(server_ips) == "table" or type(server_ips) == "string")
  if callbackOnOk then
    assert(type(callbackOnOk) == "function")
    if errcallback then
      assert(type(errcallback) == "function")
    end
  end
  -- TODO add implementation
end

return sntp
