<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
#   Table of Content

- [Name](#name)
- [Status](#status)
- [Description](#description)
- [Synopsis](#synopsis)
- [Methods](#methods)
  - [acid.counter.new](#acidcounternew)
  - [counter:incr](#counterincr)
  - [counter:get](#counterget)
- [Author](#author)
- [Copyright and License](#copyright-and-license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->


#   Name

acid.counter

#   Status

This library is considered production ready.

#   Description

A counter that counts hot events.

For hot events we do not need to records every event.
Instead we record it at a big enough probability.


#   Synopsis

```

local c = counter:new(ngx.shared.hotevent, 1000)

for _ = 0, 20 do
    -- records a event hotter than 1000 times a second
    c:incr('foo')
    ngx.sleep(1/1200)
end

print(c:get('foo')) -- high probability > 0

for _ = 0, 20 do
    -- records a event lower than 1000 times a second
    c:incr('foo')
    ngx.sleep(1/800)
end

print(c:get('foo')) -- high probability 0
```


#   Methods

##  acid.counter.new

**syntax**:
`acid.counter:new(storage, least_tps, timeout)`

**arguments**:

-   `storage`:
    a `ngx.shared.DICT` like object.
    It must provide `incr` and `get` method.

-   `least_tps`:
    specifies times per second threshold to record.
    If an event happens not frequent enough it won't be record.

-   `timeout`:
    optional to specify the timeout time of records in storage.

    By default it is `0.01` second, and the probability to record a event is
    calculated by: `p = 1 / timeout / least_tps`.

**return**:
a counter instance.


##  counter:incr

**syntax**:
`counter:incr(key)`

Record an event identified by `key`.

**arguments**:

-   `key`:
    is a string as the event identifier.

**return**:
the current value recorded.

If an error occur, it returns `nil`, error code in string and an error message.



##  counter:get

**syntax**:
`counter:get(key)`

Retrieve the value recorded for `key`.
If event `key` happens more frequently than `least_tps`,
the return value probably is a number `>0`.
Otherwise the return value has big chance to be `0`.

**arguments**:

-   `key`:
    specifies the event identifier in string.

**return**:
an integer.


#   Author

Zhang Yanpo (张炎泼) <drdr.xp@gmail.com>

#   Copyright and License

The MIT License (MIT)

Copyright (c) 2015 Zhang Yanpo (张炎泼) <drdr.xp@gmail.com>
