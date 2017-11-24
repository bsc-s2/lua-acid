<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
#   Table of Content

- [Name](#name)
- [Status](#status)
- [Description](#description)
- [Methods](#methods)
  - [tableutil.add](#tableutiladd)
  - [tableutil.addto](#tableutiladdto)
  - [tableutil.combineto](#tableutilcombineto)
  - [tableutil.combine](#tableutilcombine)
  - [tableutil.contains](#tableutilcontains)
  - [tableutil.default_setter](#tableutildefault_setter)
  - [tableutil.depth_iter](#tableutildepth_iter)
  - [tableutil.dup](#tableutildup)
  - [tableutil.duplist](#tableutilduplist)
  - [tabelutil.eq](#tabelutileq)
  - [tableutil.extends](#tableutilextends)
  - [tableutil.get](#tableutilget)
  - [tableutil.set](#tableutilset)
  - [tableutil.get_len](#tableutilget_len)
  - [tableutil.has](#tableutilhas)
  - [tableutil.intersection](#tableutilintersection)
  - [tableutil.is_empty](#tableutilis_empty)
  - [tableutil.iter](#tableutiliter)
  - [tableutil.keys](#tableutilkeys)
  - [tableutil.make_setter](#tableutilmake_setter)
  - [tableutil.merge](#tableutilmerge)
  - [tableutil.nkeys](#tableutilnkeys)
  - [tableutil.random](#tableutilrandom)
  - [tableutil.remove_all](#tableutilremove_all)
  - [tableutil.remove_value](#tableutilremove_value)
  - [tableutil.union](#tableutilunion)
  - [tableutil.update](#tableutilupdate)
- [Author](#author)
- [Copyright and License](#copyright-and-license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

#   Name

tableutil

#   Status

This library is considered production ready.

#   Description

`tableutil` provides with several table operation utilities.
Most of them are in python style.


#   Methods

## tableutil.add
It is a alias as `tableutil.combine(a,b,function(x, y) return x + y end,opts)`
See more details about at [tableutil.combine](#tableutilcombine)

## tableutil.addto
It is a alias as `tableutil.combineto(a,b,function(x, y) return x + y end,opts)`
See more details about at [tableutil.combineto](#tableutilcombineto)

##  tableutil.combineto

**syntax**:
`tableutil.combineto(a, b, operator, opts)`

Combine table `b` to table `a`.

If `opts.default` is a number value, key not existed in `a` but in `b` has a default value.
If `opts.recursive` is `true`, we do combineto recursively.
If `opts.exclude` is not nil, the key in exclude will be ignored.

**Usage**

```
local a = {x={y=3,z=1}}
local b = {x={y=3,z=1}}
local opts = {opts.exclude={x={z=true}}}
tableutil.combineto(a, b,function(x, y) return x + y end,opts)
print(a)

--output
{x={y=6,z=1}}
```

**arguments**:

-   `a`:
    is a table.

-   `b`:
    is a table.

-   `opts`:
    `opts.default` can be nil or a number value.
    Default is nil.
    If `opts.default` is a number value,
    then use `opts.default` as default value
    to add when key is existed in `b` but nil in `a`.

    `opts.recursive` can be true or false.
    Default is false.
    If `opt.recursive` is `true`, do combineto recursively.

    `opts.exclude` can be nil or or a table.
    Default is nil.
    If `exclude = {x={y={z=true}}}`,then `b[x][y][z]` will be ignored.

-   `operator`
    `operator` is function.
    It accept two number parameters, and return a single number value.

**return**:
Nothing.

##  tableutil.combine

**syntax**:
`tableutil.combine(a, b, operator, opts)`

Combine table `b` with table `a`, return a new table.

If `opts.default` is a number value, key not existed in `a` but in `b` has a default value.
If `opts.recursive` is `true`, we do combineto recursively.
If `opts.exclude` is not nil, the key in exclude will be ignored.

**arguments**:

-   `a`:
    is a table.

-   `b`:
    is a table.

-   `opts`:
    `opts.default` can be nil or a number value.
    Default is nil.
    If `opts.default` is a number value,
    then use `opts.default` as default value
    to add when key is existed in `b` but nil in `a`.

    `opts.recursive` can be true or false.
    Default is false.
    If `opt.recursive` is `true`, do combineto recursively.

    `opts.exclude` can be nil or a table.
    If `exclude = {x={y={z=true}}}`,then `b[x][y][z]` will be ignored.

-   `operator`
    `operator` is function.
    It accept two number parameters, and return a single number value.

**return**:
a table.

##  tableutil.contains

**syntax**:
`tableutil.contains(a, b)`

Check if table `a` contains table `b`.

**Contain** means `key_path` for `b` is a subset of `key_path` for `a`.

To explain this concept, we need two definitions:

-   `key_path`: is a series of table keys to access (nested) table field.
    For example, there is a table `a = {x={y=3}}`, key path `.x.y` is used to
    access `3`.

    A **non-leaf** `key_path` is a prefix of some other `key_path` and is used
    to access an intermediate table, such as `.x`.

    A **leaf** `key_path` is **NOT** a prefix of any other `key_path` and is
    used to access a primitive value, such as `.x.y`.

-   `contain`:
    There are two table `a` and `b`.
    For any finite `key_path` `pb` in `b`, if:

    -   `pb` is also a valid `key_path` in `a`,
    -   and: if `pb` is a leaf `key_path`, the value referred with `pb` in `a`
        and the value referred with `pb` in `b` are the same.

    then `a` contains `b`.

    Example:

    ```
    a = {x=1}
    b = {x=1, y=2}
    ```

    In the above example the only `key_path` in `a` is `.x` which is also a valid `key_path`
    in `b` and `a.x == b.x`. Thus `b contains a`.

    But `a does NOT contain b` because `.y` in `b` is not a valid `key_path` in
    `a`.

    ```
    a = {x={}}
    b = {x=1, y=2}
    ```

    In the above example `b does NOT contains a` because `a.x` is a table but
    `b.x` is a number.

    ```
    a = {x={}}
    b = {x={x={}}}
    a.x.x = a
    b.x.x.x = b
    ```

    In the above example `b contains a` and `a contains b` because they both
    have the same key path set: `(.x)+`:

    ```

    .x
    .x.x
    .x.x.x
    ...

    .------x-------.
    |              |
    `-> a -x-> {} -'

    .----------x----------.
    |                     |
    `-> b -x-> {} -x-> {}-'

    ```

>   If a and b are both primitive type, "contains" is defined by a==b.

---

The algorithm to compare two table recursively:

For tables with circular references, such as:

```
a.x.x = a
b.x.x.x = b

and

a.x.x = b
b.x.x.x = a
```

We compare two tables by comparing every `key_path` in them.
In the above two examples, `a` and `b` contain each other, because the
set of `key_path` in `a` and `b` are both: `(.x)+`.

Algorithm:

-   Depth first traverse `b` to iterate all possible leaf and non-leaf `key_path` in it.

-   And check if this `key_path` is also valid in `a`.

-   If a `key_path` is a leaf `key_path`, the values this `key_path` referring
    in `a` and `b` must be the same.

-   If a `key_path` is a non-leaf `key_path`, and they points to a pair of nodes
    we have already compared, stop traversal of this `key_path`, because further
    traversal does not produce more possible `key_path`.

    Thus we record every pair of `a` tree node and `b` tree node that we have
    compared in the traversal.

---

**arguments**:

-   `a`:
    is a containing table or primitive type value.

-   `b`:
    is a contained table or primitive type value.

**return**:
`true` if `a` contains `b`. Or `false`


##  tableutil.default_setter

Same as `tableutil.make_setter`, except that the setter always keep existent
table fields.

**syntax**:
`tableutil.default_setter(key, val)`

**return**:
a function to set table fileds in form of `function(tbl) ... end`.


##  tableutil.depth_iter

**syntax**:
`tableutil.depth_iter(tbl)`

Get an iterator which returns a key_path-value pair sorted by key_path once
called.
Value is a primitive value, and key_path is a list of series keys access to
the value.
See more details about **key_path** at [tableutil.contains](#tableutilcontains).

**Usage**

```
local tbl = {1, a = {
                   b = {
                      c = 'c'}},
             }

for kp, v in depth_iter(tbl) do
    print(table.concat(kp, '.') .. ':' .. v)
end

-- output:

1:1
a.b.c:c
```

**arguments**:

-   `tbl`:
    is a table.

**return**:
an iterator function.

##  tableutil.dup

**syntax**:
`tableutil.dup(tbl, deep)`

If `tbl` is not table, return `tbl`.
Or get a copy of `tbl`. Do deep copy if `deep` is true, shallow copy else.
Support copying a table with circular reference.

**arguments**:

-   `tbl`:
    is a table or a primitive value.

-   `deep`:
    is a boolean, do deep copy if `deep` is `true`, shallow copy else.
    `deep` is `nil` by default.

**return**:
the first argument `tbl` itself if `tbl` is not a table, or a table.

## tableutil.duplist

**syntax**:
`tableutil.duplist(tbl, deep)`

If `tbl` is not a table, return `{}`.
Or copy int number indexed values in table `tbl` until the first nil value found.
Do deep copy if `deep` is `true`, shallow copy else.
Support copying a table with circular reference.

**arguments**:

-   `tbl`:
    is a table or a primitive.

-   `deep`:
    is a boolean, deep copy if `deep` is true, shallow copy else.
    `deep` is `nil` by default.

**return**:
a list table.

##  tabelutil.eq

**syntax**:
`tableutil.eq(a, b)`

Check if table `a` and table `b` is equal, which means `a` contains `b` and `b`
contains `a`.
See more details about **contain** at [tableutil.contains](#tableutilcontains).

**arguments**:

-   `a`:
    is a table or a primitive value.

-   `b`:
    is a table or a primitive value.

**return**:
`true` if `a` equals `b`, `false` else.

##  tableutil.extends

**syntax**:
`tableutil.extends(tbl, tvals)`

Return `tbl` if `tbl` is not a table.
Or add `tvals[i]` to `tbl` until `tvals[i]` is nil. i = (1,2,3...).

**arguments**:

-   `tbl`:
    is a table or a primitive value.

-   `tvals`:
    is a table.

**return**:
the first argument `tbl` itself.

##  tableutil.get

**syntax**:
`tableutil.get(tbl, keys)`

Get the value **by key path** `keys` in table `tbl` if found.
Or return `nil` and error message.
See more detail about **key path** at [tableutil.contains](#tableutilcontains).

**Usage**

```
local tbl = {x={y=3}}
local keys = 'x.y'
print(tableutil.get(tbl, keys))

--output

3
```

**arguments**:

-   `tbl`:
    is a table.

-   `keys`:
    is a string **key path** of table `tbl`.
    For example, there is a table `a = {x={y=3}}`, key path `x.y` is used
    to access `3`.

**return**:
the value `keys` access to if found in `tbl`. Or nil and error message.

##  tableutil.set

**syntax**:
`tableutil.set(tbl, keys, value, opts)`

Set the value **by key path** `keys` in table `tbl`.
See more detail about **key path** at [tableutil.contains](#tableutilcontains).

**Usage**

```
print(tableutil.set({}, 'x.y', 123))
print(tableutil.set({x=1}, 'x.y', 123, {override=true}))
print(tableutil.set({x={y=1}}, 'x.y', 123, {override=true}))
print(tableutil.set({x={y=1}}, 'x.y', {z=123}, {override=true}))

--output

{x={y=123}}
{x={y=123}}
{x={y=123}}
{x={y={z={123}}}
```

**arguments**:

-   `tbl`:
    is a table.

-   `keys`:
    is a string **key path** of table `tbl` to set.

-   `value`:
    is the value to set.

-   `opts`:
    `opts.override` can be `true` or `false`.
    Default is `false`.
    If the **key path** exits in `tbl`, if `opts.override` is `true`,
    the existed value of the **key path** will be changed to `value`,
    if `opts.override` is not `true`, this function will return error.
    If any prefix of **key path** exits in `tbl`, and it's value is not a
    table, if `opts.override` is `ture`, then it's value will be set to a
    table, the old value will lost, if `opts.override` is not `ture`, this
    function will return error.

**return**:
The `tbl`. Or nil and error message.

##  tableutil.get_len

**syntax**:
`tableutil.get_len(tbl)`

Get the number of all key-value pairs in `tbl`.

**arguments**:

-   `tbl`:
    is a table.

**return**:
a number.

##  tableutil.has

**syntax**:
`tableutil.has(tbl, value)`

Check if `value` is one of the values in `tbl`.
`nil` is always in `tbl`.

**arguments**:

-   `tbl`:
    is a table.

-   `value`:
    is the value to check.

**return**:
`true` if `value` is in `tbl`, else `false`.

##  tableutil.intersection

**syntax**:
`tableutil.intersection(tables, val)`

Get a table whose keys are shared by all tables in `tables`.
If `val` is not `nil`, every values of these keys are `val`.
Or the values of these keys in first table of `tables`.

**Usage**:

```

local tbl1 = {1, a='a', b='b'}
local tbl2 = {1, a='b', c='c'}
local tbl3 = {1, a='c', d='c'}

for k,v in pairs(tableutil.intersection({tbl1, tbl2, tbl3}, '0')) do
    print(k..':'..v)
end

--output

1:0
a:0
```

**arguments**:

-   `tables`:
    is a list table filled with tables.

-   `val`:
    is a value assigned to shared keys.

**return**:
a table.

##  tableutil.is_empty

**syntax**:
`tableutil.is_empty(tbl)`

Check whether `tbl` is empty.

**arguments**:

-   `tbl`:
    is a table.

**return**:
`true` if `tbl` is empty, `false` else.

##  tableutil.iter

**syntax**:
`tableutil.iter(tbl)`

Get an iterator which returns a key-value pair of `tbl` sorted by key once
called.

**Usage**:

```
local tbl = {1, b = 'b', 2, a = 'a'}
for k, v in iter(tbl) do
    if type('v') ~= 'table' then
        print(k..":"..v)
    end
end

--output

1:1
2:2
a:a
b:b
```

**arguments**:

-   `tbl`:
    is a table.

**return**:
an iterator function.

## tableutil.keys

**syntax**:
`tableutil.keys(tbl)`

Get all keys in table `tbl`.

**arguments**:

-   `tbl`:
    is a table.

**return**:
a list table filled with all keys in `tbl`.


##  tableutil.make_setter

Make a table setter function to set table fields.
Return value is a function in form of:

```lua
function(tbl)
    -- ...
end
```

**Synopsis**:

```lua
-- set one key
local setter = tableutil.make_setter('a', 5, mode='keep')
local tbl = {x=3}
setter(tbl)
-- tbl = {a=5, x=3}

-- set multiple keys:
local setter = tableutil.make_setter({a=5, x=6, y=7}, nil, mode='keep')
local tbl = {x=3}
setter(tbl)
-- tbl = {a=5, x=3, y=7}

-- value is a function
local setter = tableutil.make_setter({a=5, x=6, y=function() return 7 end}, nil, mode='keep')
local tbl = {x=3}
setter(tbl)
-- tbl = {a=5, x=3, y=7}
```

**syntax**:
`tableutil.make_setter(key, val, mode)`

**arguments**:

-   `key`:
    is a table key or a table of key-value to set.

-   `val`:
    if `key` is a table, `val` is ignored.
    if `key` is not a table, `val` is the value to set on key `key`.

-   `mode`:
    specifies what to do if a key exists.
    -   'replace': always replace existent key in target table.
    -   'keep': always keep existent key in target table.

    By defaul it is 'replace'.


**return**:
a function.

## tableutil.merge

**syntax**:
`tableutil.merge(tbl, ...)`

Add all key-value pairs in tables of `{...}` to `tbl`.
If one key is in `tbl` already, update its value.

**arguments**:

-   `tbl`:
    is a table.

-   `...`:
    are some tables.

**return**:
the first argument `tbl` itself.

##  tableutil.nkeys

**syntax**:
`tableutil.nkeys(tbl)`

Get number of keys in table `tbl`.

**arguments**:

-   `tbl`:
    is a table.

**return**:
number of keys in `tbl`.

##  tableutil.random

**syntax**:
`tableutil.random(tbl, n)`

If `tbl` is not a table, return `tbl`.
Or cut `n` consecutive int number indexed values from a random index in `tbl`.
If `n` is greater than length of `tbl` or is `nil` then cut all `tbl`.

**arguments**:

-   `tbl`:
    is a table or primitive value.
-   `n`:
    is a number tells how many values wanted.

**return**:
a list table.

##  tableutil.remove_all

**syntax**:
`tableutil.remove_all(tbl, value)`

**Remove** all `value` from table `tbl` and return the number of `value` removed.
If `value` is int number indexed, **remove** it from table and all
following elements moved left by one position.
Or set it to `nil`.

**arguments**:

-   `tbl`:
    is a table.
-   `value`:
    is the value to be removed.

**return**:
the number of removed `value`.

##  tableutil.remove_value

**syntax**:
`tableutil.remove_value(tbl, value)`

If `value` is not in `tbl`, do nothing but return `nil`.
Or if `value` is int number indexed, remove the first `value` appeared in `tbl`,
move left the following elements by one position and return `value`.
Or set the first `value` appeared in `tbl` to `nil` and return `value`.

**arguments**:

-   `tbl`:
    is a table.

-   `value`:
    is the value to be removed.

**return**:
`value` if `value` is in `tbl`, `nil` else.

##  tableutil.union

**syntax**:
`tableutil.union(tables, val)`

Get a table whose keys are those appeared at least once in one of the tables
in `tables`.
If `val` is not `nil`, every values of these keys are `val`.
Or the values of these keys in the table of `tables` it lastly appeared.

**Usage**

```
local tbl1 = {1, a='a'}
local tbl2 = {1, b='b'}
local tbl3 = {1, c='c'}

for k, v in pairs(union({tbl1, tbl2, tbl3})) do
    print(k..':'..v)
end

--output

1:1
a:a
b:b
c:c
```

**arguments**:

-   `tables`:
    is a list table filled with tables.

-   `val`:
    is a value assigned to keys in table returned.

**return**:
a table.

##  tableutil.update

**syntax**:
`tableutil.update(tbl, src, opts)`

Add key-value pairs in `src` to `tbl` if the key is not in `tbl`.
If `opts.force` is not `false` then use every `src[k]` to replace `tbl[k]`.
If `opt.recursive` is not `false`, do replace recursively.
`opt.force` and `opt.recursive` are both `nil` by default.

**arguments**:

-   `tbl`:
    a table to be updated.

-   `src`:
    a table contains key-value pairs to update `tbl`.

-   `opts`:
    set `opts.force` to `true` to do force replace or set `opts.recursive` to `true` to do replace recursively.

**return**:
the first `tbl` itself.

#   Author

Zhang Yanpo (张炎泼) <drdr.xp@gmail.com>

#   Copyright and License

The MIT License (MIT)

Copyright (c) 2015 Zhang Yanpo (张炎泼) <drdr.xp@gmail.com>
