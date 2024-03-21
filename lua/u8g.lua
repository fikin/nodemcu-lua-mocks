--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]

---@class u8g
u8g = {}
u8g.__index = u8g

u8g.font_6x10 = 1

---represents a display of nodemcu u8g.disp nature
---@class u8g_disp
local Disp = { page = 0 }
Disp.__index = Disp

--- Disp:new instantiates new u8g.disp object
---@return u8g_disp
function Disp.new()
  return setmetatable({}, Disp)
end

--- Disp.setFont implements stock nodemcu u8g.disp API
Disp.setFont = function(self, font)
  assert(self ~= nil)
  assert(font ~= nil)
end
--- Disp.setFontRefHeightExtendedText implements stock nodemcu u8g.disp API
Disp.setFontRefHeightExtendedText = function(self)
  assert(self ~= nil)
end
--- Disp.setDefaultForegroundColor implements stock nodemcu u8g.disp API
Disp.setDefaultForegroundColor = function(self)
  assert(self ~= nil)
end
--- Disp.setFontPosTop implements stock nodemcu u8g.disp API
Disp.setFontPosTop = function(self)
  assert(self ~= nil)
end
--- Disp.drawFrame implements stock nodemcu u8g.disp API
Disp.drawFrame = function(self, x1, y1, x2, y2)
  assert(self ~= nil)
  print("frame: " .. x1 .. "/" .. y1 .. " - " .. x2 .. "/" .. y2)
end
--- Disp.drawStr implements stock nodemcu u8g.disp API
Disp.drawStr = function(self, x, y, str)
  assert(self ~= nil)
  print("[" .. x .. "/" .. y .. "] " .. str)
end
--- Disp.firstPage implements stock nodemcu u8g.disp API
Disp.firstPage = function(self)
  assert(self ~= nil)
  self.page = 1
end
--- Disp.nextPage implements stock nodemcu u8g.disp API
Disp.nextPage = function(self)
  self.page = self.page + 1
  return self.page == 3
end

--- u8g.ssd1306_128x64_i2c is stock nodemcu API
---@param slaAddress integer
---@return u8g_disp
u8g.ssd1306_128x64_i2c = function(slaAddress)
  assert(slaAddress ~= nil)
  return Disp.new()
end

return u8g
