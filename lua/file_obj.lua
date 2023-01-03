--[[
  File object abstractions
]]

---@class file_obj
---@field private _fd file*
local FileObj = {
  ---@private
  _isClosed = false
}
FileObj.__index = FileObj

---global setting to indicate how many bytes to read() if no len is given
---Overwrite in the test cases if required.
FileObj.FILE_READ_CHUNK = 1024

---close the file
---@param self file_obj
FileObj.close = function(self)
  if not self:isClosed() then
    self._fd:close()
    self._isClosed = true
  end
end

---true if the file is already closed
---@param self file_obj
---@return boolean
FileObj.isClosed = function(self)
  return self._isClosed
end

---flush content
---@param self file_obj
FileObj.flush = function(self)
  self._fd:flush()
end

---read via io.read
---@param self file_obj
---@param len? integer
---@return string
FileObj.read = function(self, len)
  return self._fd:read(len or FileObj.FILE_READ_CHUNK)
end

---read "*line"
---@param self file_obj
---@return string
FileObj.readline = function(self)
  return self._fd:read("*line")
end

---seek
---@param self file_obj
---@param ... unknown
---@return integer
FileObj.seek = function(self, ...)
  return self._fd:seek(...)
end

---write using io.write
---@param self file_obj
---@param ... unknown
---@return boolean|nil
FileObj.write = function(self, ...)
  local _, err = self._fd:write(...)
  return err == nil or nil
end

---writes str+\n using io.write
---@param self file_obj
---@param str any
---@return boolean|nil
FileObj.writeline = function(self, str)
  local _, err = self._fd:write(str .. "\n")
  return err == nil or nil
end

---
---Opens a file, in the mode specified in the string `mode`.
---
---@param loc string
---@param mode? openmode
---@return file_obj|nil
---@return string|nil errmsg
---@nodiscard
local function newFile(loc, mode)
  assert(type(loc) == "string", "location must be string")
  assert(type(mode) == "string", "file mode must be provided")
  local fd, err = io.open(loc, mode)
  if fd then
    local o = {
      _fd = fd
    }
    setmetatable(o, FileObj)
    return o, nil
  end
  return nil, err
end

return newFile
