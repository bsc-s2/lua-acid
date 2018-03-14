<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
#   Table of Content

- [Name](#name)
- [Status](#status)
- [Description](#description)
- [Synopsis](#synopsis)
- [Methods](#methods)
  - [chash.new](#chashnew)
  - [chash.choose_server](#chashchoose_server)
  - [chash.update_server](#chashupdate_server)
  - [chash.delete_server](#chashdelete_server)
- [Author](#author)
- [Copyright and License](#copyright-and-license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

#   Name

acid.chash

#   Status

This library is considered production ready.

#   Description

Consistent hash module for ngx_lua.

#   Synopsis

```lua
local chash = require('acid.chash')

local servers = {
    server_1 = 128,
    server_2 = 128,
    server_3 = 256,
}

local c_hash, err, errmsg = chash.new(servers)
if err ~= nil then
    ngx.say('error')
end

local server_names, err, errmsg = c_hash:choose_server(
        'key_foo', {nr_choose=2})
if err ~= nil then
    ngx.say('error')
end

-- server_names
{server_x1, servers_x2}

local _, err, errmsg = c_hash:update_server({server_4 = 256})
if err ~= nil then
    ngx.say('error')
end

local _, err, errmsg = c_hash:delete_server({'server_4'})
if err ~= nil then
    ngx.say('error')
end
```

#   Methods

##   chash.new

**syntax**:
`c_hash, err, errmsg = chash.new(servers, opts)`

Create a new consistent hash object.

**arguments**:

-   `servers`:
    A lua table. The key is server name, value is the number of virtual
    node for that server.

-   `opts`:
    is a lua table holding the following keys:

    -   `debug`:
        set to `true` if need to calculate consistent rate and load
        distribution. Default to `False`.

**return**:
A consistent hash object. In case of failures, return `nil` and error code
and error message.

##   chash.choose_server

**syntax**:
`server_names, err, errmsg = c_hash:choose_server(key, opts)`

Choose server.

**arguments**:

-   `key`:
    is a string.

-   `opts`:
    is a lua table holding the following keys:

    -   `nr_choose`:
        Specify how many servers to choose. Default to 1.

**return**:
A table contains server names.

##   chash.update_server

**syntax**:
`info, err, errmsg = c_hash:update_server(servers)`

Add new servers or update virtual node number for servers.

**arguments**:

-   `servers`:
    A lua table. The key is server name, value is the number of virtual
    node for that server.

**return**:
If set `debug` to `true` when create consistent hash object, return a
lua table contains two fields 'consistent_rate' and 'load_distribution',
or return a empty table. In case of failures, return `nil` and error code
and error message.

##   chash.delete_server

**syntax**:
`info, err, errmsg = c_hash:delete_server(server_names)`

Delete servers.

**arguments**:

-   `server_names`:
    A lua table, contains name of servers to delete.

**return**:
Same as `chash.update_server`.

#   Author

Renzhi (任稚) <zhi.ren@baishancloud.com>

#   Copyright and License

The MIT License (MIT)

Copyright (c) 2015 Renzhi (任稚) <zhi.ren@baishancloud.com>
