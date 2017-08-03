--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]

u8g = {}
u8g.__index = u8g

u8g.font_6x10 = 1

local Disp = { page = 0; }
function Disp:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end
Disp.setFont = function(self,size) end
Disp.setFontRefHeightExtendedText = function(self) end
Disp.setDefaultForegroundColor = function(self) end
Disp.setFontPosTop = function(self) end
Disp.drawFrame = function(self,x1,y1,x2,y2) print("frame: "..x1..'/'..y1..' - '..x2..'/'..y2); end
Disp.drawStr = function(self,x, y, str) print('['..x..'/'..y..'] '..str); end
Disp.firstPage = function(self) self.page = 1; end
Disp.nextPage = function(self) self.page = self.page + 1; return self.page == 3; end

u8g.ssd1306_128x64_i2c = function(slaAddress)
  return Disp:new()
end

return u8g