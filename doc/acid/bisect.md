<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
#   Table of Content

- [Name](#name)
- [Status](#status)
- [Description](#description)
- [Methods](#methods)
  - [bisect.search](#bisectsearch)
- [Author](#author)
- [Copyright and License](#copyright-and-license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

#   Name

acid.bisect

#   Status

This library is considered production ready.

#   Description

It provides with bisection-search functions.

#   Methods

##  bisect.search

**syntax**:
`bisect.search(array, key, opts)`

It search for `key` in `array` and returns
two value: a boolean that indicates if `key` is found,
and index so that:
`array[index] <= key < array[index + 1]`.

It does not check whether the elements in `array` are correctly sorted.
If not, the result is unspecified.

Example:

```
bisect.search({1,3}, 0) -- false, 0
bisect.search({1,3}, 1) -- true,  1
bisect.search({1,3}, 2) -- false, 1
bisect.search({1,3}, 3) -- true,  2
bisect.search({1,3}, 4) -- false, 2
```

**arguments**:

-   `array`:
    is a ascending sorted array.

    If no customized compare function is provided,
    `key` and the elements in `array` must be the same primitive type or be
    tables those have the same structure.
    Because by default it use `tableutil.cmp_list` to compare elements, which
    requires the values to compare have the same type.

    `{1,2}` and `{}` are comparable.
    `{1,'a'}` and `{1,2}` are not comparable.
    `{1,'a'}` and `1` are not comparable.

-   `key`:
    specifies the element to search.

-   `opts`:
    can be used to provide user customized compare function.

    By default it is `nil` thus `search` use `tableutil.cmp_list` to compare
    `key` against element in `array`.

    To use customized compare function: use `opts = {cmp = function(a, b) ... end}`.

    `opts.cmp` accepts two argument and should return `-1, 0, 1`
    for `a<b, a==b and a>b`.

**return**:
two values:

-   `found`: indicates if `key` is found or not.
    If found, the second return value `left` is the index where the element
    equals `key`.

-   `left`: the index of the right-most element which equals or is less than `key`.

If `key` is less than all elements, it returns `false, 0`.

If `key` is greater than all elements, it returns `false, #array`.


#   Author

Zhang Yanpo (张炎泼) <drdr.xp@gmail.com>

#   Copyright and License

The MIT License (MIT)

Copyright (c) 2015 Zhang Yanpo (张炎泼) <drdr.xp@gmail.com>
