<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
#   Table of Content

- [Name](#name)
- [Status](#status)
- [Description](#description)
- [Synopsis](#synopsis)
- [Methods](#methods)
  - [is_exist](#is_exist)
  - [is_dir](#is_dir)
  - [is_file](#is_file)
  - [read_dir](#read_dir)
  - [make_dir](#make_dir)
  - [make_dirs](#make_dirs)
  - [remove_tree](#remove_tree)
  - [file_size](#file_size)
- [Author](#author)
- [Copyright and License](#copyright-and-license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

#   Name

acid.fsutil

#   Status

This library is considered production ready.

#   Description

Some file system related functions based on glibc use luajit ffi API.

#   Synopsis

```lua
local fsutil = require('acid.fsutil')

print(is_exist('/root'))  -- true
print(is_dir('/root'))  -- true
print(is_file('/root')) -- false

local entries, err, errmsg = fsutil.read('/root')
if err ~= nil then
    ngx.say('error')
end
print(#entries)

local _, err, errmsg = fsutil.make_dir('/root/test_dir')
if err ~= nil then
    ngx.say('error')
end

local _, err, errmsg = fsutil.make_dirs('/aa/bb/cc')
if err ~= nil then
    ngx.say('error')
end

local _, err, errmsg = fsutil.remove_tree('/test_dir')
if err ~= nil then
    ngx.say('error')
end

local size, err, errmsg = fsutil.file_size('test_file')
if err ~= nil then
    ngx.say('error')
end
```

#   Methods

##  is_exist

**syntax**:
`exist = is_exist(path)`

**arguments**:

-   `path`:
    the path of file or directory.

**return**:
return a boolean value.

##  is_dir

**syntax**:
`is_dir = is_dir(path)`

**arguments**:

-   `path`:
    the path of file or directory.

**return**:
return true if exist and is a directory, otherwise return false.

##  is_file

**syntax**:
`is_dir = is_dir(path)`

**arguments**:

-   `path`:
    the path of file or directory.

**return**:
return true if exist and is a regular file, otherwise return false.

##  read_dir

**syntax**:
`entries, err, errmsg = read_dir(path)`

**arguments**:

-   `path`:
    the path of directory.

**return**:
return all file names and subdirectory names under the directory.

##  make_dir

**syntax**:
`ok, err, errmsg = make_dir(path, mode, name_or_uid, name_or_gid)`

**arguments**:

-   `path`:
    the path of directory.

-   `mode`:
    a int number to specify permission bits, such as `tonumber('0755', 8)`.
    the default is `0755`.

-   `name_or_uid`:
    the user name or user id.

-   `name_or_gid`:
    the group name or group id.

**return**:
return true on success or error code and error message on failure.

##  make_dirs

same as `make_dir`, but it also create the parents directories automatically.

**syntax**:
`ok, err, errmsg = make_dirs(path, mode, name_or_uid, name_or_gid)`

**arguments**:

-   `path`:
    the path of directory.

-   `mode`:
    a int number to specify permission bits, such as `tonumber('0755', 8)`.
    the default is `0755`.

-   `name_or_uid`:
    the user name or user id.

-   `name_or_gid`:
    the group name or group id.

**return**:
return true on success or error code and error message on failure.

##  remove_tree

**syntax**:
`ok, err, errmsg = remove_tree(path, opts)`

**arguments**:

-   `path`:
    the path of directory.

-   `opts`:
    the options table accepts the following options:

    - `keep_root`: if set to `true`, the base directory will not be removed.

**return**:
return true on success or error code and error message on failure.

##  file_size

**syntax**:
`size, err, errmsg = file_size(path)`

**arguments**:

-   `path`:
    the path of file or directory.

**return**:
return the size of file or directory.

#   Author

Renzhi (任稚) <zhi.ren@baishancloud.com>

#   Copyright and License

The MIT License (MIT)

Copyright (c) 2015 Renzhi (任稚) <zhi.ren@baishancloud.com>
