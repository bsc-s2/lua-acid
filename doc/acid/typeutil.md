e!-- START doctoc generated TOC please keep comment here to allow nuto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
#   Table of Content

- [Name](#name)
- [Status](#status)
- [Description](#description)
- [Synopsis](#synopsis)
- [Methods](#methods)
  - [typeutil.check_int_range](#typeutilcheck_int_range)
  - [typeutil.check_number_range](#typeutilcheck_number_range)
  - [typeutil.check_number_string_range](#typeutilcheck_number_range)
  - [typeutil.is_int](#typeutilis_int)
- [Author](#author)
- [Copyright and License](#copyright-and-license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Name

acid.typeutil

# Status

This library is considered production ready.

# Description

It provides with several often used type checking utilities.

# Synopsis

```lua
local acid_typeutil = require("acid.typeutil")

local is_true = acid_typeutil.check_number_range(1, 0, 2)
print(is_true)      -- true

local is_true = acid_typeutil.is_int(0.5)
print(is_true)      -- false
```

# Methods


## typeutil.check_int_range

**syntax**:
`typeutil.check_int_range(val, min, max)`

Return `true` if `val` is an integer and in the range,
`false` otherwise.

The range is closed.
It means `val` can be `min` or `max`.
Unlike `check_number_range()` in which a user is able to specify whether
left/right boundary is closed or opened.

**arguments**:

- `val`:
    is a number.

- `min`:
    is the minimum of the range.

- `max`:
    is the maximum of the range.

**return**:
bool


## typeutil.check_number_range

**syntax**:
`typeutil.check_number_range(val, min, max, left_closed, right_closed)`

Return `true` if `val` is in the range,
`false` otherwise.

**arguments**:

- `val`:
    is a number.

- `min`:
    is the minimum of the range.

- `max`:
    is the maximum of the range.

- `left_closed`:
    specifies the open or closed on the left of the range.

    By default it is `true`.

- `right_closed`:
    specifies the open or closed on the right of the range.

    By default it is `true`.

**return**:
bool.


## typeutil.check_number_string_range

**syntax**:
`typeutil.check_number_string_range(val, min, max, left_closed, right_closed)`

Same as `typeutil.check_number_range` except the `val` is a number or a number
string.


## typeutil.is_int

**syntax**:
`typeutil.is_int(val)`

Return `true` if `val` is an integer,
`false` otherwise.

**arguments**:

- `val`:
    is a number.

**return**;
bool.


# Author

siyuan (刘思源) <siyuan.liu@baishancloud.com>

# Copyright and License

The MIT License (MIT)

Copyright (c) 2017 siyuan (刘思源) <siyuan.liu@baishancloud.com>
