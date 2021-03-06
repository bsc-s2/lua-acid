local xml = require('acid.xml')
local utf8 = require('acid.utf8')

local char = string.char


function test.to_xml(t)
    for _, tbl, expected, desc in t:case_iter(2, {
        {
            {},
            '<r></r>',
        },
        {
            {''},
            '<r></r>',
        },
        {
            {'a', ''},
            '<r>a</r><r></r>',
        },
        {
            {a={}},
            '<r><a></a></r>',
        },
        {
            {{1}},
            '<r>1</r>',
        },
        {
            {a={{2}}},
            '<r><a>2</a></r>',
        },
        {
            {a={{2}, {b=3}}},
            '<r><a>2</a><a><b>3</b></a></r>',
        },
        {
            {a={__attr={foo="bar"}}},
            '<r><a foo="bar"></a></r>',
        },
        {
            {a={''}},
            '<r><a></a></r>',
        },
        {
            {a={'', __attr={f=1}}},
            '<r><a f="1"></a></r>',
        },
        {
            { a={ b={ c={} } } },
            '<r><a><b><c></c></b></a></r>',
        },
        {
            { a={ b={ c={1, 2} } } },
            '<r><a><b><c>1</c><c>2</c></b></a></r>',
        },
        {
            { a={ b={c={}}, b1={__attr={f='bar'}} } },
            '<r><a><b><c></c></b><b1 f="bar"></b1></a></r>',
        },
        {
            { a={ b1=1, b2=2, b3=3, __key_order={'b1', 'b2', 'b3'} } },
            '<r><a><b1>1</b1><b2>2</b2><b3>3</b3></a></r>',
        },
        {
            { a={ {b1=1}, {b2=2}, {b3=3} } },
            '<r><a><b1>1</b1></a><a><b2>2</b2></a><a><b3>3</b3></a></r>',
        },
        {
            { a={ '测试', '<>&'..char(34)..char(39)..char(0x20) } },
            '<r><a>&#27979;&#35797;</a><a>&lt;&gt;&amp;&quot;&apos; </a></r>',
        },
        {
            { [char(0xEF)]={ __attr={['<'] = '>'}, [char(0x00)]=char(0x01) } },
            '<r><&#xEF; &lt;="&gt;"><\0>\1</\0></&#xEF;></r>',
        },
    }) do

        local xml_str, err, errmsg = xml.to_xml('r', tbl, {no_declaration=true})
        t:eq(nil, err, errmsg)
        t:eq(nil, errmsg, desc)
        t:eq(expected, xml_str, desc)
    end
end


function test.indent(t)
    local tbl = {
        a = '1',
        b = {'1', '2'},
        c = {
            d = {
                e = {'1', '2'},
            },
            __attr = {foo='bar'},
            d2 = 'd2',
            __key_order = {'d', 'd2'},
        },
        __attr = {foo1='bar1'},
        __key_order = {'a', 'b', 'c'},
    }

    local expected = table.concat({
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<r foo1="bar1">',
        '    <a>',
        '        1',
        '    </a>',
        '    <b>',
        '        1',
        '    </b>',
        '    <b>',
        '        2',
        '    </b>',
        '    <c foo="bar">',
        '        <d>',
        '            <e>',
        '                1',
        '            </e>',
        '            <e>',
        '                2',
        '            </e>',
        '        </d>',
        '        <d2>',
        '            d2',
        '        </d2>',
        '    </c>',
        '</r>',
    }, '\n')

    local xml_str, err, errmsg = xml.to_xml('r', tbl, {indent='    '})
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)
    t:eq(expected, xml_str)
end


function test.from_xml(t)
    for _, xml_str, expected, desc in t:case_iter(2, {
        {'<a></a>',                 {a={}}             },
        {'<a   />',                 {a={}}             },
        {'<a>foo</a>',              {a='foo'}          },
        {'<a>123</a>',              {a='123'}          },
        {'<a>1</a><a>2</a>',        {a={'1','2'}}      },
        {'<a>2</a><a>1</a>',        {a={'2','1'}}      },
        {'<a><b>foo</b></a>',       {a={b='foo'}}      },
        {'<a><b>foo&#x2F;</b></a>', {a={b='foo/'}}     },
        {'<a><b>&#x2F;</b></a>',    {a={b='/'}}        },
        {'<a><b>&#x2F;foo</b></a>', {a={b='/foo'}}     },
        {'<a><b>b</b><c>c</c></a>', {a={b='b', c='c'}} },
        {'<a><c>c</c><c></c></a>',  {a={c={'c', {}}}}  },
        {'<a><c>c</c><c>1</c></a>', {a={c={'c', '1'}}} },
        {
            '<a  f1 =  \n "bar1"   f2="bar2" >a</a>',
            { a={ 'a', __attr={f1='bar1', f2='bar2'} } },
        },
        {
            ' <a   &lt;="&#x2F;"  &#33445;=\'&#1;\' > text </a>  ',
            { a={ ' text ', __attr={['<']='/', [utf8.char({33445})]=char(1)} } },
        },
        {
            '<a>f<!--comment --->oo</a>',
            { a='foo' },
        },
        {
            '<?xml version="1.0" ?><a>foo</a>',
            { a='foo' },
        },
    }) do

        local r, err, errmsg = xml.from_xml(xml_str)
        t:eq(nil, err, errmsg)
        t:eq(nil, errmsg, desc)
        test.dd(r)
        t:eqdict(expected, r, desc)
        t:eq(1, 1)
    end
end

function test.from_xml_parse_large_file(t)
    -- <?xml version="1.0" encoding="UTF-8"?>
    -- <Delete>
    --     <Object>
    --          <Key>Key</Key>
    --          <VersionId>VersionId</VersionId>
    --     </Object>
    --     <Object>
    --          <Key>Key</Key>
    --     </Object>
    --     ...
    -- </Delete>
    data = {
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<Delete>',
    }
    data_size = #data[1] + #data[2]

    -- at least 100KB
    while data_size < 100 * 1024 do
        item_fmt = '<Object>' ..
                   '<Key>test_key_%d</Key>' ..
                   '<VersionId>test_key_%d_version</VersionId>' ..
                   '</Object>'

        item_index = #data - 2
        data_item = string.format(item_fmt, item_index, item_index)

        data_size = data_size + #data_item
        table.insert(data, data_item)
    end
    table.insert(data, '</Delete>')

    xml_str = table.concat(data)
    ngx.log(ngx.DEBUG,
            string.format('generate #%d items, size %d', #data - 3, #xml_str))

    local _, err, errmsg = xml.from_xml(xml_str)
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg, errmsg)
end


function test.invalid_xml(t)
    for _, xml_str, desc in t:case_iter(1, {
        { 'foo'  },
        { 'foo<a>33</a>'  },
        { '<a>33</a>foo<b>44</b>'  },
        { '< foo="bar"></a>'  },
        { '<a>33</aaa>'  },
    }) do

        local _, err, errmsg = xml.from_xml(xml_str)
        test.dd(err)
        test.dd(errmsg)
        t:neq(nil, err, errmsg)
        t:neq(nil, errmsg, desc)
    end
end
