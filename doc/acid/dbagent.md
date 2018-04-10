<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
#   Table of Content

- [Name](#name)
- [Status](#status)
- [Description](#description)
- [Synopsis](#synopsis)
- [dbagent_conf module](#dbagent_conf-module)
  - [dbagent_conf.get_upstream_conf](#dbagent_confget_upstream_conf)
    - [tables](#tables)
      - [tables[table_name][n].from](#tablestable_namenfrom)
      - [tables[table_name][n].db](#tablestable_namendb)
    - [dbs](#dbs)
      - [dbs[db_name].r](#dbsdb_namer)
      - [dbs[db_name].w](#dbsdb_namew)
    - [connections](#connections)
      - [connections[access_point].database](#connectionsaccess_pointdatabase)
      - [connections[access_point].host](#connectionsaccess_pointhost)
      - [connections[access_point].port](#connectionsaccess_pointport)
      - [connections[access_point].user](#connectionsaccess_pointuser)
      - [connections[access_point].password](#connectionsaccess_pointpassword)
  - [dbagent_conf.models](#dbagent_confmodels)
    - [fields](#fields)
      - [data_type](#data_type)
      - [use_hex](#use_hex)
      - [use_string](#use_string)
      - [extra_check](#extra_check)
      - [range](#range)
      - [convert_method](#convert_method)
        - [json_general](#json_general)
        - [json_null_to_table](#json_null_to_table)
        - [json_null_or_empty_to_null](#json_null_or_empty_to_null)
        - [json_null_or_empty_to_table](#json_null_or_empty_to_table)
        - [json_acl](#json_acl)
    - [shard_fields](#shard_fields)
    - [actions](#actions)
      - [param](#param)
      - [param.allowed_field](#paramallowed_field)
      - [param.ident](#paramident)
      - [param.index_field](#paramindex_field)
      - [param.range](#paramrange)
      - [param.extra](#paramextra)
      - [param.extra.match](#paramextramatch)
        - [param.extra.leftopen](#paramextraleftopen)
        - [param.extra.rightopen](#paramextrarightopen)
        - [param.extra.limit](#paramextralimit)
        - [param.extra.order_by](#paramextraorder_by)
        - [param.extra.group_by](#paramextragroup_by)
        - [param.extra.group_by_asc](#paramextragroup_by_asc)
        - [param.extra.group_by_desc](#paramextragroup_by_desc)
      - [rw](#rw)
      - [indexes](#indexes)
      - [default](#default)
      - [select_field](#select_field)
      - [query_opts](#query_opts)
- [Methods](#methods)
  - [api.do_api](#apido_api)
- [Author](#author)
- [Copyright and License](#copyright-and-license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->


#   Name

acid.dbagent

#   Status

This library is considered production ready.

#   Description

This library provides easy access to mysql.

#   Synopsis

```lua
-- file dbagent_conf.lua

local _M = {}

function _M.get_upstream_conf(curr_conf)
    if curr_conf ~= nil then
        ngx.sleep(5)
    end

    local value = {
        tables = {
            employee = {
                {
                    from = {'0000000000000000000'},
                    db = 'my_db_0',
                },
                {
                    from = {'1000000000000000000'},
                    db = 'my_db_1',
                },
            },
        },

        dbs = {
            ['my_db_0'] = {
                r = {
                    'my_db_0_slave',
                },
                w = {
                    'my_db_0_master',
                },
            },
            ...
        },
        connections = {
            ['my_db_0_master'] = {
                database = 'test-database',
                host = '127.0.0.1',
                port = 3500,
                user = 'user_name',
                password = '123456'
            },
        },
    }

    local conf = {
        version = 1,
        value = value,
    }

    return conf
end

_M.models = {
    employee = {
        fields = {
            employee_id = {
                data_type = 'bigint',
            },
            name = {
                data_type = 'varchar',
            },
            department = {
                data_type = 'varchar',
            },
        },

        shard_fields = {'employee_id'},

        actions = {
            set = {
                rw = 'w',
                sql_type = 'set',
                param = {
                    allowed_field = {
                        department = true,
                    },
                    ident = {
                        employee_id = true,
                    },
                    extra = {
                        match = false,
                    },
                },
            },
            get = {
                rw = 'r',
                sql_type = 'get',
                param = {
                    ident = {
                        id = true,
                    },
                    select_column = {
                        'name', 'department',
                    },
                },
                unpack_list = true,
            },
        },
    },
}

return _M

-- nginx conf

init_by_lua_block {
    local dbagent_init = require('acid.dbagent.init')
    local r, err, errmsg = dbagent_init.init()
    assert(r, err .. ', ' .. errmsg)
}

rewrite_by_lua_block {
    local dbagent_api = require('acid.dbagent.api')

    local function before_connect(connection_info)
        ngx.log(ngx.INFO, string.format('about to connect to %s:%d',
                                        connection_info.host,
                                        connection_info.port))
    end

    local function on_error(error_code, error_message)
        ngx.log(ngx.ERR, string.format('%s:%s', error_code, error_messge))
    end

    local callbacks = {
        before_connect = before_connect,
        connect_error = on_error,
    }

    dbagent_api.do_api({callbacks=callbacks})
}

-- request example

-- curl 'http://<ip>:<port>/api/v1/employee/set' -X POST -d '{"employee_id":"1000000000000000123", "department":"foo"}'

-- curl 'http://<ip>:<port>/api/v1/employee/get' -X POST -d '{"employee_id":"1000000000000000123"}'
```

#   dbagent_conf module

You need to write a file 'dbagent_conf.lua' and place it at proper place,
so that it can be loaded with `local dbagent_conf = require('dbagent_conf')`

This module must contains two attributes:

##   dbagent_conf.get_upstream_conf

Is a callback function.
Syntax is `local conf, err, errmsg = get_upstream_conf(curr_conf)`.
Argument `curr_conf` is the conf that is currently used, this
function should return new conf immediately if conf changed,
if conf still not changed after waiting for a while, then return
`curr_conf` passed in.  `conf` or `curr_conf` has same format,
 which is a table, contains two fields, 'version' and 'value'.

The upstream configuration must contains following attributes:

###   tables

Is a lua table contains sharding infomation of each database table.

```lua
shard_fields = {'employee_id'}
tables = {
    employee = {
        {
            from = {'0000000000000000000'},
            db = 'my_db_0',
        },
        {
            from = {'1000000000000000000'},
            db = 'my_db_1',
        },
    },
}

```

####   tables[table_name][n].from

The starting value of the shard_fields for each shard.

####   tables[table_name][n].db

Specify which db this shard will locate.

###   dbs

Specify all possible access points for each db.

```lua
dbs = {
    ['my_db_0'] = {
        r = {
            'my_db_0_slave',
        },
        w = {
            'my_db_0_master',
        },
    },
    ...
}
```

####   dbs[db_name].r

Access point for read operations.

####   dbs[db_name].w

Access point for write operations.

###   connections

Specify connection infomation of each access point, such as ip address,
port, password, and so on.

```
connections = {
    ['my_db_0_master'] = {
        database = 'test-database',
        host = '127.0.0.1',
        port = 3500,
        user = 'user_name',
        password = '123456'
    },
    ...
}
```

####   connections[access_point].database

The MySQL database name.

####   connections[access_point].host

The host name for the MySQL server.

####   connections[access_point].port

The port that the MySQL server is listening on.

####   connections[access_point].user

MySQL account name for login.

####   connections[access_point].password

MySQL account password for login (in clear text).

##   dbagent_conf.models

In order to use this module to access database table, you need to provide
a model module for each database table.

###   fields

Set the attributes of each field in a database table.
Following is all attributes you can set.

####   data_type

Set the data type of the field, such as 'bigint', 'varbinary' and so on. Required.
see [MySQL Data Tyeps](
'https://dev.mysql.com/doc/refman/5.7/en/data-types.html')

####   use_hex

A boolean to specify whether the field should be set and read in
hex format when the date type is 'binary' or 'varbinary'. Default to `true`.

####   use_string

A boolean to specify whether the field should be set and read in
string format when the data type is 'bigint'. Default to `true`.

####   extra_check

By default we will do some general check of the field value according
to `data_type` of the field, you can specify more specific check
by `extra_check`. Optional.

####   range

Set to `true` if this field can be used to specify range value in a
request. Default to `false`.

####   convert_method

If you use a string field to save some struct value, such as a dict,
you can specify a convert method to convert a struct to and from a string.
Optional. Following methods are supported:

#####   json_general

Use `acid.json.enc` to encode, use `acid.json.dec` to decode.
When decoding, convert `ngx.null` to `nil`.

#####   json_null_to_table

Use `acid.json.enc` to encode, use `acid.json.dec` to decode.
When decoding, convert `ngx.null` to `{}`.

#####   json_null_or_empty_to_null

Use `acid.json.enc` to encode, use `acid.json.dec` to decode.
When decoding, convert '' to `ngx.null`.

#####   json_null_or_empty_to_table

Use `acid.json.enc` to encode, use `acid.json.dec` to decode.
When decoding, convert `ngx.null` and '' to `{}`.

#####   json_acl

A specific convertor only used to encode and decode acl struct.

###   shard_fields

The fields used to do table sharding. Set to empty table if do not
need to do table sharding. Required.

###   actions

The supported operations on the database table. Required.
You can define the behaviour of each operation by set following attributes:

####   param

The allowed fields in the request. Value `true` means must be
present in request arguments, `false` means it is optional. Required.

####   param.allowed_field

The fields to insert or to set or to increase, the argument value in
request is the new value or the increment of that field.

####   param.ident

The fields that are used to identify the records that interested in.

####   param.index_field

Index fields that can be used to choose index.

####   param.range

Fields that can specify a range value in request.

####   param.extra

Some extra parameters, such as 'match', 'leftopen', 'rightopen', 'limit'.

####   param.extra.match

Specify field value to restrict the operation, only rows with fields value
equal to fields value specified in `match` are operated on or returned.

#####   param.extra.leftopen

Set to 1 corresponding to use '>', set to 0 coresponding to use '>=',
default is 0.

#####   param.extra.rightopen

Set to 1 corresponding to use '<', set to 0 coresponding to use '<=',
default is 0.

#####   param.extra.limit

Set limit of the number of rows that will be affected or fetched.

#####   param.extra.order_by

A lua table used to specify a list of fields to order by, each list
element contains two elements, field name and order type('ASC' or 'DESC').
Optional. It is used to produce SQL ORDER BY clause.

#####   param.extra.group_by

Used to specify the name of field to group by.

#####   param.extra.group_by_asc

If is not `nil`, then sort rows in ascending order.

#####   param.extra.group_by_desc

If is not `nil`, then sort rows in descending order.

####   rw

Specify operation type of the action, 'r' for read and 'w' for write.
Required.

####   indexes

Specify the indexes can be used. Optional.

####   default

Specify default value for some fields. Optional.

####   select_field

Specify the fields to return if the the atction is a read operation.
Only required in read operation.

####   query_opts

Specify options used when query msyql database, such as 'timeout'.
Optional.

#   Methods

##  init.init

Setup static attributes and schema for each field, init a timer to
update upstream configuration periodically.

**syntax**:
`init()`

**arguments**:

No arguments.

**return**:
In case of success, returns `true`, otherwise returns `nil` and
error code and error message.

##  api.do_api

Processing client request, query datebase according to the model
of each datebase table, and return query result. If falied to query
database, it will retry 2 times.

**syntax**:
`do_api(opts)`

**arguments**:

-   `opts`:
    a table contains following fields.

    -   `callbacks`: a table contains any of following callback functions.
        Optional.

        - `before_connect`: called just before connecting mysql,
           the argument is a table contains 'host' and 'port' of the
           database about to connect.

        - `after_connect`: called when connected database,
           the argument is the same as `before_connect`.

        - `connect_error`: called when failed to connect database,
           the argument is the error code and the error messge.

        - `before_query`: called just before querying,
           the argument is the sql about to query.

        - `after_query`: called when finished to query,
           the argument is the query result returned by `ngx.mysql`.

        - `query_error`: called when failed to do query,
           the argument is the same as `connect_error`.

**return**:
this function do not return.

#   Author

Renzhi (任稚) <zhi.ren@baishancloud.com>

#   Copyright and License

The MIT License (MIT)

Copyright (c) 2015 Renzhi (任稚) <zhi.ren@baishancloud.com>
