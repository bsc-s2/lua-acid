e!-- START doctoc generated TOC please keep comment here to allow nuto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
#   Table of Content

- [Name](#name)
- [Status](#status)
- [Description](#description)
- [Synopsis](#synopsis)
- [Methods](#methods)
  - [setutil.check_set_range](#setutilcheck_set_range)
  - [setutil.intersect](#setutilintersect)
- [Author](#author)
- [Copyright and License](#copyright-and-license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Name

acid.setutil

# Status

This library is considered production ready.

# Description

It provides with several often used set operation utilities.

# Synopsis

```lua
local acid_setutil = require("acid.setutil")

local is_true, err, err_msg = acid_setutil.check_set_range(1, 2)
if err ~= nil then
    return nil, err, err_msg
end
print(is_true)      -- true

local intersection, err, err_msg = acid_setutil.intersect(1, 3, 2, 4)
if err ~= nil then
    return nil, err, err_msg
end
print(intersection.from, intersection.to)       -- 2, 3
```

# Methods

## setutil.check_set_range

**syntax**:
`setutil.check_set_range(from, to)`

Check the range of the set.

Return `true` if `from` is less than or equal to `to`,
`false` otherwise.

**arguments**:

- `from`:
    is the beginning of the set.

    It can be a number or number string.

- `to`:
    is the end of the set.

    It can be a number or number string.

**return**:
bool.


## setutil.intersect

**syntax**:
`setutil.intersect(f1, t1, f2, t2)`

Take the intersection of two sets.

**arguments**:

- `f1`:
    is the beginning of the first set.

- `t1`:
    is the end of the first set.

- `f2`:
    is the beginning of the second set.

- `t2`:
    is the end of the second set.

**return**:
a table with the beginning and end of the intersection.


# Author

siyuan (刘思源) <siyuan.liu@baishancloud.com>

# Copyright and License

The MIT License (MIT)

Copyright (c) 2017 siyuan (刘思源) <siyuan.liu@baishancloud.com>
