<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
#   Table of Content

- [Name](#name)
- [Status](#status)
- [Description](#description)
- [Methods](#methods)
  - [ffiutil.str_to_clong](#ffiutilstr_to_clong)
  - [ffiutil.clong_to_str](#ffiutilclong_to_str)
  - [ffiutil.carray_to_tbl](#ffiutilcarray_to_tbl)
  - [ffiutil.tbl_to_carray](#ffiutiltbl_to_carray)
  - [ffiutil.cdata_to_tbl](#ffiutilcdata_to_tbl)
  - [ffiutil.tbl_to_cdata](#ffiutiltbl_to_cdata)
- [Author](#author)
- [Copyright and License](#copyright-and-license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->


#   Name

acid.ffiutil

#   Status

This library is considered production ready.

#   Description

Utility functions for ffi cdata operation.

#   Methods

##  ffiutil.str_to_clong

**syntax**:
`clong, err, errmsg = ffiutil.str_to_clong(str,mode)`

convert a number string to a unsigned or signed c long object.

**arguments**:

-   `str`:
    is a number string.

-   `mode`:
    `nil` or `u`.
    If `mode='u'` then return a unsigned c long object otherwise a signed c long object.

**return**:
a lua-ffi `userdata` representing an unsigned or signed long int in C

##  ffiutil.clong_to_str

**syntax**:
`str, err, errmsg = ffiutil.clong_to_str(clong)`

convert a unsigned or signed c long object to a number string.

**arguments**:

-   `clong`:
    a lua-ffi `userdata` representing an unsigned or signed long int in C

**return**:
a number string

## ffiutil.carray_to_tbl

**syntax**:
`tbl, err, errmsg = ffiutil.carray_to_tbl(carray, len, converter)`

convert a c array object to a lua table.

**arguments**:

-   `carray`:
    is a c array object.

-   `len`:
    is a number.

    The length of `carray`.

-   `converter`:
    is a function.

    `converter`' should accept at least one parameter(.i.e the cdata array item), and return a lua object otherwise converter err message.
    It was used to convert the carray item to a lua value.

    Example:
    ```
    local converter = ffiutil.clong_to_str
    ```

**return**:
a table

## ffiutil.tbl_to_carray

**syntax**:
`carray, err, errmsg = ffiutil.tbl_to_carray(ctype, tbl, converter)`

convert an array table to a c array object.

**arguments**:

-   `ctype`:
    is a C type specification which can be used for most of the API functions.
    Either a cdecl, a ctype or a cdata serving as a template type.

-   `tbl`:
    is an array table.

-   `converter`:
    is a function.

    `converter`' should accept at least one parameter(.i.e the table item), and return a c array object otherwise converter err message.
    It was used to convert a lua item to a c value.

    Example:
    ```
    local converter = ffiutil.str_to_clong
    ```

**return**:
a c array object

## ffiutil.cdata_to_tbl

**syntax**:
`tbl, err, errmsg = ffiutil.cdata_to_tbl(cdata, schema)`

convert a cdata object to a table according to schema.

**arguments**:

-   `cdata`:
    is a cdata object.

-   `schema`:
    is a table.

    The key is the c struct filed name.
    The value can be a sub table or a function or a constant.
    Example:
    ```
    local clong_to_str = ffiutil.clong_to_str
    local fixed_long_array = function(val) return ffiutil.cdata_to_tbl(cdata, 16, clong_to_str) end
    local cdata_to_tbl_schema = {
        {
            A = clong_to_str,
            B = clong_to_str,
            C = clong_to_str,
            D = clong_to_str,
            Nl = clong_to_str,
            Nh = clong_to_str,
            data = fixed_long_array,
            num = tonumber
        }
    }
    local md5_ctx_tbl, err, errmsg = ffiutil.cdata_to_tbl(md5_ctx, cdata_to_tbl_schema)
    ```

**return**:
a table

## ffiutil.tbl_to_cdata

**syntax**:
`cdata, err, errmsg = ffiutil.tbl_to_cdata(ctype, tbl, schema)`

convert a table to a cdata object according to schema.

**arguments**:

-   `ctype`:
    is a C type specification which can be used for most of the API functions.
    Either a cdecl, a ctype or a cdata serving as a template type.

-   `tbl`:
    is a table.

-   `schema`

    The key is the c struct filed name.
    The value can be a sub table or a function or a constant.

**return**:
a cdata object

#   Author

Liu Tongwei(刘桐伟) <tongwei.liu@baishancloud.com>

#   Copyright and License

The MIT License (MIT)

Copyright (c) 2018 Liu Tongwei(刘桐伟) <tongwei.liu@baishancloud.com>
