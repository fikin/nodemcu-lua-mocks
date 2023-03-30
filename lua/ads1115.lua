--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]
local nodemcu        = require("nodemcu-module")

---ads1115 module
---@class ads1115
ads1115              = {}
ads1115.__index      = ads1115

--***************************************************************************
-- CHIP
--***************************************************************************
ads1115.ADS1015      = 15
ads1115.ADS1115      = 115

--***************************************************************************
-- I2C ADDRESS DEFINITON
--***************************************************************************

ads1115.ADDR_GND     = 0x48
ads1115.ADDR_VDD     = 0x49
ads1115.ADDR_SDA     = 0x4A
ads1115.ADDR_SCL     = 0x4B

--***************************************************************************
-- CONFIG REGISTER
--***************************************************************************

ads1115.DIFF_0_1     = 0x0000 -- Differential P = AIN0, N = AIN1 (default)
ads1115.DIFF_0_3     = 0x1000 -- Differential P = AIN0, N = AIN3
ads1115.DIFF_1_3     = 0x2000 -- Differential P = AIN1, N = AIN3
ads1115.DIFF_2_3     = 0x3000 -- Differential P = AIN2, N = AIN3
ads1115.SINGLE_0     = 0x4000 -- Single-ended AIN0
ads1115.SINGLE_1     = 0x5000 -- Single-ended AIN1
ads1115.SINGLE_2     = 0x6000 -- Single-ended AIN2
ads1115.SINGLE_3     = 0x7000 -- Single-ended AIN3

ads1115.GAIN_6_144V  = 0x0000 -- +/-6.144V range = Gain 2/3
ads1115.GAIN_4_096V  = 0x0200 -- +/-4.096V range = Gain 1
ads1115.GAIN_2_048V  = 0x0400 -- +/-2.048V range = Gain 2 (default)
ads1115.GAIN_1_024V  = 0x0600 -- +/-1.024V range = Gain 4
ads1115.GAIN_0_512V  = 0x0800 -- +/-0.512V range = Gain 8
ads1115.GAIN_0_256V  = 0x0A00 -- +/-0.256V range = Gain 16

ads1115.CONTINUOUS   = 0x0000 -- Continuous conversion mode
ads1115.SINGLE_SHOT  = 0x0100 -- Power-down single-shot mode (default)

ads1115.DR_8SPS      = 8
ads1115.DR_16SPS     = 16
ads1115.DR_32SPS     = 32
ads1115.DR_64SPS     = 64
ads1115.DR_128SPS    = 128
ads1115.DR_250SPS    = 250
ads1115.DR_475SPS    = 475
ads1115.DR_490SPS    = 490
ads1115.DR_860SPS    = 860
ads1115.DR_920SPS    = 920
ads1115.DR_1600SPS   = 1600
ads1115.DR_2400SPS   = 2400
ads1115.DR_3300SPS   = 3300

ads1115.CMODE_TRAD   = 0x0000 -- Traditional comparator with hysteresis (default)
ads1115.CMODE_WINDOW = 0x0010 -- Window comparator

ads1115.CONV_RDY_1   = 0x0000 -- Assert ALERT/RDY after one conversions
ads1115.CONV_RDY_2   = 0x0001 -- Assert ALERT/RDY after two conversions
ads1115.CONV_RDY_4   = 0x0002 -- Assert ALERT/RDY after four conversions

ads1115.COMP_1CONV   = 0x0000
ads1115.COMP_2CONV   = 0x0001
ads1115.COMP_4CONV   = 0x0002

---@class ads1115_instance
local adsInst        = {
  ---@type string
  i2c_addr = nil,
  ---@type string
  model = nil,
  ---@type number
  volt = nil,
  ---@type integer|nil
  volt_dec = nil,
  ---@type integer
  raw = nil,
  ---@type integer|nil
  sign = nil,
  ---@type integer|nil
  GAIN = nil,
  ---@type integer|nil
  SAMPLES = nil,
  ---@type integer|nil
  CHANNEL = nil,
  ---@type integer|nil
  MODE = nil,
  ---@type integer|nil
  CONVERSION_RDY = nil,
  ---@type integer|nil
  COMPARATOR = nil,
  ---@type integer|nil
  THRESHOLD_LOW = nil,
  ---@type integer|nil
  THRESHOLD_HI = nil,
  ---@type integer|nil
  COMP_MODE = nil,
}
adsInst.__index      = adsInst

---stock API
---@param self ads1115_instance
---@return number volt
---@return integer|nil volt_dec
---@return integer raw
---@return integer|nil sign
adsInst.read         = function(self)
  return self.volt, self.volt_dec, self.raw, self.sign
end

---stock API
---@param self ads1115_instance
---@param GAIN integer
---@param SAMPLES integer
---@param CHANNEL integer
---@param MODE integer
---@param CONVERSION_RDY integer|nil
---@param COMPARATOR integer|nil
---@param THRESHOLD_LOW integer|nil
---@param THRESHOLD_HI integer|nil
---@param COMP_MODE integer|nil
adsInst.setting      = function(self, GAIN, SAMPLES, CHANNEL, MODE, CONVERSION_RDY, COMPARATOR, THRESHOLD_LOW,
                                THRESHOLD_HI,
                                COMP_MODE)
  self.GAIN = GAIN
  self.SAMPLES = SAMPLES
  self.CHANNEL = CHANNEL
  self.MODE = MODE
  self.CONVERSION_RDY = CONVERSION_RDY
  self.COMPARATOR = COMPARATOR
  self.THRESHOLD_LOW = THRESHOLD_LOW
  self.THRESHOLD_HI = THRESHOLD_HI
  self.COMP_MODE = COMP_MODE
end

---stock API
---@param I2C_ID integer always 0
---@param I2C_ADDR integer
---@return ads1115_instance
ads1115.ads1115      = function(I2C_ID, I2C_ADDR)
  local o = {
    i2c_addr = I2C_ADDR,
    model = "1115",
  }
  return setmetatable(o, adsInst)
end

---stock API
---@param I2C_ID integer always 0
---@param I2C_ADDR integer
---@return ads1115_instance
ads1115.ads1015      = function(I2C_ID, I2C_ADDR)
  local o = {
    i2c_addr = I2C_ADDR,
    model = "1015",
  }
  return setmetatable(o, adsInst)
end

---stock API
ads1115.reset        = function()
  -- TODO
end

---stock API
---@param channel integer must be 0
---@return integer value from cb. If cb is not assigned, returns fixed 1024.
ads1115.read         = function(channel)
  assert(channel == 0, "expects adc channel to be 0 but found " .. tostring(channel))
  return nodemcu.adc_read_cb()
end

return ads1115
