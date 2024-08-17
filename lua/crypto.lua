--[[
License : GPLv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]

---adc module
---@class crypto
crypto = {}
crypto.__index = crypto

---stock API
---@param algo string
---@param str string
---@return string
crypto.hash = function(algo, str)
  algo = string.lower(algo)
  if algo == "md5" then
    return require("md5").new():update(str):finish()
  else
    local sha2 = require("sha2")
    if algo == "sha1" then
      return sha2.sha1(str)
    elseif algo == "sha256" then
      return sha2.sha256(str)
    elseif algo == "sha384" then
      return sha2.sha384(str)
    elseif algo == "sha512" then
      return sha2.sha512(str)
    else
      error("unsupported algorithm " .. algo)
    end
  end
end

---stock API
---@param algo crypto_alg
---@param loc string
---@return string
crypto.fhash = function(algo, loc)
  local str = require("file").getcontents(loc) or ""
  return crypto.hash(algo, str)
end

return crypto
