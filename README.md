#   Name

lua-acid

#   Status

This library is in beta phase.

It is deployed in a production envinroment and has been running stably.
But it still requires more tests and docs.

#   Description

lua-acid is a colleciton of lua utility functions and a classic paxos
implementation.

It is meant to be a underlaying code base for building a distributed system.

# Modules

| name                                        | description                                             | status          |
| :--                                         | :--                                                     | :--             |
| [acid.async_cache](doc/acid/async_cache.md) | shared-dict based cache, update asynchronously.         | well tested     |
| [acid.chash](doc/acid/chash.md)             | consistent hash module.                                 | well tested     |
| [acid.counter](doc/acid/counter.md)         | hot event counter.                                      | well tested     |
| [acid.strutil](doc/acid/strutil.md)         | string operation functions.                             | well tested     |
| [acid.tableutil](doc/acid/tableutil.md)     | table operation functions.                              | well tested     |
| [acid.unittest](doc/acid/unittest.md)       | unittest engine that looks for test functions in a dir. | well tested     |
| [acid.utf8](doc/acid/utf8.md)               | utf8 encoding and decoding.                             | well tested     |
| [acid.xml](doc/acid/xml.md)                 | xml to table and table to xml.                          | well tested     |
| [acid.cache](doc/acid/cache.md)             | in-process or shared-dict based cache.                  | not well tested |
| [acid.cluster](doc/acid/cluster.md)         | cluster implementation based on paxos.                  | not well tested |
| [acid.logging](doc/acid/logging.md)         | logging utilities.                                      | not well tested |
| [acid.paxos](doc/acid/paxos.md)             | classic paxos implementation.                           | not well tested |


# Install

-   Choice 0: Clone and copy:

    ```
    git clone git@github.com:baishancloud/lua-acid.git
    cp -R lua-acid/lib/acid <your_lua_lib_path>
    ```

-   Choice 1: `git-subrepo`

    Use git-subrepo to add it to your source code base:

    1.  Install [git-subrepo](https://github.com/baishancloud/git-subrepo)

    1.  Create config file `.gitsubrepo` in your git project:
        ```
        [ remote: https://github.com/ ]
        lualib/acid     baishancloud/lua-acid   master lib/acid
        ```

    1.  Fetch and merge `lua-acid` into your working dir:
        ```
        git-subrepo
        ```

# Test

This package needs perl command `prove` to run unittest:

```
# install in centos 7
$ yum install -y perl-CPAN perl-Test-Harness

```

run test:

```
$ sudo cpan Test::Nginx

# optional, setup nginx path:
$ export PATH=$PATH:/usr/local/Cellar/openresty/1.11.2.3/nginx/sbin

# test all
$ prove

# test modules with verbose mode
# prove t/ngx_abort_test.t t/ngx_abort.t -v
```

check nginx.conf and logs used in test under `t/servroot/conf`, `t/servroot/logs`.


# lua-poxos

Classic Paxos implementation in lua.

Nginx cluster management based on paxos.

Feature:

-   Classic two phase paxos algorithm.

-   Optional phase-3 as phase 'learn' or 'commit'

-   Support membership changing on the fly.

    This is archived by making the group members a paxos instance. Running paxos
    on group member updates group membership.

    Here we borrowed the concept 'view' that stands for a single version of
    membership.

    'view' is a no more than a normal paxos instance.

#   Author

Zhang Yanpo (张炎泼) <drdr.xp@gmail.com>

#   Copyright and License

The MIT License (MIT)

Copyright (c) 2015 Zhang Yanpo (张炎泼) <drdr.xp@gmail.com>

