--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
u8g2 = {}
u8g2.__index = u8g2

u8g2.font_helvB24_tf = 1
u8g2.font_6x10_tf = 2

-- represents a display of nodemcu u8g2.disp nature
local Disp = {}
--- Disp:new instantiates new u8g2.disp object
function Disp:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end
--- Disp.setFlipMode implements stock nodemcu u8g2.disp API
Disp.setFlipMode = function(self, mode)
end
--- Disp.setContrast implements stock nodemcu u8g2.disp API
Disp.setContrast = function(self, value)
end
--- Disp.setFontMode implements stock nodemcu u8g2.disp API
Disp.setFontMode = function(self, mode)
end
--- Disp.setDrawColor implements stock nodemcu u8g2.disp API
Disp.setDrawColor = function(self, color)
end
--- Disp.setBitmapMode implements stock nodemcu u8g2.disp API
Disp.setBitmapMode = function(self, mode)
end
--- Disp.setFont implements stock nodemcu u8g2.disp API
Disp.setFont = function(self, font)
end
--- Disp.setFontRefHeightExtendedText implements stock nodemcu u8g2.disp API
Disp.setFontRefHeightExtendedText = function(self)
end
--- Disp.setDefaultForegroundColor implements stock nodemcu u8g2.disp API
Disp.setDefaultForegroundColor = function(self)
end
--- Disp.setFontPosTop implements stock nodemcu u8g2.disp API
Disp.setFontPosTop = function(self)
end
--- Disp.drawFrame implements stock nodemcu u8g2.disp API
Disp.drawFrame = function(self, x1, y1, x2, y2)
  print("frame: " .. x1 .. "/" .. y1 .. " - " .. x2 .. "/" .. y2)
end
--- Disp.drawStr implements stock nodemcu u8g2.disp API
Disp.drawStr = function(self, x, y, str)
  print("[" .. x .. "/" .. y .. "] " .. str)
end
--- Disp.clearBuffer implements stock nodemcu u8g2.disp API
Disp.clearBuffer = function(self)
end
--- Disp.sendBuffer implements stock nodemcu u8g2.disp API
Disp.sendBuffer = function(self)
end

--- u8g2.ssd1306_i2c_128x64_noname is stock nodemcu API
u8g2.ssd1306_i2c_128x64_noname = function(id, slaAddress)
  return Disp:new()
end

return u8g2
