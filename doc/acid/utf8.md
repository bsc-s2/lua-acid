<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
#   Table of Content

- [Name](#name)
- [Status](#status)
- [Description](#description)
- [Synopsis](#synopsis)
- [Methods](#methods)
  - [char](#char)
  - [code_point](#code_point)
- [Author](#author)
- [Copyright and License](#copyright-and-license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

#   Name

acid.utf8

#   Status

This library is considered production ready.

#   Description

This library provides basic support for UTF-8 encoding.

#   Synopsis

```lua
local utf8 = require('acid.utf8')

local utf8_str, err, errmsg = utf8.char({258, 0x1234})
if err ~= nil then
    ngx.say('error')
end

local code_points, err, errmsg = utf8.code_point(utf8_str)
if err ~= nil then
    ngx.say('error')
end
```

#   Methods

##  char

**syntax**:
`utf8_str, err, errmsg = utf8.char(code_points)`

Converts each code point to its corresponding UTF-8 byte sequence and
returns a string with the concatenation of all these sequences.

**arguments**:

-   `code_points`:
    A table contains code points.

**return**:
A string with the concatenation of all UTF-8 sequences.

##  code_point

**syntax**:
`code_points, err, errmsg = utf8.code_point(utf8_str)`

Returns the code points (as integers) from all characters in utf8_str.

**arguments**:

-   `utf8_str`:
    A utf8 encoded string.

**return**:
A table contains code points.

#   Author

Renzhi (任稚) <zhi.ren@baishancloud.com>

#   Copyright and License

The MIT License (MIT)

Copyright (c) 2015 Renzhi (任稚) <zhi.ren@baishancloud.com>
