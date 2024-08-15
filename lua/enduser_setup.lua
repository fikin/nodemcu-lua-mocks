--[[
License : GPLv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]

---@class enduser_setup
enduser_setup = {}
enduser_setup.__index = enduser_setup

---stock api
---@param on_off boolean
enduser_setup.manual = function(on_off)
  assert(type(on_off) == "boolean")
  -- TODO add implementation
end

---stock api
---@param onConnected fun()
---@param onError fun(err_num:integer, desc:string)
---@param onDebug fun(desc: string)
enduser_setup.start = function(onConnected, onError, onDebug)
  assert(type(onConnected) == "function")
  assert(type(onError) == "function")
  assert(type(onDebug) == "function")
  -- TODO add implementation
end

---stock api
enduser_setup.stop = function()
  -- TODO add implementation
end

return enduser_setup
