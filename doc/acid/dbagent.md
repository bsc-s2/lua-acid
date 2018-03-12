<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
#   Table of Content

- [Name](#name)
- [Status](#status)
- [Description](#description)
- [Synopsis](#synopsis)
- [Methods](#methods)
  - [init.init](#initinit)
  - [api.do_api](#apido_api)
- [Model](#model)
  - [fields](#fields)
    - [field_type](#field_type)
    - [m](#m)
    - [no_hex](#no_hex)
    - [no_string](#no_string)
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
    - [valid_param](#valid_param)
      - [valid_param.column](#valid_paramcolumn)
      - [valid_param.ident](#valid_paramident)
      - [valid_para.match](#valid_paramatch)
      - [valid_param.index_columns](#valid_paramindex_columns)
      - [valid_param.range](#valid_paramrange)
      - [valid_param.extra](#valid_paramextra)
        - [valid_param.extra.leftopen](#valid_paramextraleftopen)
        - [valid_param.extra.rightopen](#valid_paramextrarightopen)
        - [valid_param.extra.nlimit](#valid_paramextranlimit)
        - [valid_param.extra.order_by](#valid_paramextraorder_by)
        - [valid_param.extra.group_by](#valid_paramextragroup_by)
        - [valid_param.extra.group_by_asc](#valid_paramextragroup_by_asc)
        - [valid_param.extra.group_by_desc](#valid_paramextragroup_by_desc)
    - [rw](#rw)
    - [indexes](#indexes)
    - [default](#default)
    - [select_column](#select_column)
    - [query_opts](#query_opts)
- [Conf](#conf)
  - [tables](#tables)
  - [dbs](#dbs)
  - [connections](#connections)
      - [database](#database)
      - [host](#host)
      - [port](#port)
      - [user](#user)
      - [password](#password)
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
init_worker_by_lua_block {
    local dbagnet_init = require('acid.dbagent.init')

    local function get_conf(curr_conf)
        if curr_conf ~= nil then
            ngx.sleep(5)
        end

        local value = {
            connections = {
                ['3500-1'] = {
                    database = 'test-database',
                    host = '127.0.0.1',
                    port = 3500,
                    user = 'user_name',
                    password = '123456'
                },
            },

            tables = {
                key = {
                    {
                        from = {'1000000000000000000', '', ''},
                        db = '3500',
                    },
                },
            },

            dbs = {
                ['3500'] = {
                    r = {
                        '3500-1',
                    },
                    w = {
                        '3500-1',
                    },
                },
            },
        }

        local conf = {
            version = 1,
            value = value,
        }

        return conf
    end

    local opts = {
        model_module_dir = '/path/to/dir',
        get_conf = get_conf,
    }

    dbagent_init.init(opts)
}

rewrite_by_lua_block {
    local dbagent_api = require('acid.dbagent.api')

    local function before_connect_db(connection_info)
        ngx.log(ngx.INFO, string.format('about to connect to %s:%d',
                                        connection_info.host,
                                        connection_info.port))
    end

    local function on_error(error_code, error_message)
        ngx.log(ngx.ERR, string.format('%s:%s', error_code, error_messge))
    end

    local function before_query_db(sql)
        ngx.log(ngx.INFO, 'about to query: ' .. sql)
    end

    local function after_query_db(query_result)
        ngx.log(ngx.INFO, 'query result: ' .. tostring(query_result))
    end

    local callbacks = {
        before_connect_db = before_connect_db,
        connect_db_error = on_error,
        before_query_db = before_query_db,
        after_query_db = after_query_db,
        query_db_error = on_error,
    }

    dbagent_api.do_api({callbacks=callbacks})
}
```

#   Methods

## init.init

**syntax**:
`init(opts)`

Load model modules and setup a timer to update conf immediately if
the conf changed.

**arguments**:

-   `opts`:
    a table contains following fields.

    -   `model_module_dir`: the directory where model modules located.
        For example, if the model module file is
        '/path/to/dir/models/bucket.lua', then set `model_module_dir`
        to '/path/to/dir'. Required.

    -   `get_conf`: a callback function, syntax is
        `conf, err, errmsg = get_conf(curr_conf)`, curr_conf is
        the conf that is currently used, this function should return
        new conf immediately if conf changed, if conf still not changed
        after waiting for a while, then return `curr_conf` passed in.
        `conf` or `curr_conf` has same format, which is a table, contains
        two fields, 'version' and 'value'. Required.


**return**:
nothing

##  api.do_api

**syntax**:
`do_api(opts)`

**arguments**:

-   `opts`:
    a table contains following fields.

    -   `callbacks`: a table contains any of following callback functions.
        Optional.

        - `before_connect_db`: called just before connecting mysql,
           the argument is a table contains 'host' and 'port' of the
           database about to connect.

        - `after_connect_db`: called when connected database,
           the argument is the same as `before_connect_db`.

        - `connect_db_error`: called when failed to connect database,
           the argument is the error code and the error messge.

        - `before_query_db`: called just before querying,
           the argument is the sql about to query.

        - `after_query_db`: called when finished to query,
           the argument is the query result returned by `ngx.mysql`.

        - `query_db_error`: called when failed to do query,
           the argument is the same as `connect_db_error`.

**return**:
this function do not return.

#   Model

In order to use this module to access mysql table, you need to provide
a model module for each table, following is an example.

```lua
local tableutil = require('acid.tableutil')


local _M = {}


_M.fields = {
    a = {
        field_type = 'bigint',
        m = 20,
        no_string = true,
    },
    b = {
        field_type = 'varbinary',
        m = 4,
        no_hex = true,
        extra_check = {
            enum = {'succ', 'fail'},
        },
    },
    c = {
        field_type = 'varbinary',
        m = 512,
        no_hex = true,
    },
    d = {
        field_type = 'bigint',
        m = 20,
        range = true,
    },
    e = {
        field_type = 'tinyint',
        m = 4,
    },
    f = {
        field_type = 'binary',
        m = 16,
    },
    g = {
        field_type = 'text',
        m = nil,
        convert_method = 'json_null_or_empty_to_table',
    },
}


_M.shard_fields = {
    'a',
    'b',
    'c',
}


local add_column = {}
for field_name, _ in pairs(_M.fields) do
    add_column[field_name] = true
end

local ident = {
    a = true,
    b = true,
    c = true,
    d = false,
}

local match = {
    _e = false,
    _f = false,
}

_M.actions = {
    add = {
        rw = 'w',
        valid_param = {
            column = add_column,
        },
        default = {g = '{}'},
    },
    set = {
        rw = 'w',
        valid_param = {
            column = {
                e = false,
                f = false,
            },
            ident = ident,
            match = match,
        },
    },
    remove = {
        rw = 'w',
        valid_param = {
            ident = ident,
            match = match,
        },
    },
    get = {
        rw = 'r',
        valid_param = {
            ident = ident,
            match = match,
        },
        select_column = tableutil.keys(_M.fields),
        unpack_list = true,
    },
    ls = {
        rw = 'r',
        indexes = {
            idx_a_b_c_d = {
                'a', 'b', 'c', 'd',
            },
        },
        valid_param = {
            index_columns = {
                a = true,
                b = true,
                c = true,
                d = false,
            },
            match = match,
            extra = {
                leftopen = false,
                nlimit = false,
            },
        },
        select_column = tableutil.keys(_M.fields),
    },
}


return _M
```

## fields

Set the attributes of each field in a database table.

### field_type

Set the type of the field, such as 'bigint', 'varbinary' and so on. Required.
see [MySQL Data Tyeps](
'https://dev.mysql.com/doc/refman/5.7/en/data-types.html')

### m

The length or display width of the field, used to check the input argument.
Required.

### no_hex
By default, 'varbinary' and 'binary' fields will be set and read in
hex format, if this is not expected, set `no_hex` to `true`. Optional.

### no_string
By default, 'bigint' fields will be set and read in
string format, if this is not expected, set `no_string` to `true`.
Optional.

### extra_check
By default we will do some general check of the field value according
to `field_type` of the field, you can specify more specific check
by `extra_check`. Optional.

### range
Set to `true` if this field can be used to specify range value in a
request, the range value is a string, contains two normal field value,
seprated by a comma. For example, if field value of 'd' in request is
'1000,2000', then, '`d` >= 1000 AND `d` <= 2000' will be added to the
select sql. Optional.

### convert_method
If you use a string field to save some struct value, such as a dict,
you can specify a convert method to convert a struct to and from a string.
Optional. Following methods are supported:

#### json_general
Use `acid.json.enc` to encode, use `acid.json.dec` to decode.
When decoding, convert `ngx.null` to `nil`.

#### json_null_to_table
Use `acid.json.enc` to encode, use `acid.json.dec` to decode.
When decoding, convert `ngx.null` to `{}`.

#### json_null_or_empty_to_null
Use `acid.json.enc` to encode, use `acid.json.dec` to decode.
When decoding, convert '' to `ngx.null`.

#### json_null_or_empty_to_table
Use `acid.json.enc` to encode, use `acid.json.dec` to decode.
When decoding, convert `ngx.null` and '' to `{}`.

#### json_acl
A specific convertor only used to encode and decode acl struct.

## shard_fields

The fields used to do table sharding. Set to empty table if do not
need to do table sharding. Required.

## actions

The supported operations on the database table. Required.

### valid_param

The valid fields in the request. Value `true` means must be
present in request arguments, `false` means it is optional. Required.

#### valid_param.column

The fields to set, the argument value in request is the new value of
that field.

#### valid_param.ident

The fields that are used to identify the records that interested in.

#### valid_para.match

Fields used to restrict the operation, only records with field values
equal to values specified in request are operated on or returned.

#### valid_param.index_columns

Index fields that can be used to choose index.

#### valid_param.range

Fields that can specify a range value in request.

#### valid_param.extra

Some extra parameters, such as 'leftopen', 'rightopen', 'nlimit'.

##### valid_param.extra.leftopen

Set to 1 corresponding to use '>', set to 0 coresponding to use '>=',
default is 0.

##### valid_param.extra.rightopen

Set to 1 corresponding to use '<', set to 0 coresponding to use '<=',
default is 0.

##### valid_param.extra.nlimit

Set number of rows to fetch.

##### valid_param.extra.order_by

Used to sort the records in result set. You can order result by several
fields, you can also specify 'ASC' or 'DESC' for each field. Such as
'user_age DESC, user_name ASC' means first sort in descending order by
field 'user_age', then sort in ascending order by 'user_name'.

##### valid_param.extra.group_by

Used to group the results by one column, and return the count of each group.

##### valid_param.extra.group_by_asc

If is not `nil`, then sort count in ascending order.

##### valid_param.extra.group_by_desc

If is not `nil`, then sort count in descending order.

### rw

Specify operation type of the action, 'r' for read and 'w' for write.
Required.

### indexes

Specify the indexes can be used. Only required in `ls` action.

### default

Specify default value for some fields. Optional.

### select_column

Specify the clomuns to return if the the atction is a read operation.
Only required in read operation.

### query_opts

Specify options used when query msyql database, such as 'timeout'.
Optional.

#   Conf

The conf tells which table located in which database and how to connect to
each database.

## tables

Specify the sharding infomation of each table. Required.

```
{
    key = {
        {
            from = {'1000000000000000000', '', ''},
            db = '3500',
        },
        {
            from = {'1100000000000000000', '', ''},
            db = '3501',
        },
        ...
    },
    ...
}
```

## dbs

Specify all possible access points for each database. Required.

```
{
    dbs = {
        ['3500'] = {
            r = {
                '3500-1', '3500-2',
            },
            w = {
                '3500-1'
            },
        },
        ...
    }
}
```

## connections

Specify connection infomation of each access point, such as ip address,
port, password, and so on. Required.

```
{
    connections = {
        ['3500-1'] = {
            database = 'test-database',
            host = '127.0.0.1',
            port = 3500,
            user = 'user_name',
            password = '123456'
        },
        ...
    }
}
```

#### database

The database name.

#### host

The ip address of the database instance.

#### port

The port of the database instance.

#### user

The user name used to access the database.

#### password

The password used to access the database.

#   Author

Renzhi (任稚) <zhi.ren@baishancloud.com>

#   Copyright and License

The MIT License (MIT)

Copyright (c) 2015 Renzhi (任稚) <zhi.ren@baishancloud.com>
