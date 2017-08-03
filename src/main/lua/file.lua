--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]

file = {}
file.__index = file

file.TestData = {}
file.TestData.reset = function()
  file.TestData._fd = nil
  file.TestData._in = nil
end
file.TestData.reset()

file.open = function(name)
  file.TestData._fd = io.open(name)
  if not file.TestData._fd then return false; end
  file.TestData._in = io.input(file.TestData._fd)
  return true
end

file.exists = function(loc)
  local f = io.open(loc,"r")
  if f~=nil then 
    io.close(f) 
    return true 
  else 
    return false 
  end
end

file.close = function()
  if file.TestData._fd then
    io.close(file.TestData._fd)
    file.TestData._fd = nil
    file.TestData._in = nil
  end
end

file.read = function(delim)
  if file.TestData._in then
    return file.TestData._in:read("*line")
  else
    return nil
  end
end

return file