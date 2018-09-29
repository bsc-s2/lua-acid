<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
#   Table of Content

- [Name](#name)
- [Status](#status)
- [Synopsis](#synopsis)
- [Description](#description)
- [Methods](#methods)
  - [struct.pack_int32](#structpack_int32)
  - [struct.unpack_int32](#structunpack_int32)
  - [struct.pack_string](#structpack_string)
  - [struct.unpack_string](#structunpack_string)
  - [struct.pack](#structpack)
  - [struct.unpack](#structunpack)
- [Author](#author)
- [Copyright and License](#copyright-and-license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

#   Name

struct

#   Status

The library is considered production ready.

#   Synopsis

```
local struct = require("acid.struct")

local pack_little_endian = struct.pack_int32(123, true)
local pack_big_endian = struct.pack_int32(123, false)

local num1 = struct.unpack_int32({stream=pack_big_endian, offset=1}, false, true)
local num2 = struct.unpack_int32({stream=pack_little_endian, offset=1}, true, true)

local str1 = struct.pack_string('abc')
local str2 = struct.unpack_string({stream=str1, offset=1})
```

#   Description

Some helper functions for handling binary data or network stream.

#   Methods

##  struct.pack_int32

**syntax**:
`struct.pack_int32(val, little_endian)`

Pack an int32 or unsigned int32 number to a str.

**arguments**:

-   `val`:
    the number that will be packed.

-   `little_endian`:
    type is `bool`, if it is `true`, packed in little endian, otherwise in big endian.

**return**:
    the packed string.

##  struct.unpack_int32

**syntax**:
`struct.unpack_int32(buffer, little_endian, signed)`

Unpack a 4 chars string to a number.

**arguments**:

-   `buffer`:
    a table, contains two elements:

    -   `stream`:
        the input stream.

    -   `offset`:
        offset of the stream.

-   `little_endian`:
    type is `bool`, if it is `true`, unpacked in little endian, otherwise in big endian.

-   `signed`:
    type is `bool`, if it is `true`, return a signed number, otherwise return a unsigned number.

**return**:
    the unpacked number.

##  struct.pack_string

**syntax**:
`struct.pack_string(str)`

Concat the length of the `str` in big endian and the `str`.

**arguments**:

-   `str`:
    the input string.

**return**:
    a string includes the length of the `str` and the `str`.

##  struct.unpack_string

**syntax**:
`struct.unpack_string(buffer)`

Unpack a string from a stream. The format of the string in the stream must be
`length(4 chars, packed in big endian) .. string`.


**arguments**:

-   `buffer`:
    a table, contains two elements:

    -   `stream`:
        the input stream.

    -   `offset`:
        offset of the stream.

**return**:
    string unpacked from the stream.

##  struct.pack

**syntax**:
`struct.pack(format, ...)`

Return a string containing the values(`...`) packed according to the given format.

**arguments**:

-   `format`:
    a string, it's characters have the following meaning:

    -   `>`:
        big endian.

    -   `<`:
        little endian.

    -   `i`:
        signed int32.

    -   `I`:
        unsigned int32.

    -   `s`:
        a string.

    -   `S`:
        a `struct.pack_string`.

**return**:
    the packed string.

##  struct.unpack

**syntax**:
`struct.unpack(format, buffer)`

Unpack the string (presumably packed by `struct.pack`) according to the given format.

**arguments**:

-   `format`:
    a string, it's characters have the following meaning:

    -   `>`:
        big endian.

    -   `<`:
        little endian.

    -   `i`:
        signed int32.

    -   `I`:
        unsigned int32.

    -   `s`:
        a string. The length must be provided, like `3s`.

    -   `S`:
        a `struct.pack_string`.

-   `buffer`:
    a table, contains two elements:

    -   `stream`:
        the input stream.

    -   `offset`:
        offset of the stream.

**return**:
    a `table`, the unpacked result.

#   Author

Baohai Liu(刘保海) <baohai.liu@baishancloud.com>

#   Copyright and License

The MIT License (MIT)

Copyright (c) 2017 Baohai Liu(刘保海) <baohai.liu@baishancloud.com>
