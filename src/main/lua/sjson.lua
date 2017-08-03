--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]

sjson = {}
sjson.__index = sjson

local JSON = require('JSON')

JsonDecorer = {}
JsonDecorer.__index = JsonDecorer

JsonEncoder = {}
JsonEncoder.__index = JsonEncoder

sjson.TestData = {}
sjson.TestData.reset = function()
end
sjson.TestData.reset()

JsonDecorer.new = function()
  local o = {}
  setmetatable(o,JsonDecorer)
  o._data = nil
  return o
end
JsonDecorer.write = function(self,data)
  if self._data then
    self._data = self._data..data
  else
    self._data = data
  end
end
JsonDecorer.result = function(self)
  --print('sjson: decoding '..self._data..' ...')
  return JSON:decode( self._data )
end

JsonEncoder.new = function(obj)
  local o = {}
  setmetatable(o,JsonEncoder)
  o._data = JSON:encode(obj)
  o._len = string.len(o._data)
  o._readStartIndex = 1
  return o
end
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

sjson.decoder = function() return JsonDecorer.new() end
sjson.encoder = function(obj) return JsonEncoder.new(obj) end

return sjson