--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
node = {}
node.__index = node

--- node.input is stock nodemcu API
node.input = function(str)
  pcall(
    function()
      str()
    end
  )
end

return node
