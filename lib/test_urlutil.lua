local tableutil = require('acid.tableutil')
local urlutil = require('acid.urlutil')


function test.url_escape(t)
    for _, str, safe, expected, desc in t:case_iter(3, {
        {'aA1._-', nil, 'aA1._-'             },
        {'/',      nil, '/'                  },
        {' ',      nil, '%20'                },
        {' ',      ' ', ' '                  },
        {'测试',   nil, '%E6%B5%8B%E8%AF%95' },
    }) do

        local escaped_str, err, errmsg = urlutil.url_escape(str, safe)
        t:eq(nil, err, desc)
        t:eq(nil, errmsg, desc)
        t:eq(expected, escaped_str, desc)
    end
end


function test.url_escape_plus(t)
    for _, str, safe, expected, desc in t:case_iter(3, {
        {'aA1._-', nil, 'aA1._-'             },
        {'/',      nil, '%2F'                },
        {' ',      nil, '+'                  },
        {' ',      ' ', '+'                  },
        {'测试',   nil, '%E6%B5%8B%E8%AF%95' },
    }) do

        local escaped_str, err, errmsg = urlutil.url_escape_plus(str, safe)
        t:eq(nil, err, errmsg)
        t:eq(nil, errmsg, desc)
        t:eq(expected, escaped_str, desc)
    end
end


function test.url_unescape(t)
    for _, str, expected, desc in t:case_iter(2, {
        {'aA1._-',             'aA1._-'                    },
        {'/',                  '/'                         },
        {'%20',                ' '                         },
        {' ',                  ' '                         },
        {'%E6%B5%8B%E8%AF%95', '测试'                      },
        {'%00%1F',             string.char('0x00', '0x1F') },
    }) do

        local unescaped_str, err, errmsg = urlutil.url_unescape(str)
        t:eq(nil, err, desc)
        t:eq(nil, errmsg, desc)
        t:eq(expected, unescaped_str, desc)
    end
end


function test.url_unescape_plus(t)
    for _, str, expected, desc in t:case_iter(2, {
        {'aA1._-',             'aA1._-'                    },
        {'/',                  '/'                         },
        {'%20',                ' '                         },
        {'+',                  ' '                         },
        {'%E6%B5%8B%E8%AF%95', '测试'                      },
        {'%00%1F',             string.char('0x00', '0x1F') },
    }) do

        local unescaped_str, err, errmsg = urlutil.url_unescape_plus(str)
        t:eq(nil, err, desc)
        t:eq(nil, errmsg, desc)
        t:eq(expected, unescaped_str, desc)
    end
end


function test.url_parse(t)
    for _, str, expected, desc in t:case_iter(2, {
        {'http://bob:123@a.com:80/b/c/;p1=1;p2=2?foo=bar#ff',
         {
             scheme='http',
             user='bob',
             password='123',
             host='a.com',
             port='80',
             path='/b/c/',
             params='p1=1;p2=2',
             query='foo=bar',
             fragment='ff',
         },
        },
        {'http',
         {
             scheme='http',
             user='',
             password='',
             host='',
             port='',
             path='',
             params='',
             query='',
             fragment='',
         },
        },
        {'http://@a.com/;??#',
         {
             scheme='http',
             user='',
             password='',
             host='a.com',
             port='',
             path='/',
             params='',
             query='?',
             fragment='',
         },
        },
        {'http:?',
         {
             scheme='http',
             user='',
             password='',
             host='',
             port='',
             path='',
             params='',
             query='',
             fragment='',
         },
        },
        {'http:?aa',
         {
             scheme='http',
             user='',
             password='',
             host='',
             port='',
             path='',
             params='',
             query='aa',
             fragment='',
         },
        },
        {'http:/p/p/p?aa',
         {
             scheme='http',
             user='',
             password='',
             host='',
             port='',
             path='/p/p/p',
             params='',
             query='aa',
             fragment='',
         },
        },
        {'http://bob@?aa',
         {
             scheme='http',
             user='bob',
             password='',
             host='',
             port='',
             path='',
             params='',
             query='aa',
             fragment='',
         },
        },
        {'http://@/p?aa?aa',
         {
             scheme='http',
             user='',
             password='',
             host='',
             port='',
             path='/p',
             params='',
             query='aa?aa',
             fragment='',
         },
        },
        {'http://@@@/p;/p?aa',
         {
             scheme='http',
             user='@@',
             password='',
             host='',
             port='',
             path='/p',
             params='/p',
             query='aa',
             fragment='',
         },
        },
        {'http://:123@/p;;;?aa',
         {
             scheme='http',
             user='',
             password='123',
             host='',
             port='',
             path='/p',
             params=';;',
             query='aa',
             fragment='',
         },
        },
        {'http://:123@:90/p?aa####',
         {
             scheme='http',
             user='',
             password='123',
             host='',
             port='90',
             path='/p',
             params='',
             query='aa',
             fragment='###',
         },
        },
    }) do

        local r, err, errmsg = urlutil.url_parse(str)
        t:eq(nil, err, desc)
        t:eq(nil, errmsg, desc)
        ngx.say(tableutil.repr(r))
        t:eqdict(expected, r, desc)
    end
end


function test.build_query(t)
    for _, tbl, expected, desc in t:case_iter(2, {
        {{},                ''                                      },
        {{1, 3, 2},         '1=1&2=3&3=2'                           },
        {{a=1},             'a=1'                                   },
        {{a='a b'},         'a=a%20b'                               },
        {{['测试']='测试'}, '%E6%B5%8B%E8%AF%95=%E6%B5%8B%E8%AF%95' },
    }) do

        local query_string, err, errmsg = urlutil.build_query(tbl)
        t:eq(nil, err, desc)
        t:eq(nil, errmsg, desc)
        t:eq(expected, query_string, desc)
    end
end
