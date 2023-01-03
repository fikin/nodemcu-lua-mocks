--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local nodemcu = require("nodemcu-module")
local LFS = require("node-lfs")
local Task = require("node-task")

---@class node
node = {
  LFS = LFS,
  task = Task,
}
node.__index = node

---@class node_parttable
---@field lfs_addr integer
---@field lfs_size integer
---@field spiffs_addr integer
---@field spiffs_size integer

---@class node_bootreason
---@field rawcode integer
---@field reason integer
---@field exccause? integer
---@field epc1? integer
---@field epc2? integer
---@field epc3? integer
---@field excvaddr? integer
---@field depc? integer


---stock API
---@param str string
node.input = function(str)
  pcall(
    function()
      str()
    end
  )
end

---stock API
---@return node_parttable
node.getpartitiontable = function()
  return nodemcu.node.parttable
end

---stock API
---@return integer rawcode
---@return integer reason
---@return integer|nil exccause
---@return integer|nil epc1
---@return integer|nil epc2
---@return integer|nil epc3
---@return integer|nil excvaddr
---@return integer|nil depc
node.bootreason = function()
  return nodemcu.node.bootreason.rawcode, nodemcu.node.bootreason.reason
end

---stock API
---@return integer
node.chipid = function()
  return nodemcu.node.chipid
end

---stock API
node.restart = function()
  error("FIXME node.restart() is not implemented")
end

return node
