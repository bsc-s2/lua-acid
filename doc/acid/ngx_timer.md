<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
#   Table of Content

- [Name](#name)
- [Status](#status)
- [Description](#description)
- [Synopsis](#synopsis)
- [Methods](#methods)
  - [ngx_timer.at](#ngx_timerat)
  - [ngx_timer.every](#ngx_timerevery)
- [Author](#author)
- [Copyright and License](#copyright-and-license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

#   Name

acid.ngx_timer

#   Status

This library is considered production ready.

#   Description

This module provides simple wrapper of `ngx.timer.at`, so you
do not need to define the timer callback function.

#   Synopsis

```lua
local ngx_timer = require('acid.ngx_timer')

local do_sum = function(a, b)
    ngx.log(ngx.INFO, 'sum is: ' .. tostring(a + b))
end

local _, err, errmsg = ngx_timer.at(0.1, do_sum, 1, 2)
if err ~= nil then
    ngx.log(ngx.ERR, string.format(
            'failed to setup timer: %s, %s', err, errmsg))
end

local _, err, errmsg = ngx_timer.every(0.5, do_sum, 1, 2)
if err ~= nil then
    ngx.log(ngx.ERR, string.format(
            'failed to setup timer: %s, %s', err, errmsg))
end
```

#   Methods

##   ngx_timer.at

**syntax**:
`_, err, errmsg = ngx_timer.at(delay, func, ...)`

Setup a timer, which will run `func` with all following arguments
at `delay` seconds later. When the nginx worker is trying to shut
down, the `func` will be executed even the specified delay time
has not expired.

**arguments**:

-   `delay`:
    specifies the delay for the timer, in seconds.
    You can specify fractional seconds like `0.001`.

**return**:
If failed to setup the timer, `nil` is returned, following error code
and error message.

##   ngx_timer.every

**syntax**:
`_, err, errmsg = ngx_timer.every(interval, func, ...)`

Setup a timer, which will run `func` with all following arguments
every `interval` seconds.

**arguments**:

-   `interval`:
    specifies the loop interval, in seconds.
    You can specify fractional seconds like `0.001`.

**return**:
If failed to setup the timer, `nil` is returned, following error code
and error message.

#   Author

Renzhi (任稚) <zhi.ren@baishancloud.com>

#   Copyright and License

The MIT License (MIT)

Copyright (c) 2015 Renzhi (任稚) <zhi.ren@baishancloud.com>
