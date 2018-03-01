<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
#   Table of Content

- [Name](#name)
- [Status](#status)
- [Description](#description)
- [Synopsis](#synopsis)
- [Methods](#methods)
  - [hashlib.new](#hashlibnew)
  - [hashlib.md5](#hashlibmd5)
  - [hashlib.sha1](#hashlibsha1)
  - [hashlib.sha256](#hashlibsha256)
  - [hashlib.update](#hashlibupdate)
  - [hashlib.reset](#hashlibreset)
  - [hashlib.final](#hashlibfinal)
  - [hashlib.deserialize](#hashlibdeserialize)
  - [hashlib.serialize](#hashlibserialize)
- [Author](#author)
- [Copyright and License](#copyright-and-license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->


#   Name

acid.hashlib

#   Status

This library is considered production ready.

#   Description

It is a wrapper for some hash functions,
and add serialize/deserialize methods for them.

The hash functions have the following methods:
- hash.new()
- hasher:update()
- hasher:reset()
- hasher:final()

Can be used to incrementally calculate the hash of data in different processes.

#   Synopsis

```lua
local hashlib = require('acid.hashlib')

local data = 'data'
local md5 = hashlib.md5()
md5:update(data)
local ctx, err, errmsg = hashlib:serialize()
if err ~= nil then
    print('failed to serialize ctx of md5')
end
print(md5:final())

-- append data in another process
local append = 'append'
local md5 = hashlib.md5()
local _, err, errmsg = hashlib:deserialize(ctx)
if err ~= nil then
    print('failed to deserialize from serialize ctx')
end
md5:update(append)
-- the md5 of 'dataappend'
print(md5:final())

```

#   Methods

##  hashlib.new

**syntax**:
`hasher, err, errmsg = hashlib.new(algorithm)`

**arguments**:
-   `algorithm`:
    is a string.

    The name of hash algorithm.
    It can be :
    - hashlib.MD5
    - hashlib.SHA1
    - hashlib.SHA256

**return**:
the corresponding wrapped hash objects for calculating hash

##  hashlib.md5

**syntax**:
`md5 = hashlib.md5()`

**return**:
the corresponding wrapped hash objects for calculating md5

##  hashlib.sha1

**syntax**:
`sha1 = hashlib.sha1()`

**return**:
the corresponding wrapped hash objects for calculating sha1

##  hashlib.sha256

**syntax**:
`sha256 = hashlib.sha256()`

**return**:
the corresponding wrapped hash objects for calculating sha256

##  hashlib.update

**syntax**:
`ok = hasher:update(data)`

can be called repeatedly with chunks of the message to be hashed.

**arguments**:

-   `data`:
    is a str.

**return**:
return true on success or false on failure

##  hashlib.reset

**syntax**:
`ok = hasher:reset()`

**return**:
return true on success or false on failure

##  hashlib.final

**syntax**:
`digest = hasher:final()`

**return**:
return the digest of the data

##  hashlib.deserialize

**syntax**:
`ok, err, errmsg = hasher:deserialize(ctx)`

**arguments**:

-   `ctx`:
    is a table.

    The lua table that hold context information for hashing operation.

**return**:
return true on success or error code and error message on failure

##  hashlib.serialize

**syntax**:
`ctx, err, errmsg = hasher:serialize()`

**return**:
The lua table that hold context information for hashing operation.

#   Author

Liu Tongwei(刘桐伟) <tongwei.liu@baishancloud.com>

#   Copyright and License

The MIT License (MIT)

Copyright (c) 2018 Liu Tongwei(刘桐伟) <tongwei.liu@baishancloud.com>
