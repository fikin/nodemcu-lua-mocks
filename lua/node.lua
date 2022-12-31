--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local nodemcu = require("nodemcu-module")
local tmr = require("tmr")

---@class node_lfs
local LFS = {}
LFS.__index = LFS

---stock API
---@return table
LFS.list = function()
  -- TODO
  return {}
end

---stock API
---@param modName any
---@return nil
LFS.get = function(modName)
  -- TODO
  return nil
end

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

return node
