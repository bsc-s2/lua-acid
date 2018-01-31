<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
#   Table of Content

- [Name](#name)
- [Status](#status)
- [Description](#description)
- [Synopsis](#synopsis)
- [Methods](#methods)
  - [load_cert_and_key](#load_cert_and_key)
- [Author](#author)
- [Copyright and License](#copyright-and-license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

#   Name

acid.cert_loader

#   Status

This library is considered production ready.

#   Description

This library load all certifications from disk into memory, and choose
the longest certification that match the server name, then set that
certification for ssl handshake.

The certifications on disk may change, so this library will load from disk
periodically. This process is done asynchronously, so request is not blocked.

All certifications in memory are transferred to binary format, and kept in a
tree structure.

If following certification files on disk.

``` shell
aa.com.crt
aa.com.key
bb.com.crt
bb.com.key
cc.aa.com.crt
cc.aa.com.key
```

Then the tree structure is like:

``` lua
cert_tree = {
    com = {
        aa = {
            _cert_info = {
                cert_name = 'aa.com'
                der_cert = '...' --binary format of the certification.
                der_key = '...' --binary format of the private key.
            },

            cc = {
                _cert_info = {
                    ...
                },
            }
        },
        bb = {
            _cert_info = {
                ...
            },
        },
    }
}
```

#   Synopsis

```lua
# nginx.conf

http {
    lua_shared_dict my_locks 100k;
    lua_shared_dict my_cache 100m;

    server {

        listen 80;
        listen 443 ssl;

        ssl_certificate /path/to/default_cert.crt;
        ssl_certificate_key /path/to/default_cert_private_key.key;

        ssl_certificate_by_lua_block {
            local cert_loader = require('acid.cert_loader')
            local opts = {
                shared_dict_name = 'my_cache',
                lock_shared_dict_name = 'my_locks',
                cert_path = '/path/to/cert_files',
                expire_time = 60 * 10,
                cache_expire_time = 60 * 60,
            }
            local r = cert_loader.load_cert_and_key(opts)

            if r.cert_name ~= nil then
                ngx.log(ngx.INFO, 'use cert: ' .. r.cert_name)
            else
                ngx.log(ngx.INFO, 'cert not loaded, reason is: ' .. r.reason)
            end
        }

        location = /t {
            content_by_lua_block {
            }
        }
    }
}
```

#   Methods

##  load_cert_and_key

**syntax**:
`result, err, errmsg = cert_loader.load_cert_and_key(opts)`

**arguments**:

-   `opts`:
    A table contains any of following fields.

    - `cert_path`: the directory where certification files located. Required.

    - `shared_dict_name`: shared dict to cache certifications. Required.

    - `lock_shared_dict_name`: shared dict used by `ngx.lock`. Required.

    - `cert_suffix`: suffix of certification file, default is '.crt'.

    - `cert_key_suffix`: suffix of certification private key file,
        default is '.key'.

    - `expire_time`: expire time of local memory cache.
        default is 600 seconds.

    - `cache_expire_time`: expire time of the shared dict cache.
        default is 3600 seconds.

**return**:
If certification is set, return a table contains the name of the
certification, if not set, return a table contains the reason.

#   Author

Renzhi (任稚) <zhi.ren@baishancloud.com>

#   Copyright and License

The MIT License (MIT)

Copyright (c) 2015 Renzhi (任稚) <zhi.ren@baishancloud.com>
