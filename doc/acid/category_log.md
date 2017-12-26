<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
#   Table of Content

- [Name](#name)
- [Status](#status)
- [Description](#description)
- [Synopsis](#synopsis)
- [Methods](#methods)
  - [new](#new)
  - [write_log](#write_log)
- [Author](#author)
- [Copyright and License](#copyright-and-license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

#   Name

acid.category_log

#   Status

This library is considered production ready.

#   Description

This lua module is used to write error log of different requst to
different log file. Error logs can be separated by response status
or something else.

It is implementd by wrapping the ngx.log function,
besides logging to the original log file normally, it also save logs
in memory, and at nginx log phase, it finally write to a proper log file.

#   Synopsis

```lua
# nginx.conf

http {
    init_worker_by_lua_block {
        local category_log = require('acid.category_log')

        local get_category_file = function()
            return string.format('front_%d_error.log', ngx.status)
        end

        local opts = {
            get_category_file = get_category_file,
            max_repeat_n = 64,
            max_entry_n = 256,
        }

        category_log.wrap_log(opts)
    }

    server {
        ...

        log_by_lua_block {
            local category_log = require('acid.category_log')
            category_log.write_log()
        }

        location = /t {
            rewrite_by_lua_block {
                ...
                ngx.log(ngx.ERR, 'test_error_log')
                ngx.status = 500
                ngx.exit(ngx.HTTP_OK)
            }
        }
    }
}
```

#   Methods

##  new

**syntax**:
`category_log.wrap_log(opts)`

**arguments**:

-   `opts`:
    The options table should contain the following fields:

    -   `get_category_file`: a callback function, have no argument,
        should return the log file to which the logs of this request
        should write, return nil indicate not write to any log file.

    -   `max_repeat_n`: set how many logs on same source file and same
         line number will be saved.

    -   `max_entry_n`: set the max total number of logs to save.

    -   `log_level`: set level of logging, the default is `ngx.INFO`.

**return**:
do not have return value

##  write_log

**syntax**:
`category_log:write_log()`

write logs saved in memory to proper log file.

**return**:
do not have return value

#   Author

Renzhi (任稚) <zhi.ren@baishancloud.com>

#   Copyright and License

The MIT License (MIT)

Copyright (c) 2015 Renzhi (任稚) <zhi.ren@baishancloud.com>
