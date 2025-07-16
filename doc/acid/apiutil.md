<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
#   Table of Content

- [Name](#name)
- [Status](#status)
- [Description](#description)
- [Synopsis](#synopsis)
- [Methods](#methods)
  - [apiutil.output](#apiutiloutput)
- [Author](#author)
- [Copyright and License](#copyright-and-license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

#   Name

acid.apiutil

#   Status

This library is considered production ready.

#   Description

It provides common ngx output functions.

#   Synopsis

```lua
local apiutil = require("acid.apiutil")

code = 200
headers = {['Content-Type']='application/json'}
body = 'hello'

apiutil.output(code,headers,body)
```

#   Methods


##  apiutil.output

**syntax**:
`apiutil.output(code, headers, body)`

**arguments**:

-   `code`:
    is a integer.

-   `headers`:
    is a table.

    like `{["X-My-Header"] = 'blah blah', ['Set-Cookie'] = {'a=32; path=/', 'b=4; path=/'}}`.

-   `body`:
    can be str or nil or boolean or nested array table.

    See also [ngx.print](https://github.com/openresty/lua-nginx-module#ngxprint)

**return**:
Nothing

#   Author

Liu Tongwei(刘桐伟) <tongwei.liu@baishancloud.com>

#   Copyright and License

The MIT License (MIT)

Copyright (c) 2017 Liu Tongwei(刘桐伟) <tongwei.liu@baishancloud.com>
