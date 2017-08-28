<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
#   Table of Content

- [Name](#name)
- [Status](#status)
- [Description](#description)
- [Synopsis](#synopsis)
- [Methods](#methods)
  - [unicode.from_utf8](#from-utf8)
  - [unicode.xml_dec](#xml-dec)
  - [unicode.xml_enc](#xml-enc)
  - [unicode.xml_enc_character_reference](#xml-enc-character-reference)
- [Author](#author)
- [Copyright and License](#copyright-and-license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

#   Name

acid.unicode

#   Status

This library is considered production ready.

#   Description

Unicode related functions.

#   Synopsis

```lua
local unicode = require('acid.unicode')

local points, err, errmsg = unicode.from_utf8(string.char('0xE2','0x82','0xAC'))
if err ~= nil then
    ngx.say('error')
end
--- points: {8364}

local r, err, errmsg = unicode.xml_dec('&lt;&#60;')
if err ~= nil then
    ngx.say('error')
end
--- r: '<<'

local r, err, errmsg = unicode.xml_enc({60, 8364})
if err ~= nil then
    ngx.say('error')
end
--- r: '&lt;&#8364;'

local r, err, errmsg = unicode.xml_enc_character_reference('<<')
if err ~= nil then
    ngx.say('error')
end
--- r: '&lt;&lt;'
```

#   Methods

##  from-utf8

**syntax**:
`code_points, err, errmsg = unicode.from_utf8(utf8_string)`

**arguments**:

-   `utf8_string`:
    The utf8 encoded string.

**return**:
A table contains unicode code points.

##  xml-dec

**syntax**:
`str, err, errmsg = unicode.xml_dec(str_to_dec)`

**arguments**:

-   `str_to_dec`:
    A string contains character references.

**return**:
The same as the input string, except that, all character references are
converted to corresponding chars.

##  xml-enc

**syntax**:
`str, err, errmsg = unicode.xml_enc(code_points)`

**arguments**:

-   `code_points`:
    A table contains unicode code points.

**return**:
The encoded string.

##  xml-enc-character-reference

**syntax**:
`str, err, errmsg = unicode.xml_enc_character_reference(str_to_enc)`

Convert very char in the input string to character references if need to.

**arguments**:

-   `str_to_enc`:
    An arbitrary string.

**return**:
The encoded string.

#   Author

Renzhi (任稚) <zhi.ren@baishancloud.com>

#   Copyright and License

The MIT License (MIT)

Copyright (c) 2015 Renzhi (任稚) <zhi.ren@baishancloud.com>
