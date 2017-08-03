--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]

net = {}
net.__index = net

require('Timer')

net.TCP = 1
net.UDP = 2

Connection = {}
Connection.__index = Connection
Connection.TestData = {}

TcpListener = {}
TcpListener.__index = TcpListener

net.TestData = {}
net.TestData.reset = function()
  Timer.reset()
  net.TestData.listeners = {}
  net.TestData.collected = nil
  Connection.TestData.EVENT_DELAY = 1 -- time delay for firing any socket operation
  Connection.TestData.CHUNK_SIZE = 1460 -- network frame size
  Connection.TestData.WATCHDOG_PERIOD_MS = 1000 -- 1sec
end
net.TestData.reset()

Connection.new = function(localPort, localIp, inputDataCb, outputDataCb) 
  local o = {}
  setmetatable(o,Connection)
  o.localIp = localIp
  o.localPort = localPort
  o.TestData = { events = {}, output = nil, wasClosed = false, wasOpened = false, activityTs = 0 }
  o.TestData.inputDataCb = inputDataCb and inputDataCb or function() return nil end
  o.TestData.outputDataCb = outputDataCb and outputDataCb or function(data) end
  o.TestData.events['connection'] = function(self) end
  o.TestData.events['reconnection'] = function(self, errCode) end
  o.TestData.events['disconnection'] = function(self, errCode) end
  o.TestData.events['receive'] = function(self, data) end
  o.TestData.events['sent'] = function(self) end
  return o
end
Connection.getaddr = function(self) return self.localPort, self.localIp end
Connection.getpeer = function(self) return self.remotePort, self.remoteIp end
local function queueFnc(cb)
  Timer.createSingle(Connection.TestData.EVENT_DELAY,cb):start()
end
Connection.close = function(self) 
  if self.TestData.wasOpened and not self.TestData.wasClosed then
    queueFnc(function() 
      self.TestData.wasClosed = true
      self.TestData.events['disconnection'](self) 
    end)
  end
end
Connection.TestData.createInputPipeCoroutine = function(self)
  local function getFirstChunk(data)
    if string.len(data) <= Connection.TestData.CHUNK_SIZE then
      return data
    else
      return string.sub(data, 1, Connection.TestData.CHUNK_SIZE)
    end
  end
  local function getChunkTail(data)
    if string.len(data) > Connection.TestData.CHUNK_SIZE then
      return string.sub(data, Connection.TestData.CHUNK_SIZE + 1)
    else
      return nil
    end
  end
  return coroutine.create(function() 
    while not self.TestData.wasClosed do
      local data = self.TestData.inputDataCb()
      if data then
        while data do
          local chunk = getFirstChunk(data)
          self.TestData.events['receive'](self, chunk)
          data = getChunkTail(data)
          self.TestData.activityTs = Timer.getCurrentTimeMs()
          coroutine.yield()
        end
      else
        coroutine.yield() 
      end
    end
  end)
end
Connection.TestData.createInputPipeTimer = function(self)
  local coro = Connection.TestData.createInputPipeCoroutine(self)
  local timer = Timer.createReoccuring(Connection.TestData.EVENT_DELAY, function(timerObj)
    if coroutine.status(coro) == 'dead' then
      timerObj:stop()
    else 
      coroutine.resume(coro)
    end 
  end)
  return timer
end
Connection.connect = function(self, remotePort, remoteIp)
  assert(not self.TestData.wasClosed, 'Connection already closed.')
  assert(not self.TestData.wasOpened, 'Connection already connected.')
  self.remoteIp = remoteIp
  self.remotePort = remotePort
  queueFnc(function() 
    self.TestData.wasOpened = true 
    self.TestData.events['connection'](self)
    Connection.TestData.createInputPipeTimer(self):start()
  end)
end
Connection.on = function(self, event, cb)
  --print('AAA '..tostring(self)..' '..tostring(event)..' '..tostring(cb))
  self.TestData.events[event] = cb 
end
Connection.send = function(self, data, callback)
  --print('net send: self='..tostring(self)..' data='..tostring(data)..' callback='..tostring(callback))
  assert(not self.TestData.wasClosed, 'Connection already closed.')
  assert(self.TestData.wasOpened, 'Connection not connected.')
  self.TestData.activityTs = Timer.getCurrentTimeMs()
  if callback then
    self:on("sent", callback)
  end
  queueFnc(function()  
    self.TestData.outputDataCb( data ) 
    self.TestData.events['sent'](self)
  end)
end
Connection.enableTimeoutWatchdog = function(self, timeoutMs)
  Timer.createReoccuring(Connection.TestData.WATCHDOG_PERIOD_MS,function(timerObj) 
    if self.TestData.wasOpened and Timer.hasDelayElapsedSince(Timer.getCurrentTimeMs(),self.TestData.activityTs,timeoutMs) then
      self:close()
    end
    if self.TestData.wasClosed then timerObj:stop() end
  end):start()
end

TcpListener.new = function(timeoutMs)
  local o = {}
  setmetatable(o, TcpListener)
  o.timeoutMs = timeoutMs
  return o
end
TcpListener.close = function(self) end
TcpListener.listen = function(self, port, ip, cb)
  if type(port) == 'string' then
    cb = ip
    ip = port
    port = math.random() * 10000
  end
  if type(ip) == 'function' then
    cb = ip
    ip = '0.0.0.0'
  end
  self.port = port
  self.ip = ip
  self.cb = cb
  assert( net.TestData.listeners[port] == nil, 'Port '..port..' already used by another listener.' )
  net.TestData.listeners[port] = self
end
TcpListener.getaddr = function(self)
  return self.port, self.ip
end
TcpListener.TestData = {}
TcpListener.TestData.receiveIncomingConnection = function(self, remotePort, remoteIp, inputDataCb, outputDataCb)
  local con = Connection.new( self.port, self.ip, inputDataCb, outputDataCb )
  con:enableTimeoutWatchdog( self.timeoutMs )
  self.cb(con)
  con:connect(remotePort, remoteIp)
end

net.createServer = function(type, timeoutSec)
  if not timeoutSec then
    timeoutSec = 30
  end
  if type == net.TCP then
    return TcpListener.new(timeoutSec  * 1000) -- ms format
  else
    error('FIXME : implement udp server')
  end
end

net.TestData.inputArrayFnc = function(arr, recycleArray)
  local index = 0
  local function nextPayload(timerObj)
    if index >= table.getn(arr) then
      if recycleArray then
        index = 0
      else
        return
      end
    end
    index = index + 1
    return arr[index]
  end
  return nextPayload
end
net.TestData.collectDataFnc = function(data)
  if not net.TestData.collected then
    net.TestData.collected = {}
  end
  net.TestData.collected[ table.getn(net.TestData.collected) + 1 ] = data
end
net.TestData.receiveIncommingConnection = function(onPort, remoteIp, remotePort, inputDataCb, outputDataCb)
  local listener = net.TestData.listeners[port]
  assert(listener ~= nil, 'Test data sent to not existing port listener.')
  listener.TestData.receiveIncomingConnection(remoteIp, remotePort, inputDataCb, outputDataCb)
end

return net
