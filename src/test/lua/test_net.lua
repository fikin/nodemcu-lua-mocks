--[[
License : GLPv3, see LICENCE in root of repository

Authors : Nikolay Fiykov, v1
--]]

luaunit = require('luaunit')

require('net')

function testInputArrayFnc()
  net.TestData.reset()
  local f = net.TestData.inputArrayFnc({ '1', '2', '3' }, false)
  luaunit.assertEquals( f(), '1' )
  luaunit.assertEquals( f(), '2' )
  luaunit.assertEquals( f(), '3' )
  luaunit.assertIsNil( f() )
end

function testInputArrayCycleFnc()
  net.TestData.reset()
  local f = net.TestData.inputArrayFnc({ '1', '2', '3' }, true)
  luaunit.assertEquals( f(), '1' )
  luaunit.assertEquals( f(), '2' )
  luaunit.assertEquals( f(), '3' )
  luaunit.assertEquals( f(), '1' )
  luaunit.assertEquals( f(), '2' )
end

function testCollectDataFnc()
  net.TestData.reset()
  local f = net.TestData.collectDataFnc
  luaunit.assertIsNil( net.TestData.collected )
  f('1')
  f('2')
  luaunit.assertNotIsNil( net.TestData.collected )
  luaunit.assertEquals( net.TestData.collected, { '1', '2' } )
end

function testConnectionSend()
  net.TestData.reset()

  local sentCbWasCalled = 0
  local pipedByConnection = {}
  local con = Connection.new( 4444, '192.168.255.1', 
    nil, 
    function(data) pipedByConnection[table.getn(pipedByConnection) + 1] = data end 
  )
  con.TestData.wasOpened = true
  con:on('sent', function(sck) sentCbWasCalled = sentCbWasCalled + 1 end)

  con:send('1')
  Timer.joinAll(5)
  con:send('2')
  Timer.joinAll(5)

  luaunit.assertEquals(sentCbWasCalled, 2)
  luaunit.assertEquals(pipedByConnection, { '1', '2' })
end

function testConnectionInputPipeCoroutine()
  net.TestData.reset()

  local inputData = { '1', '2' }
  local receivedData = {}
  local con = Connection.new( 4444, '192.168.255.1', 
    function()
      if table.getn(receivedData) < table.getn(inputData) then 
        return inputData[table.getn(receivedData) + 1]
      else
        return nil
      end 
    end, 
    nil 
  )
  con.TestData.wasOpened = true
  con:on('receive', function(sck, data) receivedData[ table.getn(receivedData) + 1 ] = data end)

  local coro = Connection.TestData.createInputPipeCoroutine(con)

  coroutine.resume(coro)
  coroutine.resume(coro)
  coroutine.resume(coro)
  con.TestData.wasClosed = true
  coroutine.resume(coro)

  luaunit.assertEquals(receivedData, { '1', '2' })
end

function testConnectionInputPipeTimer()
  net.TestData.reset()

  local inputData = { '1', '2' }
  local receivedData = {}
  local con = Connection.new( 4444, '192.168.255.1', 
    function()
      if table.getn(receivedData) < table.getn(inputData) then 
        return inputData[table.getn(receivedData) + 1]
      else
        return nil
      end 
    end, 
    nil 
  )
  con.TestData.wasOpened = true
  con:on('receive', function(sck, data) receivedData[ table.getn(receivedData) + 1 ] = data end)

  local timer = Connection.TestData.createInputPipeTimer(con)
  timer:start()

  Timer.joinAll(3)
  con.TestData.wasClosed = true
  Timer.joinAll(3)

  luaunit.assertEquals(receivedData, { '1', '2' })
end

function testConnectionConnect()
  net.TestData.reset()

  local connectionWasCalled = false
  local disconnectionWasCalled = false
  local inputData = { '1', '2' }
  local receivedData = {}
  local con = Connection.new( 4444, '192.168.255.1',
    function()
      if table.getn(receivedData) < table.getn(inputData) then 
        return inputData[table.getn(receivedData) + 1]
      else
        return nil
      end 
    end, 
    nil 
  )
  con:on('connection', function(sck) connectionWasCalled = true end)
  con:on('receive', function(sck, data) receivedData[ table.getn(receivedData) + 1 ] = data end)
  con:on('disconnection', function(sck) disconnectionWasCalled = true end)

  con:connect(1111, '22.22.22.22')
  Timer.joinAll(3)
  con:close()
  Timer.joinAll(3)

  luaunit.assertTrue( connectionWasCalled )
  luaunit.assertTrue( disconnectionWasCalled )
  luaunit.assertEquals(receivedData, { '1', '2' })
--  luaunit.assertEquals(con.localIp, '192.168.255.1')
--  luaunit.assertEquals(con.localPort, 4444)
--  luaunit.assertEquals(con.remoteIp, '22.22.22.22')
--  luaunit.assertEquals(con.remotePort, 1111)
  local p, i = con:getaddr()
  luaunit.assertEquals(i, '192.168.255.1')
  luaunit.assertEquals(p, 4444)
  local p, i = con:getpeer()
  luaunit.assertEquals(i, '22.22.22.22')
  luaunit.assertEquals(p, 1111)
end

function testConnectionTimeoutTrigger()
  net.TestData.reset()

  Connection.TestData.WATCHDOG_PERIOD_MS = 1
  local con = Connection.new( '192.168.255.1', 4444, function() return nil end, function(data) end )
  con:enableTimeoutWatchdog( 1 )
  local wasClosed = false
  con:on('disconnection', function(sck) wasClosed = true end)
  con:connect(5555, '192.168.255.2')
  Timer.joinAll(3)
  luaunit.assertTrue(wasClosed)
end

function testConnectionTimeoutNotTrigger()
  net.TestData.reset()

  Connection.TestData.WATCHDOG_PERIOD_MS = 1
  local con = Connection.new( '192.168.255.1', 4444, function() return nil end, function(data) end )
  con:enableTimeoutWatchdog( 1 )
  local wasClosed = false
  con:on('disconnection', function(sck) wasClosed = true end)
  con:connect(5555, '192.168.255.2')
  Timer.joinAll(1)
  con:send('aa')
  Timer.joinAll(1)
  con:send('aa')
  Timer.joinAll(1)
  luaunit.assertTrue(wasClosed)
end

function testConnectionReceiveDataChunking()
  net.TestData.reset()

  local receivedData = {}
  Connection.TestData.CHUNK_SIZE = 1
  local con = Connection.new( 4444, '192.168.255.1',
    net.TestData.inputArrayFnc({'12','34'}, false), 
    nil 
  )
  con:on('receive', function(sck, data) receivedData[ table.getn(receivedData) + 1 ] = data end)

  con:connect(1111, '22.22.22.22')
  Timer.joinAll(3)
  con:close()
  Timer.joinAll(3)

  luaunit.assertEquals(receivedData, { '1', '2', '3', '4' })
end

function testTcpListener()
  net.TestData.reset()

  local connectionReceived = false
  local onIncomingConnection = function(con)
    luaunit.assertNotIsNil(con)
    connectionReceived = true
  end

  local listener = TcpListener.new(1000000)
  listener:listen(11, '192.168.255.2', onIncomingConnection)

  local p, i = listener:getaddr()
  luaunit.assertEquals(i, '192.168.255.2')
  luaunit.assertEquals(p, 11)

  TcpListener.TestData.receiveIncomingConnection(listener, 44, '33.33.33.33', nil, nil)
  luaunit.assertTrue(connectionReceived)
end

function testTcpServer()
  net.TestData.reset()

  local con = nil
  local onIncomingConnection = function(con1)
    luaunit.assertNotIsNil(con1)
    con = con1
    local ready = false
    con:on('receive', function(sck,data) 
      sck:send('1-'..data)
      ready = data == '34'
    end)
    con:on('sent', function(sck)
      if ready then sck:close() end
    end)
  end

  local srv = net.createServer(net.TCP, 1)

  srv:listen(11, '192.168.255.2', onIncomingConnection)

  TcpListener.TestData.receiveIncomingConnection(srv, 44, '33.33.33.33', 
    net.TestData.inputArrayFnc({'12','34'}, false),
    net.TestData.collectDataFnc
  )
  
  Timer.joinAll(10)

  luaunit.assertNotIsNil(con)
  luaunit.assertTrue(con.TestData.wasClosed)
  luaunit.assertEquals(net.TestData.collected, { '1-12', '1-34' })
end



os.exit( luaunit.LuaUnit.run() )
