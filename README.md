# nodemcu-lua-mocks

<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [nodemcu-lua-mocks](#nodemcu-lua-mocks)
  - [Introduction](#introduction)
  - [Currently supported modules](#currently-supported-modules)
  - [Examples](#examples)
  - [Installation](#installation)
  - [Usage](#usage)
    - [Overall test setup](#overall-test-setup)
    - [External input](#external-input)
    - [Emulating real NodeMCU device](#emulating-real-nodemcu-device)
    - [On testing tmr, Timer and on timing in general](#on-testing-tmr-timer-and-on-timing-in-general)
    - [On using wifi](#on-using-wifi)
    - [On using net](#on-using-net)
    - [On using gpio](#on-using-gpio)
    - [On using rest of modules](#on-using-rest-of-modules)
    - [u8g](#u8g)
  - [Building and deploying](#building-and-deploying)
  - [License](#license)

<!-- /code_chunk_output -->

## Introduction

A [NodeMCU Lua API](https://nodemcu.readthedocs.io/en/master/en/) mocks used for unit testing.

I use this library to unit test my NodeMCU lua projects. And lately I started using it for integration testing as well. For example see [NodeMCU Device](https://github.com/fikin/nodemcu-device) project.

Implementation now is sufficient enough to actually simulate NodeMCU functionality. 
For example `tmr` is fully emulated, including quirks like `tmr.now()` 31-bit cycle-over. `Wifi` is also simulated enough to fake AP connection/disconnection events. And `net.TCP` server too, including thinks like data chunking for TCP frame sizes. Even `node` input and output are simulated.

Basically all interfaces are implemented ... Just kidding ... My suggestion is to check the code at src/main/lua for clear view what is working and how. For rest, contributions are much appreciated.

Source code is annotated using [LuaLS](https://github.com/LuaLS/lua-language-server/wiki/Annotations), most of the data structures are abstracted as classes. One can refer to these in production code in oder to benefit from code assistance.

## Currently supported modules

adc, bit, crypto, dht, encoder, enduser_setup, file, gpio, i2c, mdns, net, node, ow, pwm, rotary, rtcmem, rtctime, sjson, sntp, tmr, u8g2, u8g, wifi

## Examples

Stereotypical setup of a test file looks like:

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

Or another example with `tmr`:

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

For complete set of ideas how to unit test with NodeMCU API, check existing tests in folder `tests/`. They give fairly good idea what can be done and how. Another source of ready examples is [NodeMCU Device](https://github.com/fikin/nodemcu-device) project.

## Installation

Add `lua/?.lua` directory to your `LUA_PATH`.

In order to simplify the usage, all external dependencies are included in this repo as-is.

## Usage

Instructions in short, in order to unit/integration test using the library one has to:

- use `require("<module>")` in source and test code explicitly, even for built-in modules like `file`, `node` and etc.
- import `nodemcu` module in the test file, which emulates NodeMCU device itself.
- call `nodemcu.reset()` before each individual test.
- every time, where expecting some async operation to perform, like a timer to fire, io to send/receive data, node task to trigger, wifi callback to fire and similar, one has to advance the time inside the test manually by using `nodemcu.advanceTime(<ms>)`. This simulates time advance inside emulated NodeMCU device.
- all external input, from likes of `gpio`, `net`, `wifi` and similar, use respective `nodemcu` methods to simulate external events for those activities.

Everything else, more or less should be as-is when coding against the real NodeMCU devices.

### Overall test setup

Import NodeMCU and make sure before each individual test to reset its state:

```lua
local nodemcu = require("nodemcu")
...
-- before each test case
nodemcu.reset()
...
```

### External input

When external input is required, like `wifi`, `net`-connections and data, `gpio` and `adc` read data, use `nodemcu` methods to do that. For example:

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
gpio.write(1, gpio.HIGH) -- capture function will trigger and assert the value
...
```

### Emulating real NodeMCU device

All emulation code is located in `nodemcu-module`, inspect that to understand what kind of support methods there are available.

Main idea is that all external interactions are emulated via dedicated APIs.

### On testing tmr, Timer and on timing in general

NodeMCU API is exclusively designed on asynchronous, event driven processing using callbacks.

This requires some sort of time management, where time before and after an event is properly tracked. And because there is no native thread model in Lua, I've opted of modeling time exclusively. In other words:

- there is an internal `Timer` object which keeps track of scheduled activities
- time of this `Timer` advances manually i.e. one has to call `nodemcu.advanceTime(ms)`

So, basic use pattern is following :

- create timer like `tmr.create(2,...):start()` which created a timer event after 2ms.
- call `nodemcu.advanceTime(1)` and the timer will advance with 1ms i.e. no timer event will be fired yet.
- call `nodemcu.advanceTime(2)` and the timer event will be fired.

`tmr` module is supported, static and dynamic timers included.

`tmr.now()` is simulated, including 31-bit rollover.

### On using wifi

Wifi is mostly simulated and rest dummied.

`nodemcu-modules` exposes some data structures to capture wifi's state.
Event dispatching is also supported.

In past I had some methods to simulate wifi connect-disconnect sequence but in later updates I've removed them, as these were somewhat hard to work with. They can be brought back but we should find some simplifications first.

### On using net

Presently TCP server is implemented. I gather UDP can be done too but I haven't had the need yet.

Faking client connection from outside is done via `nodemcu.net_tpc_connect_to_listener` which returns a `socket` connected to some listener.

Sending data to the server connection happens via `socket.sentByRemote`. And accepting data from server happens via `socket.receivedByRemote`.

One can check the source code of `net-tcp-socket.lua` for methods documented to be used by unit tests to grasp the full picture.

### On using gpio

`gpio` triggers are supported, or I hope so.

All `gpio.write(pin,val)` can be captured to user function via `nodemcu.gpio_capture(pin,function(pin,val)void)`.

All external input to pins can be simulated via `nodemcu.gpio_set(pin,val)` or `nodemcu.gpio_set(pin,cb)`. This method also triggers gpio pin triggers.

### On using rest of modules

Best would be to inspect the source code of respective module to get the idea of what is mocked and how it behaves.

### u8g

This is dummy at the moment and I have zero ideas how to simulate it. But I'd love to have someting meaningfull, any suggestion is most welcome.

## Building and deploying

```shell
git clone https://github.com/fikin/nodemcu-lua-mocks.git
make test
export LUA_PATH=$(pwd)/lua/?.lua
```

## License

GPLv3, see LICENSE file
Contributions :

- src/contrib/lua/JSON.lua, see its header.
- src/contrib/lua/md5.lua, see its header.
- src/contrib/lua/sha2.lua, see its header.
- [luaunit](https://github.com/bluebird75/luaunit), see library's own details
