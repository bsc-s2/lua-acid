<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DO NOT EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
#   Table of Content

- [Name](#name)
- [Status](#status)
- [Description](#description)
- [Synopsis](#synopsis)
- [Methods](#methods)
  - [sm3.new](#sm3new)
  - [sm3.update](#sm3update)
  - [sm3.final](#sm3final)
  - [sm3.reset](#sm3reset)
- [Author](#author)
- [Copyright and License](#copyright-and-license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

#   Name

acid.sm3

#   Status

This library is considered production ready.

#   Description

This module provide some util methods to calculate the digest.

#   Synopsis

```lua
local sm3 = require("acid.sm3")
local resty_string = require("resty.string")

local mt = sm3:new()

local msg = '123'
if mt:update(msg) == true then
    print(resty_string.to_hex(mt:final()))
end

-- output:
-- 6e0f9e14344c5406a0cf5a3b4dfb665f87f4a771a31f7edbb5c72874a32b2957

```

#   Methods

## sm3.new()

**syntax**:
`sm3.new()`

Dynamically allocates the memory space required for a digest context.
Return a pointer to this digest context

## sm3.update()

**synatax**:
`sm3.update(s)`

Calculate the digest value for s.
Return true means success, false means failture

**aruguments**:

-  `s`:
    a `string`, refer to the data for which the digest valus is to be calculate

**return**:
success is true, failture is false

## sm3.final()

**synatax**:
`sm3.final()`

Put the digest data in a buffer.
Return a string containing the digest data

**return**:
success is a string, failture is nil


## sm3.reset()

**synatax**:
`sm3.reset()`

Reset digest context.
Return true means success, false means failture

**return**:
success is true, failture is false

#   Author

Lv Ting<ting.lv@baishancloud.com>

#   Copyright and License

The MIT License (MIT)

Copyright (c) 2018 Lv Ting<ting.lv@baishancloud.com>
