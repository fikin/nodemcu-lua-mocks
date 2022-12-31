--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local nodemcu = require("nodemcu-module")

---adc module
---@class encoder
encoder = {}
encoder.__index = encoder

local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/' -- You will need this for encoding/decoding

local function enc(data)
  return ((data:gsub('.', function(x)
    local r, b = '', x:byte()
    for i = 8, 1, -1 do r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and '1' or '0') end
    return r;
  end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
    if (#x < 6) then return '' end
    local c = 0
    for i = 1, 6 do c = c + (x:sub(i, i) == '1' and 2 ^ (6 - i) or 0) end
    return b:sub(c + 1, c + 1)
  end) .. ({ '', '==', '=' })[#data % 3 + 1])
end

local function dec(data)
  data = string.gsub(data, '[^' .. b .. '=]', '')
  return (data:gsub('.', function(x)
    if (x == '=') then return '' end
    local r, f = '', (b:find(x) - 1)
    for i = 6, 1, -1 do r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and '1' or '0') end
    return r;
  end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
    if (#x ~= 8) then return '' end
    local c = 0
    for i = 1, 8 do c = c + (x:sub(i, i) == '1' and 2 ^ (8 - i) or 0) end
    return string.char(c)
  end))
end

---stock API
---@param bin string
---@return string
encoder.toBase64 = function(bin)
  return enc(bin)
end

---stock API
---@param bin string
---@return string
encoder.fromBase64 = function(bin)
  return dec(bin)
end

---stock API
---@param str string
---@return string
encoder.toHex = function(str)
  return (str:gsub('.', function(c)
    return string.format('%02X', string.byte(c))
  end))
end

---stock API
---@param str string
---@return string
encoder.fromHex = function(str)
  return (str:gsub('..', function(cc)
    return string.char(tonumber(cc, 16))
  end))
end

return encoder
