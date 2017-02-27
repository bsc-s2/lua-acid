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

# modules

| name                                    | description                                             | status          |
| :--                                     | :--                                                     | :--             |
| [acid.strutil](doc/acid/strutil.md)     | string operation functions.                             | well tested     |
| [acid.tableutil](doc/acid/tableutil.md) | table operation functions.                              | well tested     |
| [acid.unittest](doc/acid/unittest.md)   | unittest engine that looks for test functions in a dir. | well tested     |
| [acid.logging](doc/acid/logging.md)     | logging utilities.                                      | not well tested |
| [acid.cache](doc/acid/cache.md)         | in-process or shared-dict based cache.                  | not well tested |
| [acid.paxos](doc/acid/paxos.md)         | classic paxos implementation.                           | not well tested |
| [acid.cluster](doc/acid/cluster.md)     | cluster implementation based on paxos.                  | not well tested |


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

