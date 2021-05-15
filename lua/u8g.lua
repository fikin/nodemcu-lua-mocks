--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
u8g = {}
u8g.__index = u8g

u8g.font_6x10 = 1

-- represents a display of nodemcu u8g.disp nature
local Disp = {page = 0}
--- Disp:new instantiates new u8g.disp object
function Disp:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end
--- Disp.setFont implements stock nodemcu u8g.disp API
Disp.setFont = function(self, font)
end
--- Disp.setFontRefHeightExtendedText implements stock nodemcu u8g.disp API
Disp.setFontRefHeightExtendedText = function(self)
end
--- Disp.setDefaultForegroundColor implements stock nodemcu u8g.disp API
Disp.setDefaultForegroundColor = function(self)
end
--- Disp.setFontPosTop implements stock nodemcu u8g.disp API
Disp.setFontPosTop = function(self)
end
--- Disp.drawFrame implements stock nodemcu u8g.disp API
Disp.drawFrame = function(self, x1, y1, x2, y2)
  print("frame: " .. x1 .. "/" .. y1 .. " - " .. x2 .. "/" .. y2)
end
--- Disp.drawStr implements stock nodemcu u8g.disp API
Disp.drawStr = function(self, x, y, str)
  print("[" .. x .. "/" .. y .. "] " .. str)
end
--- Disp.firstPage implements stock nodemcu u8g.disp API
Disp.firstPage = function(self)
  self.page = 1
end
--- Disp.nextPage implements stock nodemcu u8g.disp API
Disp.nextPage = function(self)
  self.page = self.page + 1
  return self.page == 3
end

--- u8g.ssd1306_128x64_i2c is stock nodemcu API
u8g.ssd1306_128x64_i2c = function(slaAddress)
  return Disp:new()
end

return u8g
