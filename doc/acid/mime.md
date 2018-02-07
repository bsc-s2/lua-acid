<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
#   Table of Content

- [Name](#name)
- [Status](#status)
- [Description](#description)
- [Synopsis](#synopsis)
- [Methods](#methods)
  - [mime.by_fn](#mimeby_fn)
- [Author](#author)
- [Copyright and License](#copyright-and-license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

#   Name

acid.mime

#   Status

This library is considered production ready.

#   Description

This module provide some util methods to handle mime type.

#   Synopsis

```lua
local mime = require("acid.mime")

mime.by_fn('file.json')
-- application/json
```

#   Methods


##  mime.by_fn

**syntax**:
`mime.by_fn(fn)`

Return mime type according to filename suffix.

**arguments**:

-   `fn`:
    is a string.

**return**:
mime type that predefined.

#   Author

Liu Tongwei(刘桐伟) <tongwei.liu@baishancloud.com>

#   Copyright and License

The MIT License (MIT)

Copyright (c) 2017 Liu Tongwei(刘桐伟) <tongwei.liu@baishancloud.com>
