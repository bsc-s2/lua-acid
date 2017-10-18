<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
#   Table of Content

- [Name](#name)
- [Status](#status)
- [Description](#description)
- [Synopsis](#synopsis)
- [Methods](#methods)
  - [urlutil.url_escape](#url-escape)
  - [urlutil.url_escape_plus](#url-escape-plus)
  - [urlutil.url_unescape](#url-unescape)
  - [urlutil.url_unescape_plus](#url-unescape-plus)
  - [urlutil.url_parse](#url-parse)
- [Author](#author)
- [Copyright and License](#copyright-and-license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

#   Name

acid.urlutil

#   Status

This library is considered production ready.

#   Description

This library contains url related functions such as url escape,
unescape and url parse.

#   Synopsis

```lua
local urlutil = require('acid.urlutil')

local str, err, errmsg = urlutil.url_escape('a/ b')
if err ~= nil then
    ngx.say('error')
end
-- str: 'a/%20b'

local str, err, errmsg = urlutil.url_escape_plus('a/ b')
if err ~= nil then
    ngx.say('error')
end
-- str: 'a%2F+b'

local str, err, errmsg = urlutil.url_unescape('a/%20b')
if err ~= nil then
    ngx.say('error')
end
-- str: 'a/ b'

local str, err, errmsg = urlutil.url_unescape_plus('a%2F+b')
if err ~= nil then
    ngx.say('error')
end
-- str: 'a/ b'

local r, err, errmsg = urlutil.url_parse(
        'http://bob:123@a.com:80/b/c/;p1=1;p2=2?foo=bar#ff')
if err ~= nil then
    ngx.say('error')
end
-- r: {scheme='http', user='bob', password='123', host='a.com',
       port='80', path='/b/c/', params='p1=1;p2=2', query='foo=bar',
       fragment='ff'}
```

#   Methods

##  url-escape

**syntax**:
`escaped_str, err, errmsg = url_escape(str, safe)`

Percent encoding chars except for a-z, A-Z, 0-9, dot('.'),
underscore and hyphen.

**arguments**:

-   `str`:
    Arbitrary string.

-   `safe`:
    A string contains chars that do not need to escape.
    The default is '/'.

**return**:
The url escaped string.

##  url-escape-plus

**syntax**:
`escaped_str, err, errmsg = url_escape_plus(str, safe)`

Same as url_escape, except that encode space to '+' instead of '%20'.

**arguments**:

-   `str`:
    Arbitrary string.

-   `safe`:
    A string contains chars that do not need to escape.
    The default is ''.

**return**:
The url escaped string.

##  url-unescape

**syntax**:
`unescaped_str, err, errmsg = url_unescape(str)`

**arguments**:

-   `str`:
    Arbitrary string.

**return**:
The unescaped string.

##  url-unescape-plus

**syntax**:
`unescaped_str, err, errmsg = url_unescape_plus(str)`

**arguments**:

-   `str`:
    Arbitrary string.

**return**:
The unescaped string.

##  url-parse

**syntax**:
`r, err, errmsg = url_parse(url)`

**arguments**:

-   `url`:
    The url to parse.

**return**:
A table contains fields: 'scheme', 'user', 'password', 'host', 'port',
'path', 'params', 'query', 'fragment', all of then are string type.
If the corresponding component does not exists, the corresponding
field is an empty string.

#   Author

Renzhi (任稚) <zhi.ren@baishancloud.com>

#   Copyright and License

The MIT License (MIT)

Copyright (c) 2015 Renzhi (任稚) <zhi.ren@baishancloud.com>
