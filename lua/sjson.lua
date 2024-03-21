--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local JSON = require("JSON")

---@class sjson
sjson = {}
sjson.__index = sjson

---implements sjson.decoder methods
---@class sjson_decoder
---@field _data string
local JsonDecorer = {}
JsonDecorer.__index = JsonDecorer

--- JsonDecorer.new instantiates new instance of decoder
---@return sjson_decoder
JsonDecorer.new = function()
  local o = {}
  setmetatable(o, JsonDecorer)
  o._data = nil
  return o
end

--- JsonDecorer.write implements stock nodemcu sjson.decoder API
---@param self sjson_decoder
---@param data string
JsonDecorer.write = function(self, data)
  if self._data then
    self._data = self._data .. data
  else
    self._data = data
  end
end

--- JsonDecorer.result implements stock nodemcu sjson.decoder API
---@param self sjson_decoder
---@return table
JsonDecorer.result = function(self)
  --print('sjson: decoding '..self._data..' ...')
  local ret = JSON:decode(self._data)
  if type(ret) == "table" then return ret; end
  error("failed sjson conversion for data=%s, type(data)=%s, res=%s " % { self._data, type(ret), ret })
end

-- implements sjson.encoder interface
---@class sjson_encoder
---@field private _len integer
---@field private _data string
---@field private _readStartIndex integer
local JsonEncoder = {}
JsonEncoder.__index = JsonEncoder

--- JsonEncoder.new instantiates new encoder object

---new decoder
---@param obj table
---@return sjson_encoder
JsonEncoder.new = function(obj)
  local o = {}
  setmetatable(o, JsonEncoder)
  o._data = JSON:encode(obj)
  o._len = string.len(o._data)
  o._readStartIndex = 1
  return o
end

--- JsonEncoder.read implements stock nodemcu sjson.encoder API
---@param self sjson_encoder
---@param size integer
---@return string|nil
JsonEncoder.read = function(self, size)
  assert(type(self) == "table")
  size = size or 1024
  assert(type(size) == "number")
  if self._readStartIndex <= self._len then
    local endIndex = self._readStartIndex + size
    if endIndex > self._len then
      endIndex = self._len
    end
    local str = string.sub(self._data, self._readStartIndex, endIndex)
    self._readStartIndex = endIndex + 1
    return str
  end
  return nil
end

--- sjson.decoder is stock nodemcu API
---@return sjson_decoder
sjson.decoder = function()
  return JsonDecorer.new()
end

-- sjson.encoder is stock nodemcu API
---@param obj table
---@return sjson_encoder
sjson.encoder = function(obj)
  return JsonEncoder.new(obj)
end

---returns given json text as table
---@param str any
---@param opts? any
---@return table
sjson.decode = function(str, opts)
  if opts then
    assert(type(opts) == "table")
  end
  local d = JsonDecorer.new()
  d:write(str)
  return d:result()
end

---returns json text for given table
---@param tbl table
---@param opts? table
---@return string|nil
sjson.encode = function(tbl, opts)
  if opts then
    assert(type(opts) == "table")
  end
  local d = JsonEncoder.new(tbl)
  return d:read(4096)
end

return sjson
