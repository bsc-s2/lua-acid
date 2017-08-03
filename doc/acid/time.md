<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
# Table of Content

- [Name](#name)
- [Status](#status)
- [Description](#description)
- [Synopsis](#synopsis)
- [Methods](#methods)
  - [time.parse](#timeparse)
  - [time.format](#timeformat)
  - [time.to_sec](#timeto_sec)
- [Properties](#properties)
  - [time.timezone](#timetimezone)
- [Author](#author)
- [Copyright and License](#copyright-and-license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Name

acid.time

# Status

This library is considered production ready.

# Description

It provides with several often used time operation utilities.

# Synopsis

```lua
local acid_time = require("acid.time")

local ts, err, err_msg = acid_time.parse('2017-07-26 14:13:17', 'std')
if err ~= nil then
    return nil, err, err_msg
end
-- ts = 1501049597
print(ts)

local dt, err, err_msg = acid_time.format(1501049597, 'utc')
if err ~= nil then
    return nil, err, err_msg
end
-- dt = 'Wed, 26 Jul 2017 06:13:17 UTC'
print(dt)
```

# Methods


## time.parse

**syntax**:
`time.parse(dt, fmtkey, withzone)`

Parse time string to a timestamp.

**arguments**:

- `dt`:
    is a time string.

    For example:

    ```
    dt = '20170726T061317Z'                 -- 'isobase'
    dt = '2017-07-26T06:13:17.000Z'         -- 'iso'
    dt = 'Wed, 26 Jul 2017 06:13:17 UTC'    -- 'utc'
    dt = '2017-07-26 14:13:17'              -- 'std'
    dt = '26/Jul/2017:14:13:17'             -- 'nginxaccesslog'
    dt = '2017/07/26 14:13:17'              -- 'nginxerrorlog'
    ```

- `fmtkey`:
    specifies time string format.
    `fmtkey` is a format string alias.

    For example:

    ```
    fmtkey = 'isobase'
    fmtkey = 'iso'
    fmtkey = 'utc'
    fmtkey = 'std'
    fmtkey = 'nginxaccesslog'
    fmtkey = 'nginxerrorlog'
    ```

    See also: `time.format`.

- `withzone`:
    is a Boolean value to determine if time has timezone.
    `withzone` can be defaulted.

    By default it is:

    ```
    'isobase'       = true
    'iso'           = true
    'utc'           = true
    'std'           = false
    'nginxaccesslog'= false
    'nginxerrorlog' = false
    ```

    See also: `time.format`.

**return**:
timestamp in second.


## time.format

**syntax**:
`time.format(ts, fmtkey, withzone)`

Convert timestamp to specified format time string.

**arguments**:

- `ts`:
    is a timestamp in second.

- `fmtkey`:
    specifies time string format.
    `fmtkey` is a format string alias.

    For example:

    ```
    fmtkey = 'iso'
    fmtkey = 'utc'
    fmtkey = 'std'
    fmtkey = 'nginxaccesslog'
    fmtkey = 'nginxerrorlog'
    ```

    See also `time.parse`.

- `withzone`:
    is a Boolean value to determine if time has timezone.
    `withzone` can be defaluted.

    By default it is:

    ```
    'iso'           = true
    'utc'           = true
    'std'           = false
    'nginxaccesslog'= false
    'nginxerrorlog' = false
    ```

    See also: `time.parse`.

**return**:
specified format time string.


## time.to_sec

**syntax**:
`time.to_sec(ts)`

Convert timestamp in second, millisecond, microsecond or nanosecond to second.

**arguments**:

- `ts`:
    is a number string or number that is not scientific notation,
    and it can be a timestamp in second, millisecond(10e-3), microsecond(10e-6) or nanosecond(10e-9),
    and it can not be a float number or less than 0.

**return**:
timestamp in second.


# Properties

## time.timezone

**syntax**:
`time.timezone`

The `timezone` satisfies `local_time + timezone = utc_time`.

`timezone` is the offset to timezone 0 without DST info,
it is a integer number.


# Author

siyuan (刘思源) <siyuan.liu@baishancloud.com>

# Copyright and License

The MIT License (MIT)

Copyright (c) 2017 siyuan (刘思源) <siyuan.liu@baishancloud.com>
