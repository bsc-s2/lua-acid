#   Name

tableutil

#   Status

This library is considered production ready.

#   Description

`tableutil` provides with several table operation utilities.
Most of them are in python style.


#   Methods

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
    to access an intermedia table, such as `.x`.

    A **leaf** `key_path` is **NOT** a prefix of any other `key_path` and is
    used to access a primitive value, such as `.x.y`.

-   `contain`:
    There are two table `a` and `b`.
    For any finite `key_path` `pb` in `b`, if:

    -   `pb` is also a valid `key_path` in `a`,
    -   and: if `pb` is a leaf `key_path` and the values referred by `pb` in `a`
        and `b` are the same.

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


#   Author

Zhang Yanpo (张炎泼) <drdr.xp@gmail.com>

#   Copyright and License

The MIT License (MIT)

Copyright (c) 2015 Zhang Yanpo (张炎泼) <drdr.xp@gmail.com>
