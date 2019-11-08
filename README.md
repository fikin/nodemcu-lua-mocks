# nodemcu-lua-mocks

A [NodeMCU Lua API](https://nodemcu.readthedocs.io/en/master/en/) mocks used for unit testing.

I use this library to unit test my NodeMCU lua projects.

At beginning I was mockinng method signatures only, just to get a dummy execution pass ok. But now the implementation is sufficient enough to actually simulate NodeMCU functionality. For example tmr is fully emulated, including quirks like tmr.now() 31-bit cycle-over. Wifi is also simulated enough to fake AP connection/disconnection events. And net.TCP server too, including thinks like data chunking for TCP frame sizes.
Now I can unit test a production ready init.lua as done in my [other project](https://github.com/fikin/humidifier).

Basically all interfaces are implemented ... Just kidding ... My suggestion is to check the code at src/main/lua for clear view what is working and how. For rest, contributions are much appreciated.

## Examples

Use example :

```lua
local lu = require('luaunit')
local nodemcu = require('nodemcu')

function testTrigger()
  nodemcu.reset()
  local calls = ""
  gpio.trig(1,"both",function(level, time)
    calls = calls .. tostring(level)
  end)
  nodemcu.gpio_set(1, gpio.LOW)
  nodemcu.gpio_set(1, gpio.HIGH)
  lu.assertEquals(calls, "01")
end

os.exit(lu.run())
```

Or another example with tmr:

```lua
local lu = require('luaunit')
local nodemcu = require('nodemcu')

function testDynamicTimer()
  nodemcu.reset()
  local fncCalled = 0
  local t = tmr.create()
  t:register( 1, tmr.ALARM_SINGLE, function(timerObj)
    fncCalled = 1
    timerObj:unregister()
  end)
  lu.assertTrue( t:start() )
  nodemcu.advanceTime(100)
  lu.assertEquals(fncCalled,1)
end

os.exit(lu.run())
```

For complete set of ideas how to unit test with NodeMCU API, check existing tests in folder tests/. They give fairly good idea what can be done and how.

## Installation

Add *lua* directory to your LUA_PATH.

## Usage

Import NodeMCU and make sure before each individual test to reset its state:

```lua
local nodemcu = require("nodemcu")
...
nodemcu.reset()
...
```

When external input is required, like *wifi*, *net* connections and data, *gpio* and *adc* read data, use *nodemcu* methods to do that. For example:

```lua
local nodemcu = require("nodemcu")
...
-- assign callback to provide input to adc.read
nodemcu.adc_read_cb = function() return 55 end
...
-- simulate high-signal arrives to pin 1
gpio.mode(1, gpio.INPUT)
nodemcu.gpio_set(1,gpio.HIGH)
-- or use sequence for single values
nodemcu.gpio_set(1,someSequenceFunc)
...
-- capture writes to some gpio pin
gpio.mode(1, gpio.OUTPUT)
nodemcu.gpio_capture(1,function(pin,val) assert(pin==1) assert(val==gpio.HIGH) end)
gpio.write(1, gpio.HIGH)
...
```

### Assistance methods

Inspect *nodemcu-module* methods to understand what *nodemcu* supports.

### tmr, Timer and on timing in general

NodeMCU API is exclusively designed on asynchronous, event driven processing using callbacks.

This requires some sort of time management, where time before and after an event is properly tracked. And because there is no native thread model in Lua, I've opted of modeling time exclusively. In other words:

* there is an internal Timer object which keeps track of scheduled activities
* time of this Timer advances manually i.e. one has to call *nodemcu.advanceTime(ms)*

So, basic use pattern is folloqing :

* create timer like tmr.create(2,...):start() which created a timer event after 2ms.
* call nodemcu.advanceTime(1) and the timer will advance with 1ms i.e. no timer event will be fired yet.
* call nodemcu.advanceTime(2) and the timer event will be fired.

tmr module is supported, static and dynamic timers included.

tmr.now() is simluated, including 31-bit rollover.

### wifi

Wifi is mostly simulated.

One can assign callbacks to act on *sta* and *ap* configure calls using *nodemcu.wifiSTAsetConfigFnc* and *nodemcu.wifiAPsetConfigFnc*. These callbacks decide not only on wifi configure response but also provide with IP and other configuration. See *nodemcu-module* for more details.

wifi.sta.config autoconnect is supported.

### net

Presently TCP server is implemented. I gather UDP can be done too but I haven't had the need yet.

Faking new connection to some listener happend via TcpListener.TestData.receiveIncomingConnection(...) which expects calbacks called to provide with remote's host sent data and sink callbacks for the data sent back to it.
For convenience, there are :

* net.TestData.inputArrayFnc(...) used to serve to the connection an array of strings
* net.TestData.collectDataFnc(...) used to collect all sent data into net.TestData.collected field. These two might have to change in future as they are not multi-connection friendly design.

### gpio

gpio triggers are supported, or I hope so.

All *gpio.write(pin,val)* can be captured to user function via *nodemcu.gpio_capture(pin,function(pin,val)void)*.

All external input to pins can be provided via *nodemcu.gpio_set(pin,val)* or *nodemcu.gpio_set(pin,cb)*. This method also triggers gpio pin triggers.

### adc, dht

Similar to gpio in use pattern.

### u8g

This is dummy at the moment and I have zero ideas how to simulate it. But I'd love to have someting meaningfull, any suggestion is most welcome.

### sjson, mdns and rest

sjson is simulated, I guess ok. Rest is either simulated or plain does nothing.

## Building and deploying

```shell
git clone https://github.com/fikin/nodemcu-lua-mocks.git
make clean test dist
export LUA_PATH=$(pwd)/lua/?.lua
```

## License

GPLv3, see LICENSE file
Contributions :

* src/contrib/lua/JSON.lua, see its header.
* [luaunit](https://github.com/bluebird75/luaunit), see library's own details
