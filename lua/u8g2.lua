--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]

---@class u8g2
u8g2 = {}
u8g2.__index = u8g2

u8g2.font_helvB24_tf = 1
u8g2.font_6x10_tf = 2

-- represents a display of nodemcu u8g2.disp nature
---@class u8d2_disp
local Disp = {}
Disp.__index = Disp

--- Disp:new instantiates new u8g2.disp object
function Disp.new()
  return setmetatable({}, Disp)
end

--- Disp.setFlipMode implements stock nodemcu u8g2.disp API
Disp.setFlipMode = function(self, mode)
  assert(self ~= nil)
  assert(mode ~= nil)
end
--- Disp.setContrast implements stock nodemcu u8g2.disp API
Disp.setContrast = function(self, value)
  assert(self ~= nil)
  assert(value ~= nil)
end
--- Disp.setFontMode implements stock nodemcu u8g2.disp API
Disp.setFontMode = function(self, mode)
  assert(self ~= nil)
  assert(mode ~= nil)
end
--- Disp.setDrawColor implements stock nodemcu u8g2.disp API
Disp.setDrawColor = function(self, color)
  assert(self ~= nil)
  assert(color ~= nil)
end
--- Disp.setBitmapMode implements stock nodemcu u8g2.disp API
Disp.setBitmapMode = function(self, mode)
  assert(self ~= nil)
  assert(mode ~= nil)
end
--- Disp.setFont implements stock nodemcu u8g2.disp API
Disp.setFont = function(self, font)
  assert(self ~= nil)
  assert(font ~= nil)
end
--- Disp.setFontRefHeightExtendedText implements stock nodemcu u8g2.disp API
Disp.setFontRefHeightExtendedText = function(self)
  assert(self ~= nil)
end
--- Disp.setDefaultForegroundColor implements stock nodemcu u8g2.disp API
Disp.setDefaultForegroundColor = function(self)
  assert(self ~= nil)
end
--- Disp.setFontPosTop implements stock nodemcu u8g2.disp API
Disp.setFontPosTop = function(self)
  assert(self ~= nil)
end
--- Disp.drawFrame implements stock nodemcu u8g2.disp API
Disp.drawFrame = function(self, x1, y1, x2, y2)
  assert(self ~= nil)
  print("frame: " .. x1 .. "/" .. y1 .. " - " .. x2 .. "/" .. y2)
end
--- Disp.drawStr implements stock nodemcu u8g2.disp API
Disp.drawStr = function(self, x, y, str)
  assert(self ~= nil)
  print("[" .. x .. "/" .. y .. "] " .. str)
end
--- Disp.clearBuffer implements stock nodemcu u8g2.disp API
Disp.clearBuffer = function(self)
  assert(self ~= nil)
end
--- Disp.sendBuffer implements stock nodemcu u8g2.disp API
Disp.sendBuffer = function(self)
  assert(self ~= nil)
end

--- u8g2.ssd1306_i2c_128x64_noname is stock nodemcu API
---@param id integer
---@param slaAddress integer
---@return u8d2_disp
u8g2.ssd1306_i2c_128x64_noname = function(id, slaAddress)
  assert(id ~= nil)
  assert(slaAddress ~= nil)
  return Disp.new()
end

return u8g2
