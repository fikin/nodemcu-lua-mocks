# nodemcu-lua-mocks
A [NodeMCU Lua API](https://nodemcu.readthedocs.io/en/master/en/) mocks used for unit testing.

I use this library to unit test my NodeMCU lua projects.

At beginning I was mockinng method signatures only, just to get a dummy execution pass ok. But now the implementation is sufficient enough to actually simulate NodeMCU functionality. For example tmr is fully emulated, including quirks like tmr.now() 31-bit cycle-over. Wifi is also simulated enough to fake AP connection/disconnection events. And net.TCP server too, including thinks like data chunking for TCP frame sizes.
I unit test a production ready init.lua as done in my [other project](https://github.com/fikin/humidifier).

Basically all interfaces are implemented ... Just kidding ... My suggestion is to check the code at src/main/lua for clear view what is working and how. For rest, contributions are much appreciated.

## Examples
Use example :
```lua
luaunit = require('luaunit')

require('gpio')

function testTrigger()
  gpio.TestData.reset()
  local callCnt = 0
  gpio.trig(1,"both",function(level, time)
    callCnt = callCnt + 1 
  end)
  gpio.TestData.setLow(1)
  gpio.TestData.setHigh(1)
  luaunit.assertEquals(callCnt,2)
end

os.exit( luaunit.LuaUnit.run() )
```

Or another example with tmr:
```lua
luaunit = require('luaunit')

require('tmr')

function testDynamicTimer()
  tmr.TestData.reset()
  local fncCalled = 0
  local t = tmr.create()
  t:register( 1, tmr.ALARM_SINGLE, function(timerObj)
    fncCalled = 1
    timerObj:unregister()
  end)
  luaunit.assertTrue( t:start() )
  Timer.joinAll(100)
  luaunit.assertEquals(fncCalled,1)
end

os.exit( luaunit.LuaUnit.run() )
```

For complete set of ideas how to unit test with NodeMCU API, check existing tests in src/test/lua. They give fairly good idea what can be done and how.

## Usage
Any of the NodeMCU modules must be implicitly imported in your unit tests using require('modulename').

If you create multiple tests (functions) inside single lua test file, make sure before each one to call <module>.TestData.reset() to reset its internal state before the test.
*Note* that dependent modules are not automatically reset i.e. net requires tmr, so in your test you'd have to require both of them and reset them explicitly. Missing require can be easily spotted, unit test execution will complain, but missing TestData.reset() can be devastating and will take a lot of troubleshooting effort on your part.

Modules which require external input, like net connections and data, gpio and adc read data, typically have convenience methods in module.TestData.xyz which can be used in the unit test. This is the way to provide decisions for wifi, net, gpio, adc, dht modules to name few.

### TestData object
TestData object is added to all modules to :
* contain working data from the interfaces, like collect data to inspect later
* constants which impact internal behavior, like timeout settings and various callbacks
* a data convenience methods, used to feed data into the module. For example gpio.TestData.setLow(pin) or wifi.TestData.sta.onConfigureCb(cfg). 
* a "reset()" function, which is rather needed when developing multiple tests in single lua file. For that see below.

Basically TestData object is ok to use in unit tests and *never* in your production code. Strive for that pattern.

### tmr, Timer and on timing in general
Lua doesn't have genuine threading support, I include coroutines here. And present NodeMCU is exclusively designed on asynchronous, event driven mode where all data is done via callbacks. So far NodeNCU is not interrupt driven.
This posed a particularly difficult challenge how to simulate it, without doing too stupid thinks or deviating too far from what esp SDK is doing.

I've opted to model all timing aspects via Timer object. This is a list of time definitions, with single controll loop to advance the time via Timer.joinAll(joinTimeMs).
Basic pattern is that once Timer object is created, once started it is added to the list of active definitions and Timer.joinAll() will advance its time.

So, basic use pattern is folloqing :
* create timer like tmr.create(2,...):start() which created a timer event after 2ms.
* call Timer.joinAll(1) and the timer will advance with 1ms i.e. no timer event will be fired yet.
* call Timer.joinAll(2) and the timer event will be fired.

tmr module is supported, static and dynamic timers included.

tmr.now() is simluated, including 31-bit rollover.

### wifi
Wifi is simulated mostly via callbacks.

Generally config save option is not supported. I suppose I consider it harmfull for the code. For example upon reboot esp wifi will try to reconnect but nodemcu callbacks are gone. And init.lua will be executed anyway. So, lately I've stopped saving it and opted for complete re-initialization logic in init.lua code.

wifi.sta.config autoconnect is supported.

Enablin STA and AP happend via providing callbacks returning true for wifi.TestData.sta/ap.onConfigureCb(cfg).

Additionally sta model offers boolean onConnectCb() to simulate wifi connect error aka wrong credentials.
And onGetIp() to provide with own set of values for ip, netmask and gateway.

### net
Presently TCP server is implemented. I gather UDP can be done too but I haven't had the need yet.

Faking new connection to some listener happend via TcpListener.TestData.receiveIncomingConnection(...) which expects calbacks called to provide with remote's host sent data and sink callbacks for the data sent back to it.
For convenience, there are :
* net.TestData.inputArrayFnc(...) used to serve to the connection an array of strings
* net.TestData.collectDataFnc(...) used to collect all sent data into net.TestData.collected field. These two might have to change in future as they are not multi-connection friendly design.

### gpio
gpio triggers are supported, or I hope so.

All gpio.write(pin,val) are stored in an array and offered back via gpio.read(pin).
*Note* that write does not trigger events.
In order to trigger events, one has to set values via gpio.TestData.setLow/setHigh(pin) methods.

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
```
Dist will place all files to be included in other projects under target/dist folder. Just copy it or include it in LUA_PATH.

To run compile target, required is :
* Lua engine in PATH
* make or if one mimics its commands, only shell
* git to clone external source code (luaunit). This one can provide manualy too.

Test and dist are dependent on compile.

External library used is [luaunit](https://github.com/bluebird75/luaunit), which is git cloned (https interface) as part of default make target (all, compile). If you're behind proxy, make sure to set http(s)_proxy env vars.

Source and build folders structure is modeled after maven principles i.e. target/ contains all working code and src/ contains actual sources.

## License
GPLv3, see LICENSE file
Contributions :
* src/contrib/lua/JSON.lua, see its header.
* [luaunit](https://github.com/bluebird75/luaunit), see library's own details
