<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
#   Table of Content

- [Name](#name)
- [Status](#status)
- [Description](#description)
- [Synopsis](#synopsis)
- [Methods](#methods)
  - [to_xml](#to_xml)
  - [from_xml](#from_xml)
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

local xml_str, err, errmsg = xml.to_xml('root', {foo='bar'})
if err ~= nil then
    ngx.say('error')
end
-- <root><foo>bar</foo></root>

local r, err, errmsg = xml.from_xml('<foo>bar</foo>')
if err ~= nil then
    ngx.say('error')
end
-- r.foo == 'bar'
```

#   Methods

##  to_xml

**syntax**:
`xml_str, err, errmsg = xml.to_xml(root_name, tbl, opts)`

**arguments**:

-   `root_name`:
    The root tag name.

-   `tbl`:
    Arbitrary lua table, support the following extra fields.

    -   `__attr`: A table to set attributes.

    -   `__key_order`: A array table to specify the output label order.

-   `opts`:
    The options table accepts the following options:

    -   `no_declaration`: If true, will not add declaration string.

    -   `indent`: Set the indent to get a beautiful output.

**return**:
The xml formated string.

##  from_xml

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
