#   Name

acid.strutil

#   Status

This library is considered production ready.

#   Description

It provides with several often used string operation utilities.
Most of them follows python-style.

#   Synopsis

```lua
local strutil = require("acid.strutil")

strutil.split('a/b/c', '/')     -- {'a', 'b', 'c'}


-- convert series of data into human readable string.
strutil.to_str(1,2,{10,a=1,20}) -- 12{10,20,a=1}
```

#   Methods

##  strutil.rsplit

**syntax**:
`strutil.rsplit(str, pattern, opts)`

Same as `strutil.split` except when `maxsplit` is specified,
it starts splitting from right to left.

##  strutil.split

**syntax**:
`strutil.split(str, pattern, opts)`

Split string `str` with separator `pattern`

```
strutil.split('a/b/c/d', '/', 2)     -- {'a', 'b', 'c/d'}
```

**arguments**:

-   `str`:
    is the string to split.

-   `pattern`:
    is separator in lua string pattern or a plain text string.
    Depends on the third argument.

-   `opts`:
    is options to control behavior of split.

    The value of `opts` could be:

    -   `nil`: lua string pattern.
        `strutil.split(str, pattern)`

        It splits `str` with lua string pattern `pattern`.

    -   `true`: pattern is plain text.
        `strutil.split(str, pattern, true)`

        It splits `str` with plain text separator `pattern`.

    -   number: plain text and limit max split times.
        `strutil.split(str, pattern, 3)`.

        It splits `str` with plain text `pattern` and splits at most 3 times.

    -   table: options in a table. Valid option keys are `plain` and `maxsplit`.
        `strutil.split(str, pattern, {plain=false, maxsplit=5})`

        It splits `str` with lua string pattern and splits at most 5 times.

**return**:
a table of split strings.


#   Author

Zhang Yanpo (张炎泼) <drdr.xp@gmail.com>

#   Copyright and License

The MIT License (MIT)

Copyright (c) 2015 Zhang Yanpo (张炎泼) <drdr.xp@gmail.com>
