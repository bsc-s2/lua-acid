<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
#   Table of Content

- [Name](#name)
- [Status](#status)
- [Description](#description)
- [Synopsis](#synopsis)
- [Methods](#methods)
  - [async_cache.new](#new)
  - [async_cache.get](#get)
- [Author](#author)
- [Copyright and License](#copyright-and-license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

#   Name

acid.async_cache

#   Status

This library is considered production ready.

#   Description

It use nginx shared dictionary to cache values, and update values asynchronously.

#   Synopsis

```lua
# nginx.conf

http {
    lua_shared_dict my_locks 100k;
    lua_shared_dict my_cache 100m;

    server {
        ...

        location = /t {
            content_by_lua_block {
                local async_cache = require('acid.async_cache')

                local update_handler = {}
                function update_handler.get_latest(self, key)
                    return {
                        value = 'the latest value',
                        cache_expire_time = 60 * 5,
                    }, nil, nil
                end

                local cache, err, errmsg = async_cache.new(
                        'my_cache', 'my_locks', 'test_service', update_handler,
                        {cache_expire_time=60 * 20, max_stale_time=60})
                if err ~= nil then
                    ngx.say('failed to new async cache')
                end

                local cache_value, err, errmsg = cache:get('key')
                if err ~= nil then
                    ngx.say('failed to get value')
                end

                ngx.say('the value is: ' .. tostring(cache_value.value))
                ngx.say('the status is: ' .. cache_value.status)
            }
        }
    }
}
```

#   Methods

##  new

**syntax**:
`obj, err, errmsg = async_cache.new(shared_dict_name, lock_dict_name, service_name,
                                    update_handler, opts)`

**arguments**:

-   `shared_dict_name`:
    The name of shared dictionary(carete by lua_shared_dict) used to cache values.

-   `lock_dict_name`:
    The name of shared dictionary(carete by lua_shared_dict) used by lua-resty-lock.

-   `service_name`:
    It is a string used as key prefix when set shared dict, so different services
    can use same keys.

-   `update_handler`:
    A table contains a callback function `get_latest`, which is used to get the
    latest value of a key. The syntax of function `get_latest` is
    `get_latest(self, storage_key)`, the first argument is the `update_handler` table,
    the second argument is the key passed to `get`, prefixed by service_name and a slash,
    the return of this function is a table contain two fields: `value` and `cache_expire_time`,
    the latter can be omited, the `value` is the actual value of the key.

-   `opts`:
    The options table accepts the following options:

    -   `cache_expire_time`:
        Set expire time, the default is 1200 seconds, if the value
        is expired, the `status` will be "stale".

    -   `max_stale_time`:

        Default is 120 seconds.

        If the value not updated in max_stale_time after expire, the
        `status` will be "too_stale".

    -   `async_fetch`:

        Default is false.

        If set to true, when cache not hit, return immediately,
        and add a asynchronous task to fetch and cache the value.

        If set to false, when cache status is "too_stale" or "missing",
        async_cache will synchronous call `get_last` and return.


**return**:
The cache object, In case of failure, return nil and error code and error message.

##  get

**syntax**:
`cache_value, err, errmsg = obj:get(key)`

**arguments**:

-   `key`:
    The key of the cached value.

**return**:
The value and status of the cached key, in a table.
In case of failure, return nil and error code and error message.

#   Author

Renzhi (任稚) <zhi.ren@baishancloud.com>

#   Copyright and License

The MIT License (MIT)

Copyright (c) 2015 Renzhi (任稚) <zhi.ren@baishancloud.com>
