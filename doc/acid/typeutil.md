<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
#   Table of Content

- [Name](#name)
- [Status](#status)
- [Description](#description)
- [Synopsis](#synopsis)
- [Methods](#methods)
  - [typeutil.check_integer_range](#typeutilcheck_integer_range)
  - [typeutil.check_number_range](#typeutilcheck_number_range)
  - [typeutil.check_string_number_range](#typeutilcheck_string_number_range)
  - [typeutil.check_length_range](#typeutilcheck_length_range)
  - [typeutil.check_fixed_length](#typeutilcheck_fixed_length)
  - [typeutil.is_string](#typeutilis_string)
  - [typeutil.is_number](#typeutilis_number)
  - [typeutil.is_integer](#typeutilis_integer)
  - [typeutil.is_boolean](#typeutilis_boolean)
  - [typeutil.is_string_number](#typeutilis_string_number)
  - [typeutil.is_array](#typeutilis_array)
  - [typeutil.is_dict](#typeutilis_dict)
  - [typeutil.is_empty_table](#typeutilis_empty_table)
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

local is_true = acid_typeutil.is_integer(0.5)
print(is_true)      -- false
```

# Methods


## typeutil.check_integer_range

**syntax**:
`typeutil.check_integer_range(val, min, max, opts)`

Return `true` if `val` is an integer and in the range,
`false` otherwise.

The range is closed.
It means `val` can be `min` or `max`.

**arguments**:

- `val`:
  is a number.

- `min`:
  is the minimum of the range.

- `max`:
  is the maximum of the range.

- `opts`:
  `opts.left_closed` can be true or false.
  Default is true.
  If `opts.left_closed` is true, range contains min value.

  `opts.right_closed` can be true or false.
  Default is true.
  If `opts.right_closed` is true, range contains max value.

**return**:
bool


## typeutil.check_number_range

**syntax**:
`typeutil.check_number_range(val, min, max, opts)`

Return `true` if `val` is in the range,
`false` otherwise.

**arguments**:

- `val`:
  is a number.

- `min`:
  is the minimum of the range.

- `max`:
  is the maximum of the range.

- `opts`:
  `opts.left_closed` can be true or false.
  Default is true.
  If `opts.left_closed` is true, range contains min value.

  `opts.right_closed` can be true or false.
  Default is true.
  If `opts.right_closed` is true, range contains max value.

**return**:
bool.


## typeutil.check_string_number_range

**syntax**:
`typeutil.check_string_number_range(val, min, max, opts)`

Same as `typeutil.check_number_range` except the `val` is a string number.

## typeutil.check_length_range

**syntax**:
`typeutil.check_length_range(val, min, max, opts)`

Return `true` if `val`'s length is in the range,
`false` otherwise.

**arguments**:

- `val`:
  can be a string or a table.

- `min`:
  is the minimum of the range.

- `max`:
  is the maximum of the range.

- `opts`:
  `opts.left_closed` can be true or false.
  Default is true.
  If `opts.left_closed` is true, range contains min value.

  `opts.right_closed` can be true or false.
  Default is true.
  If `opts.right_closed` is true, range contains max value.

**return**:
bool.

## typeutil.check_fixed_length

**syntax**:
`typeutil.check_fixed_length(val, length)`

Return `true` if `val`'s length equals `length`,
`false` otherwise.

**arguments**:

- `val`:
  can be a string or a table.

- `length`:
  is a number.

**return**:
bool.


## typeutil.is_string

**syntax**:
`typeutil.is_string(val)`

Return `true` if `val` is a string,
`false` otherwise.

**arguments**:

- `val`:
  any.

**return**;
bool.

## typeutil.is_number

**syntax**:
`typeutil.is_number(val)`

Return `true` if `val` is a number,
`false` otherwise.

**arguments**:

- `val`:
  any.

**return**;
bool.

## typeutil.is_integer

**syntax**:
`typeutil.is_integer(val)`

Return `true` if `val` is an integer,
`false` otherwise.

**arguments**:

- `val`:
  any.

**return**;
bool.

## typeutil.is_boolean

**syntax**:
`typeutil.is_boolean(val)`

Return `true` if `val` is a bool,
`false` otherwise.

**arguments**:

- `val`:
  any.

**return**;
bool.

## typeutil.is_string_number

**syntax**:
`typeutil.is_string_number(val)`

Return `true` if `val` is a string number,
`false` otherwise.

**arguments**:

- `val`:
  any.

**return**;
bool.

## typeutil.is_array

**syntax**:
`typeutil.is_array(val)`

Return `true` if `val` is an array,
`false` otherwise.

Note that the array follows the cjson definition.
See [encode_sparse_array](https://www.kyne.com.au/~mark/software/lua-cjson-manual.html#encode_sparse_array)
The excessively sparse array is considered to be a dict.
The empty_table is both an array and a dict.
**arguments**:

- `val`:
  any.

**return**;
bool.

## typeutil.is_dict

**syntax**:
`typeutil.is_dict(val)`

Return `true` if `val` is a dict,
`false` otherwise.

**arguments**:

- `val`:
  any.

**return**;
bool.

## typeutil.is_empty_table

**syntax**:
`typeutil.is_empty_table(val)`

Return `true` if `val` is `{}`,
`false` otherwise.

**arguments**:

- `val`:
  any.

**return**;
bool.


# Author

siyuan (刘思源) <siyuan.liu@baishancloud.com>

# Copyright and License

The MIT License (MIT)

Copyright (c) 2017 siyuan (刘思源) <siyuan.liu@baishancloud.com>
