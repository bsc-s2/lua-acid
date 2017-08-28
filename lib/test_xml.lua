local tableutil = require('acid.tableutil')
local xml = require('acid.xml')

local tc = table.concat
local ngx = ngx


function test.to_xml(t)
    for _, tbl, expected, desc in t:case_iter(2, {
        {{},         tc({'<r>', '</r>'}, '%s*')                         },
        {{{}},       tc({'<r>', '</r>'}, '%s*')                         },
        {{1},        tc({'<r>', '1', '</r>'}, '%s*')                    },
        {{1,2},      tc({'<r>', '1', '</r>', '<r>', '2', '</r>'}, '%s*')},
        {{a={}},     tc({'<r>', '<a>', '</a>', '</r>'}, '%s*')          },
        {{a={1}},    tc({'<r>', '<a>', '1', '</a>', '</r>'}, '%s*')     },
        {{a='foo'},  tc({'<r>', '<a>', 'foo', '</a>', '</r>'}, '%s*')   },
        {{a=123},    tc({'<r>', '<a>', '123', '</a>', '</r>'}, '%s*')   },
        {{a=''},     tc({'<r>', '<a>', '', '</a>', '</r>'}, '%s*')      },
    }) do

        local xml_str, err, errmsg = xml.to_xml('r', tbl)
        t:eq(nil, err, desc)
        t:eq(nil, errmsg, desc)
        ngx.say(xml_str)
        t:neq(nil, string.match(xml_str, expected), desc)
    end
end


function test.to_xml_in_order(t)
    local tbl = {
        a=1,
        b=2,
        c=3,
        __key_order = {'c', 'b', 'a'},
    }

    local expected = tc({'<r>', '<c>', '3', '</c>', '<b>', '2', '</b>',
                         '<a>', '1', '</a>', '</r>'}, '%s*')

    local xml_str, err, errmsg = xml.to_xml('r', tbl)
    t:eq(nil, err)
    t:eq(nil, errmsg)
    ngx.say(xml_str)
    t:neq(nil, string.match(xml_str, expected))
end


function test.from_xml(t)
    for _, xml_str, expected, desc in t:case_iter(2, {
        {'<a></a>',                 {a={}}             },
        {'<a>foo</a>',              {a='foo'}          },
        {'<a>123</a>',              {a='123'}          },
        {'<a>1</a><a>2</a>',        {a={'1','2'}}      },
        {'<a>2</a><a>1</a>',        {a={'2','1'}}      },
        {'<a><b>foo</b></a>',       {a={b='foo'}}      },
        {'<a><b>b</b><c>c</c></a>', {a={b='b', c='c'}} },
        {'<a><c>c</c><c></c></a>',  {a={c={'c', {}}}}  },
        {'<a><c>c</c><c>1</c></a>', {a={c={'c', '1'}}} },
    }) do

        local r, err, errmsg = xml.from_xml(xml_str)
        t:eq(nil, err, desc)
        t:eq(nil, errmsg, desc)
        ngx.say(tableutil.repr(r))
        t:eqdict(expected, r, desc)
    end
end
