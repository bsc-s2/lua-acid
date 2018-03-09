<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
#   Table of Content

- [Name](#name)
- [Status](#status)
- [Description](#description)
- [Synopsis](#synopsis)
- [Schema](#schema)
  - [schema.arg_name](#schemaarg_name)
  - [schema.arg_schema](#schemaarg_schema)
    - [schema.arg_schema.required](#schemaarg_schemarequired)
    - [schema.arg_schema.checker](#schemaarg_schemachecker)
      - [schema.arg_schema.checker[1].type](#schemaarg_schemachecker1type)
        - [any](#any)
        - [bool](#bool)
        - [integer](#integer)
        - [float](#float)
        - [string](#string)
        - [string_number](#string_number)
        - [array](#array)
        - [dict](#dict)
- [Methods](#methods)
  - [arg_schema_checker.check_arguments](#arg_schema_checkercheck_arguments)
- [Author](#author)
- [Copyright and License](#copyright-and-license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

#   Name

acid.arg_schema_checker

#   Status

This library is considered production ready.

#   Description

This library is used to check input args according to schema.

#   Synopsis

```lua
local arg_schema_checker = require('acid.arg_schema_checker')

local args = {
    a = 1,
    b = {1, 2},
    c = {
        foo = {},
    },
}

local schema = {
    a = {
        required = true,
        checker = {
            ['type'] = 'integer',
            enum = {1, 2, 3, 4},
        },
    },
    b = {
        checker = {
            ['type'] = 'array',
            element_checker = {
                ['type'] = 'integer',
            },
        },
    },
    c = {
        checker = {
            ['type'] = 'dict',
            sub_schema = {
                foo = {
                    required = true,
                    checker = {
                        ['type'] = 'dict',
                    },
                },
            },
        },
    },
}

local _, err, errmsg = arg_schema_checker.check_arguments(args, schema)
if err ~= nil then
    ngx.log(ngx.ERR, string.format('invalid input args: %s, %s', err, errmsg))
end
```

#   Schema

```lua
local arg_name = 'a'

local arg_schema = {
    required = true,
    checker = {
        ...
    },
}

local schema = {
    arg_name = arg_schema,
}
```

##   schema.arg_name

Specify argument name.

##   schema.arg_schema

Specify argument schema.

###   schema.arg_schema.required

A boolean to specify whether this argument must be presented in input args.
If set to `true`, `schema.arg_schema.checker.type` must be specified.

###   schema.arg_schema.checker

A list of dicts, each dict specify a possible type of this argument's value.
Each dict must have a field 'type', which can have following values:
'any', 'array', 'bool', 'dict', 'float', 'integer', 'string_number',
'string'. If the list has noly one element, you can specify
`schema.arg_schema.checker` as a dict directly.

####   schema.arg_schema.checker[1].type

#####   any

Mean value of the argment can be anything.

#####   bool

Mean value of the argument cat be `true` or `false`.

#####   integer

Mean value of the argument can only be an integer.
You can also specify value range by `min` and `max`, or specify
enum values by `enum`, or specify excluded values by `not`.
`enum` and `not` must be a table, single value is not allowed.

```lua
{
    ['type'] = 'integer',
    -- min = 0,
    -- max = 100,
    -- enum = {1, 3, 5},
    -- ['not'] = {38, 44},
}
```

#####   float

Mean value of the argument can be a float number, integer is also allowed.
You can also specify `min`, `max`, `enum` and `not`.

#####   string

Mean value of the argument can only be a string.
You can also specify string length by `fixed_length`, or specify
string length range by `min_length` and `max_length`, or specify
enum values by `enum`, or specify excluded values by `not`, or
specify a regular expression to be matched by `regexp`.  `enum` and
`not` must be a table, single value is not allowed.

```lua
{
    ['type'] = 'string',
    -- fixed_length = 32,
    -- min_length = 1,
    -- max_length = 64,
    -- enum = {'foo', 'bar'},
    -- ['not'] = {'fooo', 'barr'},
    -- regexp = '^[a-c]{3}$',
}
```

#####   string_number

Mean value of the argument must be a string that can represent a valid number.
You can also specify `min`, `max`, `enum` and `not`.

#####   array

Mean value of the argument must be an array represented by a lua table.
Such as `{1, 2, 3, 4}`.
You can also specify array length by `fixed_length`, or specify
array length range by `min_length` and `max_length`, or specify
allowed types of each element by `element_checker`.

```lua
{
    ['type'] = 'array',
    -- fixed_length = 3,
    -- min_length = 1,
    -- max_length = 4,
    -- element_checker = {
    --     ['type'] = 'integer',
    --     enum = {1, 2, 3, 4},
    -- }
    -- element_checker = {
    --     {
    --         ['type'] = 'integer',
    --     },
    --     {
    --         ['type'] = 'string',
    --     },
    -- }
}
```

#####   dict

Mean value of the argument must be a dict represented by a lua table.
You can also specify length of the array part of the table by `fixed_length`,
or specify the length range by `min_length` and `max_length`, or specify
allowed types for the key of the dict by `key_checker`, or specify allowed
types for the value of the dict by `value_checker`, or specify a schema
which will be used to check the dict as input args by `sub_schema`.

```lua
{
    ['type'] = 'dict',
    -- fixed_length = 1,
    -- min_length = 1,
    -- max_length = 100,
    -- key_checker = {
    --     {
    --         ['type'] = 'integer',
    --     },
    --     {
    --         ['type'] = 'string',
    --     },
    -- },
    -- value_checker = {
    --     ['type'] = 'string',
    -- },
    -- sub_schema = {
    --     foo = {
    --         required = true,
    --         checker = {
    --             ['type'] = 'string',
    --         },
    --     },
    -- },
}
```

#   Methods

##   arg_schema_checker.check_arguments

**syntax**:
`local _, err, errmsg = arg_schema_checker.check_arguments(args, schema)`

**arguments**:

-   `args`:
    The input arguments.

-   `schema`:
    The schema of the input arguments.

**return**:
If the input arguments match the specified schema, return `true`, or
return `false` followed by error code and error message.

#   Author

Renzhi (任稚) <zhi.ren@baishancloud.com>

#   Copyright and License

The MIT License (MIT)

Copyright (c) 2015 Renzhi (任稚) <zhi.ren@baishancloud.com>
