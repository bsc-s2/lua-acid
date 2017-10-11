<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
#   Table of Content

- [Name](#name)
- [Status](#status)
- [Description](#description)
- [Synopsis](#synopsis)
- [Methods](#methods)
  - [strutil.endswith](#strutilendswith)
  - [strutil.fnmatch](#strutilfnmatch)
  - [strutil.fromhex](#strutilfromhex)
  - [strutil.ljust](#strutilljust)
  - [strutil.join](#strutiljoin)
  - [strutil.placeholder](#strutilplaceholder)
  - [strutil.right_n_split](#strutilright_n_split)
  - [strutil.rjust](#strutilrjust)
  - [strutil.rsplit](#strutilrsplit)
  - [strutil.split](#strutilsplit)
  - [strutil.startswith](#strutilstartswith)
  - [strutil.strip](#strutilstrip)
  - [strutil.to_chunks](#strutilto_chunks)
  - [strutil.to_str](#strutilto_str)
  - [strutil.tohex](#strutiltohex)
- [Author](#author)
- [Copyright and License](#copyright-and-license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

#   Name

acid.strutil

#   Status

This library is considered production ready.

#   Description

It provides with several often used string operation utilities.
Most of them follow python-style.

#   Synopsis

```lua
local strutil = require("acid.strutil")

strutil.split('a/b/c', '/')     -- {'a', 'b', 'c'}


-- convert series of data into human readable string.
strutil.to_str(1,2,{10,a=1,20}) -- 12{10,20,a=1}
```

#   Methods


##  strutil.endswith

**syntax**:
`strutil.endswith(str, suffix)`

Return `true` if `str` ends with the specified `suffix`,
`false` otherwise.

See also: `strutil.startswith`.

**arguments**:

-   `str`:
    is a string.

-   `suffix`:
    suffix string or a table of strings to try.

**return**:
bool


## strutil.fnmatch

**syntax**:
`strutil.fnmatch(s, ptn)`

Return `true` if string `s` matches the string `ptn`,
`false` otherwise.

**arguments**:

- `s`:
    is a string.

- `ptn`:
    is used to find the first match of `ptn` in the string `s`.

    Convert escape and special chars in `ptn` to chars that Lua can recognize.

**return**:
bool.


##  strutil.fromhex

**syntax**:
`strutil.fromhex(str)`

Convert `'00ab'` to `'\x00\xab'`.
See also: `strutil.tohex`

**arguments**:

-   `str`:
    hex string.

**return**:
byte string.

**error**:
An error will be emitted if `str` is not a string, or it is not a valid hex.


##  strutil.ljust

**syntax**:
`strutil.ljust(str, n, char)`

Return `str` left-justified in a string of length `n`.
Padding is done using the specified fill character.
By default `char` is space.

See also `strutil.rjust`.

**arguments**:

-   `str`:
    string to justify.

-   `n`:
    specifies result string length.

-   `char`:
    is filling char.

**return**:
a padded string.


##  strutil.join

**syntax**:
`strutil.join(sep, ...)`

Same as `table.concat({...}, sep)`

**arguments**:

-   `sep`:
    Separator string.

**return**:
a string.


##  strutil.placeholder

**syntax**:
`strutil.placeholder(val, pholder, float_fmt)`

Return a string representing `val`
or a placeholder string if `val` is `nil` or `''`.

**arguments**:

-   `val`:
    any type of value.

-   `pholder`:
    specifies what string to use as a place holder.

    By default it is `'-'`.

-   `float_fmt`:
    specifies float number format to convert to string.

    By default it is `nil`.
    If `val` is float, it is converted to string with `tostring(val)`.

**return**:
string.


## strutil.right_n_split

**syntax**:
`strutil.right_n_split(str, pat, frm, plain, n)`

Split string `str` from the right with a separator `pat`.

Return two values:
The offset of the end of the part that is not split in `str`,
and following `n` parts in a table in reversed order.

For example:

```
strutil.right_n_split('a/b/c/d', '/', 1, true, 2)       -- 3, {'d', 'c'}
```

**arguments**:

- `str`:
    is the string to be split.

- `pat`:
    is a separator in string.

- `frm`:
    specifies the starting position to find the `pat`.

- `plain`:
    turns off the pattern matching facilities.

- `n`:
    limits max split times.

**return**:
two values,
a number and a table of `n` split strings.


##  strutil.rjust

**syntax**:
`strutil.rjust(str, n, char)`

Return `str` right-justified in a string of length `n`.
Padding is done using the specified fill character.
By default `char` is space.

See also `strutil.ljust`.

**arguments**:

-   `str`:
    string to justify.

-   `n`:
    specifies result string length.

-   `char`:
    is filling char.

**return**:
a padded string.


##  strutil.rsplit

**syntax**:
`strutil.rsplit(str, pattern, opts)`

Same as `strutil.split` except when `maxsplit` is specified,
it starts with splitting from right to left.

##  strutil.split

**syntax**:
`strutil.split(str, pattern, opts)`

Split string `str` with a separator `pattern`

```
strutil.split('a/b/c/d', '/', 2)     -- {'a', 'b', 'c/d'}
```

**arguments**:

-   `str`:
    is the string to be split.

-   `pattern`:
    is a separator in lua string pattern or a plain text string,
    depending on the third argument.

-   `opts`:
    is an option to control the behavior of this function.

    The value of `opts` could be:

    -   `nil`: lua string pattern.
        `strutil.split(str, pattern)`

        It splits `str` with lua string pattern `pattern`.

    -   `true`: pattern is plain text.
        `strutil.split(str, pattern, true)`

        It splits `str` with plain text separator `pattern`.

    -   number: use plain text pattern and it limits max split times.
        `strutil.split(str, pattern, 3)`.

        It splits `str` with plain text `pattern` and splits at most 3 times.

    -   table: options in a table. Valid option keys are `plain` and `maxsplit`.
        `strutil.split(str, pattern, {plain=false, maxsplit=5})`

        It splits `str` with lua string pattern and splits at most 5 times.

**return**:
a table of split strings.


##  strutil.startswith

**syntax**:
`strutil.startswith(str, prefix, start)`

Return `true` if `str` starts with the specified `prefix`,
`false` otherwise.

See also: `strutil.endswith`.

**arguments**:

-   `str`:
    is a string.

-   `prefix`:
    prefix string or a table of strings to try.

-   `start`:
    is the position to start test.

    By default it is `nil`: to test from the first char.

**return**:
bool


##  strutil.strip

**syntax**:
`strutil.strip(str, ptn)`

Return a string with leading and trailing chars those matches `pth` removed.

**arguments**:

-   `str`:
    string.

-   `ptn`:
    specifies chars in plain text to remove from both side of the `str`.

    if `ptn` is `nil` or empty string `""`,
    it removes all space chars(`" ", "\t", "\r" and "\n"`).

**return**:
a string with `pth` removed from both side.


## strutil.to_chunks

**syntax**:
`strutil.to_chunks(s, n)`

Divide a string `s` into sections by length `n`.

**arguments**:

- `s`:
    is a string.

- `n`:
    specifies the length of each part.

    It must be greater than 0,
    and it can be a float.

    when it is a float,
    for Example:
    ```
    strutil.to_chunks('abcdefgh', 1.34) -- {'a', 'b', 'cd', 'e', 'f', 'gh'}

    strutil.to_chunks('abcdef', 1.5)    -- {'a', 'bc', 'd', 'ef'}
    ```

**return**:
a table of split strings.


##  strutil.to_str

**syntax**:
`strutil.to_str(...)`

Convert all arguments to a human readable string.
Example:

```
strutil.to_str(1,2,{10,a=1,20}) -- 12{10,20,a=1}
```

It is actually just a wrapper of underlying `repr.str()`.

**arguments**:

-   `...`:
    a series of element of type `number, string, bool, table or nil`.


**return**:
a human readable string

##  strutil.tohex

**syntax**:
`strutil.tohex(str)`

Convert `'\x00\xab'` to `'00ab'`.
See also: `strutil.fromhex`

**arguments**:

-   `str`:
    any string.

**return**:
hex string.

**error**:
An error will be emit if `str` is not a string, or it is not a valid hex.


#   Author

Zhang Yanpo (张炎泼) <drdr.xp@gmail.com>

#   Copyright and License

The MIT License (MIT)

Copyright (c) 2015 Zhang Yanpo (张炎泼) <drdr.xp@gmail.com>
