<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
#   Table of Content

- [Name](#name)
- [Status](#status)
- [Synopsis](#synopsis)
- [Description](#description)
- [Variable](#variable)
  - [ZnodeStat](#znodestat)
- [Methods](#methods)
  - [zkcli.new](#zkclinew)
  - [zkcli.create](#zkclicreate)
  - [zkcli.get](#zkcliget)
  - [zkcli.get_children](#zkcliget_children)
  - [zkcli.get_acls](#zkcliget_acls)
  - [zkcli.get_next](#zkcliget_next)
  - [zkcli.set](#zkcliset)
  - [zkcli.set_acls](#zkcliset_acls)
  - [zkcli.delete](#zkclidelete)
  - [zkcli.add_auth](#zkcliadd_auth)
- [Author](#author)
- [Copyright and License](#copyright-and-license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

#   Name

zkcli

#   Status

The library is considered production ready.

#   Synopsis

```
local zkcli = require("acid.zkcli")
local cli, err, errmsg = zkcli:new('127.0.0.1:2181')

local p, err, errmsg = cli:create('/a', 'val')
# p == '/a'
# err == nil
# errmsg == nil

local v, err, errmsg = cli:get('a')
# v[1] == 'val'
# v[2]: node stat

local st, err, errmsg = cli:set('a', 'val1')
# st: node stat

local r, err, errmsg = cli:delete('a')
# r == true
```

#   Description

An Apache Zookeeper lua client.

#   Variable

##  ZnodeStat

a `table`, the elements:

-   `czxid`:
    a `string` of 8 chars, the transaction id of the change that caused this znode to be created.

-   `mzxid`:
    a `string` of 8 chars, the transaction id of the change that last modified this znode.

-   `ctime`:
    a `string` of 8 chars, the time in seconds from epoch when this znode was created. (ctime is in milliseconds).

-   `mtime`:
    a `string` of 8 chars, the time in seconds from epoch when this znode was last modified. (mtime is in milliseconds).

-   `version`:
    a `number`, the number of changes to the data of this znode.

-   `cversion`:
    a `number`, the number of changes to children of this znode.

-   `aversion`:
    a `number`, the number of changes to the ACL of this znode.

-   `ephemeral_owner`:
    a `string` of 8 char, sthe session id of the owner of this znode if the znode is an ephemeral node.

-   `data_length`:
    a `number`, the length of the data field of this znode.

-   `num_children`:
    a `number`, the number of children of this znode.

#   Methods

##  zkcli.new

**syntax**:
`zkcli:new(hosts, timeout, auth_data, opts)`

Create zookeeper client.

**arguments**:

-   `hosts`:
    a `table` or a `string`, like:

    -   `{{'10.10.10.1', '2181'}, {'10.10.10.2', '2181'}}`

    -   `'10.10.10.1:2181,10.10.10.2:2181'`

-   `timeout`:
    it is a `table` or `number`, specifies the connect, send, read timeout in ms.

    -   `table`: has 3 elements(connect timeout, send timeout, read timeout).

    -   `number`: in ms, it is connect timeout, send timeout and read timeout.

-   `auth_data`:
    a `table` of authentication credentials to use for the connection, should be a list of `{scheme, credential}`.

-   `opts`:
    a `table`, the other optional parameters.

    -   `read_only`: allow connections to read only servers.

**return**:
the zookeeper client.

##  zkcli.create

**syntax**:
`zkcli:create(path, value, acls, sequence)`

Create a node with the given value as its data.

**arguments**:

-   `path`:
    path of node.

-   `value`:
    initial bytes value of node.

-   `acls`:
    a list of the node acl, like `{{'cdrwa', 'username', 'pwd'}, ...}`.

    -   `the first element`:
        it's characters have the following meaning:

        -   `c`: create

        -   `d`: delete

        -   `r`: read

        -   `w`: write

        -   `a`: admin

    -   `the second element`:
        username

    -   `the third element`:
        passwd

-   `sequence`:
    boolean indicating whether path is suffixed with a unique index.

**return**:
real path of the new node.

##  zkcli.get

**syntax**:
`zkcli:get(path)`

Get the value of a node.

**arguments**:

-   `path`:
    path of node.

**return**:
a table, `{value, ZnodeStat}` of node.

##  zkcli.get_children

**syntax**:
`zkcli:get_children(path)`

Get a list of child nodes of a path.

**arguments**:

-   `path`:
    path of node to list.

**return**:
list of child node names.

##  zkcli.get_acls

**syntax**:
`zkcli:get_acls(path)`

Return the ACL and stat of the node of the given path.

**arguments**:

-   `path`:
    path of node.

**return**:
a table of 2 elements, one is `acls`(see `acls` in `zkcli.create`), another is `ZnodeStat`.

##  zkcli.get_next

**syntax**:
`zkcli:get_next(path, version, timeout)`

Wait until zk-node `path` version becomes greater than `version` then return
node value and `ZnodeStat`.

**arguments**:

-   `path`:
    path of node.

-   `version`:
    the version for compareing with the version of the node.

-   `timeout`:
    specifies the timeout for waiting in ms. Defaults to one year.

**return**:
if timeout, `rst` is nil, `err` is `GetNextTimeout`, otherwise the value and `ZnodeStat` of the node.

##  zkcli.set

**syntax**:
`zkcli:set(path, value, version)`

Set the value of a node.

**arguments**:

-   `path`:
    path of node.

-   `value`:
    new data value.

-   `version`:
    version of node being updated, or -1.

**return**:
Updated `ZnodeStat` of the node.

##  zkcli.set_acls

**syntax**:
`zkcli:set_acls(path, acls, version)`

Set the ACL for the node of the given path.

**arguments**:

-   `path`:
    path of node.

-   `acls`:
    see `acls` in `zkcli.create`.

-   `version`:
    the expected node version that must match.

**return**:
the `ZnodeStat` of the node.

##  zkcli.delete

**syntax**:
`zkcli:delete(path, version)`

Delete a node.

**arguments**:

-   `path`:
    path of node.

-   `version`:
    the expected node version that must match.

**return**:
`true` if success.

##  zkcli.add_auth

**syntax**:
`zkcli:add_auth(scheme, credential)`

Send credentials to server.

**arguments**:

-   `scheme`:
    authentication scheme (default supported: `digest`).

-   `credential`:
    the credential, format is `username:pwd`.

**return**:
nothing

#   Author

Baohai Liu(刘保海) <baohai.liu@baishancloud.com>

#   Copyright and License

The MIT License (MIT)

Copyright (c) 2017 Baohai Liu(刘保海) <baohai.liu@baishancloud.com>
