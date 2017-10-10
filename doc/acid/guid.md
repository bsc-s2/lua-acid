<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
# Table of Content

- [Name](#name)
- [Status](#status)
- [Description](#description)
- [Synopsis](#synopsis)
- [Methods](#methods)
  - [guid.generate](#guidgenerate)
  - [guid.new](#guidnew)
  - [guid.parse](#guidparse)
- [Author](#author)
- [Copyright and License](#copyright-and-license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Name

acid.guid

# Status

This library is considered production ready.

# Description

It provides generating and parsing a unique id.

The format of guid:

```
-- 1451577623124010001
-- tttttttttttttssmmmm

-- t: is a number representing the current timestamp.
-- s: is a number representing sequence id.
-- m: is a number representing the unique machine id of cluster.
```

The sequence id is the number of generating guid in the current timestamp,
and the machine id ensures the machine between the one and only in cluster.

# Synopsis

```lua
local obj, err, err_msg = guid.new('shared_guid', 'shared_lock', 13, 2, 4)
if err ~= nil then
    return nil, err, err_msg
end

local guid, err, err_msg = obj:generate(obj.max_mid)
if err ~= nil then
    return nil, err, err_msg
end
print(guid)

local guid_tab, err, err_msg = obj:paste(guid)
if err ~= nil then
    return nil, err, err_msg
end
print(guid_tab.ts, guid_tab.seq, guid_tab.mid)
```

# Methods


## guid.generate

**syntax**:
`local guid, err, err_msg = obj:generate(mid, max_wait_ms)`

Generate a global unique string.

**arguments**:

- `mid`:
    is a number representing the unique machine id of cluster.

    It used to ensure the machine in a cluster is unique.

- `max_wait_ms`:
    is the max wait time to make a guid.

    By default it is 500 milliseconds.

**return**:
is a number string.


## guid.new

**syntax**:
`local obj, err, err_msg = guid.new(shared_guid, shared_lock, len_ts, len_seq, len_mid)`

**arguments**:

- `shared_guid`:
    is the name of shared dictionary(create by lua_shared_dict) used to cache
    and update the values of sequence.

- `shared_lock`:
    is the name of shared dictionary(create by lua_shared_dict) used by
    lua-resty-lock.

- `len_ts`:
    is the length of timestamp,
    it is a positive integer and it can not be more than 13.

    When generate a guid,
    timestamp provides millisecond level accuracy.

- `len_seq`:
    is the length of sequence id.

    It is an integer and it must be greater than or equal to 1.

    `seq` is a monotonically incremental integer as the second significant part
    of a guid to avoid duplication on a single machine.

- `len_mid`:
    is the length of machine id.

    It is an integer and it must be greater than or equal to 1.

    `mid` as the third part of a guid is used to ensure that the machine in a
    cluster is unique.

**return**:
is a guid object.


## guid.parse

**syntax**:
`local guid_tab, err, err_msg = obj:parse(guid)`

Parse `guid` to timestamp, sequence and machine id.

**argument**:

- `guid`:
    is a number string.

    It is made up of timestamp, sequence and machine id.

**return**:
is a table with timestamp, sequence and machine id.


# Author

LiuSiYuan (刘思源) <siyuan.liu@baishancloud.com>

# Copyright and License

The MIT License (MIT)

Copyright (c) 2017 LiuSiYuan (刘思源) <siyuan.liu@baishancloud.com>
