<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
#   Table of Content

- [Name](#name)
- [Status](#status)
- [Description](#description)
- [Synopsis](#synopsis)
- [Methods](#methods)
  - [sql_constructor.make_fields](#sql_constructormake_fields)
  - [sql_constructor.new](#sql_constructornew)
  - [sql_constructor.make_insert_sql](#sql_constructormake_insert_sql)
  - [sql_constructor.make_update_sql](#sql_constructormake_update_sql)
  - [sql_constructor.make_delete_sql](#sql_constructormake_delete_sql)
  - [sql_constructor.make_select_sql](#sql_constructormake_select_sql)
- [Author](#author)
- [Copyright and License](#copyright-and-license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

#   Name

acid.sql_constructor

#   Status

This library is considered production ready.

#   Description

This library is used to construct sql statement.

#   Synopsis

```lua
local sql_constructor = require('acid.sql_constructor')

local raw_fields = {
    id = {
        data_type = 'bigint',
    },
    age = {
        data_type = 'bigint',
        use_string = false,
    },
    name = {
        data_type = 'varchar',
    },
}

local fields, err, errmsg = sql_constructor.make_fields(raw_fields)
if err ~= nil then
    ngx.say('error')
end

local param = {
    allowed_field = {
        id = true, age = true, name = true,
    },
}

local args = {
    id = '123456',
    age = 28,
    name = 'bob',
}

local constructor, err, errmsg = sql_constructor.new('employee', fields)
if err ~= nil then
    ngx.say('error')
end

local sql, err, errmsg = constructor:make_insert_sql(param, args)
if err ~= nil then
    ngx.say('error')
end

-- sql
-- INSERT IGNORE INTO `employee` (`age`,`name`,`id`) VALUES (28,'bob','123456')
```

#   Methods

##   sql_constructor.make_fields

**syntax**:
`fields, err, errmsg = sql_constructor.make_fields(raw_fields)`

Add `backticked_name` and `select_expr` attribute for each field.

**arguments**:

-   `raw_fields`:
    a lua table contains attributes of each field of database table.
    You may set following attributes for each field.

    -   `data_type`:
        set the data type of the field, such as 'bigint', 'varchar'.

    -   `use_hex`:
        a boolean to specify whether the field should be set and read
        in hex format when the date type is 'binary' or 'varbinary'.
        Default to `true`.

    -   `use_string`:
        a boolean to specify whether the field should be set and read
        in string format when the data type is 'bigint'.
        Default to `true`.

**return**:
A copy of `raw_fields` with attribute `backticked_name` and
`select_expr` added to each field. In case of errors, returns `nil`
with error code and error message.

##   sql_constructor.new

**syntax**:
`constructor, err, errmsg = sql_constructor.new(table_name, fields)`

Create a new sql constructor.

**arguments**:

-   `table_name`:
    the name of the database table.

-   `fields`:
    the `fields` returned by `sql_constructor.make_fields`.

**return**:
In case of success, returns sql constructor object. In case of errors,
returns `nil` with error code and error message.

##   sql_constructor.make_insert_sql

**syntax**:
`sql, err, errmsg = constructor:make_insert_sql(param, args)`

Make insert sql statement.

**arguments**:

-   `param`:
    a lua table holding the following keys.

    -   `allowed_field`:
        a lua table used to specify fields to insert, the key is the field
        name, the value is ignored.

-   `args`:
    a lua table holding fields value.

**return**:
The insert sql statement.

```lua
local param = {
    allowed_field = {id = true, age = true, name = true},
}

local args = {
    id = '123456',
    age = 28,
    name = 'bob',
}

local sql, err, errmsg = constructor:make_insert_sql(param, args)

-- sql
-- INSERT IGNORE INTO `employee` (`age`,`name`,`id`) VALUES (28,'bob','123456')
```

##   sql_constructor.make_update_sql

**syntax**:
`sql, err, errmsg = constructor:make_update_sql(param, args, opts)`

Make update sql statement.

**arguments**:

-   `param`:
    a lua table holding the following keys.

    -   `allowed_field`:
        a lua table used to specify fields to set, the key is the field
        name, the value is ignored.

    -   `range`:
        a lua table used to specify fields that contains range value,
        the key is the field name, the value is ignored. Optional.
        It is used to produce SQL WHERE clause conditions. For example,
        if field 'a' in `args` has range value `{100, 200}`, then,
        condition '\`a\` >= 100 AND \`a\` < 200' will be added to WHERE
        clause. Range value can also be `{nil, 200}` or `{100, nil}`,
        then only '\`a\` < 200' or '\`a\` >= 100' will be added to WHERE
        clause.

    -   `ident`:
       a lua table used to specify fields that are used to identify rows
       interested in, the key is the field name, the value is ignored.
       Optional. It is used to produce SQL WHERE clause conditions.
       For example, if field 'a' in `args` has value `'foo'`, then,
       condition "\`a\`='foo'" will be added to WHERE clause.

-   `args`:
    a lua table holding fields value.

-   `opts`:
    a lua table holding following keys.

    -   `incremental`:
        set to `true` if fields value specified in `args` need to be added to
        the old fields value. Default to `false`.

    -   `match`:
        a lua table used to specify fields value, so only rows that with
        specified fields value are taken into account. Optional.
        It is used to produce SQL WHERE clause conditions.
        For example, if `match` in `opts` has value `{a=100}`, then,
        condition '\`a\`=100' will be added to WHERE clause.

    -   `leftopen`:
        if set to `1`, then use `>` instead of `>=` when produce condition
        from range value. Default to `0`.

    -   `rightopen`:
        if set to `0`, then use `<=` instead of `<` when produce condition
        from range value. Default to `1`.

    -   `limit`:
        set limit of the number of rows that can be updated. Optional.

**return**:
The update sql statement.

```lua
local param = {
    allowed_field = {
        age = true,
    },
    ident = {
        id = true,
    },
},
local args = {
    age = 28,
    id = '123456'
},
local opts = {
    match = {name = 'bob'},
},

local sql, err, errmsg = constructor:make_update_sql(param, args, opts)

-- sql
-- UPDATE IGNORE `employee` SET `age`=28 WHERE `id`='123456' AND `name`='bob'
```

##   sql_constructor.make_delete_sql

**syntax**:
`sql, err, errmsg = constructor:make_delete_sql(param, args, opts)`

Make delete sql statement.

**arguments**:

-   `param`:
    a lua table holding the following keys.

    -   `range`:
        same as `range` in [make_update_sql](#sql_constructormake_update_sql).

    -   `ident`:
        same as `ident` in [make_update_sql](#sql_constructormake_update_sql).

-   `args`:
    a lua table holding field values.

-   `opts`:
    a lua table holding following keys.

    -   `match`:
        same as `match` in [make_update_sql](#sql_constructormake_update_sql).

    -   `leftopen`:
        same as `leftopen` in [make_update_sql](#sql_constructormake_update_sql).

    -   `rightopen`:
        same as `rightopen` in [make_update_sql](#sql_constructormake_update_sql).

    -   `limit`:
        same as `limit` in [make_update_sql](#sql_constructormake_update_sql).

**return**:
The delete sql statement.

```lua
local param = {
    range = {
        age = true,
    },
},
local args = {
    age = {20, 30},
},
local opts = {
    match = {name = 'bob'},
    leftopen = 1
},

local sql, err, errmsg = constructor:make_delete_sql(param, args, opts)

-- sql
-- DELETE IGNORE FROM `employee` WHERE `age`>20 AND `age`<30 AND `name`='bob'
```

##   sql_constructor.make_select_sql

**syntax**:
`sql, err, errmsg = constructor:make_select_sql(select_field, param, args, opts)`

Make select sql statement.

**arguments**:

-   `select_field`:
    a lua table holding a list of fields to select.

-   `param`:
    a lua table holding the following keys.

    -   `range`:
        same as `range` in [make_update_sql](#sql_constructormake_update_sql).

    -   `ident`:
        same as `ident` in [make_update_sql](#sql_constructormake_update_sql).

-   `args`:
    a lua table holding fields value.

-   `opts`:
    a lua table holding following keys.

    -   `select_expr_list`:
        specify select expression list to use, if not set, select expression
        list will be build from `select_field`.

    -   `index_condition`:
        specify condition list build from index fields. Optional.
        It will be added to WHERE clause.

    -   `force_index_clause`:
        specify a force index clause. Optional.

    -   `match`:
        same as `match` in [make_update_sql](#sql_constructormake_update_sql).

    -   `group_by_clause`:
        specify a group by clause. Optional.

    -   `order_by`:
        a lua table used to specify a list of fields to order by,
        each list element contains two elements, field name and
        order type('ASC' or 'DESC'). Optional. It is used to produce
        SQL ORDER BY clause.

    -   `leftopen`:
        same as `leftopen` in [make_update_sql](#sql_constructormake_update_sql).

    -   `rightopen`:
        same as `rightopen` in [make_update_sql](#sql_constructormake_update_sql).

    -   `limit`:
        set limit of the number of rows that can be returned. Optional.

**return**:
The select sql statement.

```lua
local select_field = {'id', 'age', 'name'},
local param = {
    range = {
        age = true
    },
},
local args = {
    age = {20, 30},
},
local opts = {
    index_condition = '`id`>"123456"',
    order_by = {
        {'age', 'ASC'},
        {'name', 'DESC'},
    },
}
local sql, err, errmsg = constructor:make_select_sql(
        select_field, param, args, opts)

-- sql
-- SELECT CAST(`id` AS CHAR) as `id`,`age`,`name` FROM `employee` WHERE `id`>"123456" AND `age`>=20 AND `age`<30 ORDER BY `age` ASC, `name` DESC
```

#   Author

Renzhi (任稚) <zhi.ren@baishancloud.com>

#   Copyright and License

The MIT License (MIT)

Copyright (c) 2015 Renzhi (任稚) <zhi.ren@baishancloud.com>
