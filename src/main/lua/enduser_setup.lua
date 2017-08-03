--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]

enduser_setup = {}
enduser_setup.__index = enduser_setup

enduser_setup.TestData = { 1024 }
enduser_setup.TestDataIndx = 0

enduser_setup.TestData = {
  manual = false,
  onConnected = nil,
  onError = nil,
  onDebug = nil
}

enduser_setup.manual = function(on_off)
  TestData.manual = on_off
end

-- [onConnected()], [onError(err_num, string)], [onDebug(string)]
enduser_setup.start = function(onConnected, onError, onDebug)
  TestData.onConnected = onConnected
  TestData.onError = onError
  TestData.onDebug = onDebug
end

enduser_setup.stop = function()
end

return enduser_setup