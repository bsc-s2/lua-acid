<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
#   Table of Content

- [Name](#name)
- [Status](#status)
- [Description](#description)
- [Synopsis](#synopsis)
- [Methods](#methods)
  - [xml.to_xml](#to-xml)
  - [xml.from_xml](#from-xml)
- [Author](#author)
- [Copyright and License](#copyright-and-license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

#   Name

acid.xml

#   Status

This library is considered production ready.

#   Description

Convert lua table to xml or xml to lua table.

#   Synopsis

```lua
local xml = require('acid.xml')

local xml_str, err, errmsg = xml.to_xml({foo='bar'})
if err ~= nil then
    ngx.say('error')
end

local r, err, errmsg = xml.from_xml('<foo>bar</foo>')
if err ~= nil then
    ngx.say('error')
end
```

#   Methods

##  to-xml

**syntax**:
`xml_str, err, errmsg = xml.to_xml(tbl)`

**arguments**:

-   `tbl`:
    Arbitrary lua table, support the following extra fields.

    -   `__attr`: A table to set attributes.

    -   `__key_order`: A array table to specify the output label order.

**return**:
The xml formated string.

##  from-xml

**syntax**:
`r, err, errmsg = xml.from_xml(xml_str)`

**arguments**:

-   `xml_str`:
    Xml formated string.

**return**:
A lua table.

#   Author

Renzhi (任稚) <zhi.ren@baishancloud.com>

#   Copyright and License

The MIT License (MIT)

Copyright (c) 2015 Renzhi (任稚) <zhi.ren@baishancloud.com>
