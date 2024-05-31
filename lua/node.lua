--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local nodemcu = require("nodemcu-module")
local LFS = require("node-lfs")
local Task = require("node-task")
local tools = require("tools")

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

---prints all arguments, space delimited to node.outout
---and optionally to stdout.
---arguments are from "pcall" call i.e. arg[1] if pcall ok/false flag
---@param ... any
local function pipePcallResp(...)
  local args = { ... }
  local str = table.concat(tools.tblMap(args, tostring), " ", 2)
  nodemcu.node.outputPipe:write(str)
  if nodemcu.node.outputToSerial then print(str) end
end

---stock API
---puts output  result to node.ouput().
---@param str string
node.input = function(str)
  assert(str, "node.input() does not accepts nil")
  nodemcu.node.inputStr = nodemcu.node.inputStr .. str
  local fnc, err = load(nodemcu.node.inputStr, "node")
  if fnc then
    pipePcallResp(pcall(fnc))
    nodemcu.node.inputStr = ""
  else
    pipePcallResp(false, err)
  end
  nodemcu.node.outputPipe:write("\n")
  if nodemcu.node.outputFn then
    nodemcu.node.outputFn(nodemcu.node.outputPipe)
  end
end

---stock API
---calls outputFn for each node.input()
---if outputFn not set, it uses print().
---@param outputFn? tools_pipe_create_cb
---@param printToSerial? integer 1 means print to serial too, 0 means do not
node.output = function(outputFn, printToSerial)
  nodemcu.node.outputToSerial = printToSerial == 1 or false
  nodemcu.node.outputPipe = tools.new_pipe()
  nodemcu.node.outputFn = outputFn
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
---raises error "node.restart"
node.restart = function()
  error("node.restart")
end

---stock API
---@return integer heap for now it is fixed to 32096 value
node.heap = function()
  return 32096
end

---stock API
---@return number one or 80 or 160
node.getcpufreq = function()
  return nodemcu.node.cpufreq
end

---stock API
---@param us integer delay in microseconds
node.delay = function(us)
  assert(type(us) == "number")
  -- TODO : how to advance time? Do we really need to delay anything in mocked tests?
end

---stocl API
---compiles given .lua file to .lc
---NOTE it can compile only function body compliant code
---i.e. it has to end with "return ..."
---@param fName string
node.compile = function(fName)
  -- read .lua file
  local fd1, err1 = io.open(nodemcu.fileLoc(fName), "r")
  assert(err1 == nil, string.format("failed opening file for reading : %s : %s", fName, err1))
  assert(fd1, string.format("failed opening file for reading : %s", fName))
  local code, err = fd1:read(1024 * 1024)
  assert(err == nil, string.format("failed while reading file : %s : %s", fName, err))
  fd1:close()

  -- load
  local f3, err3 = load(code)
  assert(err3 == nil, string.format("failed parsing code of file : %s : %s", fName, err3))
  assert(f3, string.format("loaded file is not a function : %s", fName))

  -- compile to bytecode
  local bytecode = string.dump(f3)

  -- write to .lc file
  local fName2 = string.gsub(fName, ".lua", ".lc")
  local fd2, err2 = io.open(nodemcu.fileLoc(fName2), "w")
  assert(err2 == nil, string.format("failed writing file : %s : %s", fName2, err2))
  assert(fd2, string.format("failed opening file for writing : %s", fName2))
  _, err2 = fd2:write(bytecode)
  assert(err2 == nil, string.format("failed while writing to file : %s : %s", fName2, err2))
  fd2:close()
end

return node
