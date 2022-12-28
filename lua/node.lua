--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]

---@class node
node = {}
node.__index = node

---stock API
---@param str string
node.input = function(str)
  pcall(
    function()
      str()
    end
  )
end

return node
