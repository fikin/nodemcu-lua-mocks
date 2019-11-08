--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]

sjson = {}
sjson.__index = sjson

local JSON = require('JSON')

-- implements sjson.decoder methods
local JsonDecorer = {}
JsonDecorer.__index = JsonDecorer

--- JsonDecorer.new instantiates new instance of decoder
JsonDecorer.new = function()
  local o = {}
  setmetatable(o,JsonDecorer)
  o._data = nil
  return o
end

--- JsonDecorer.write implements stock nodemcu sjson.decoder API
JsonDecorer.write = function(self,data)
  if self._data then
    self._data = self._data..data
  else
    self._data = data
  end
end

--- JsonDecorer.result implements stock nodemcu sjson.decoder API
JsonDecorer.result = function(self)
  --print('sjson: decoding '..self._data..' ...')
  return JSON:decode( self._data )
end

-- implements sjson.encoder interface
local JsonEncoder = {}
JsonEncoder.__index = JsonEncoder

--- JsonEncoder.new instantiates new encoder object
JsonEncoder.new = function(obj)
  local o = {}
  setmetatable(o,JsonEncoder)
  o._data = JSON:encode(obj)
  o._len = string.len(o._data)
  o._readStartIndex = 1
  return o
end

--- JsonEncoder.read implements stock nodemcu sjson.encoder API
JsonEncoder.read = function(self,size)
  if self._readStartIndex <= self._len then
    local endIndex = self._readStartIndex + size
    if endIndex > self._len then endIndex = self._len end
    local str = string.sub(self._data,self._readStartIndex,endIndex)
    self._readStartIndex = endIndex + 1
    return str
  end
  return nil
end

--- sjson.decoder is stock nodemcu API
sjson.decoder = function() return JsonDecorer.new() end

-- sjson.encoder is stock nodemcu API
sjson.encoder = function(obj) return JsonEncoder.new(obj) end

return sjson