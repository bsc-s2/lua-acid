local tableutil = require("acid.tableutil")
local time = require('acid.time')

local test = _G.test
local dd = test.dd


function test.nkeys(t)
    local cases = {
        {0, {              }, 'nkeys of empty'},
        {1, {0             }, 'nkeys of 1'},
        {2, {0, nil, 1     }, 'nkeys of 0, nil and 1'},
        {2, {0, 1          }, 'nkeys of 2'},
        {2, {0, 1, nil     }, 'nkeys of 0, 1 and nil'},
        {1, {a=0, nil      }, 'nkeys of a=1'},
        {2, {a=0, b=2, nil }, 'nkeys of a=1'},
    }

    for ii, c in ipairs(cases) do
        local n, tbl = t:unpack(c)
        local msg = 'case: ' .. tostring(ii) .. '-th '
        dd(msg, c)

        local rst = tableutil.nkeys(tbl)
        t:eq(n, rst, msg)

        rst = tableutil.get_len(tbl)
        t:eq(n, rst, msg)
    end
end

function test.keys(t)
    t:eqdict( {}, tableutil.keys({}) )
    t:eqdict( {1}, tableutil.keys({1}) )
    t:eqdict( {1, 'a'}, tableutil.keys({1, a=1}) )
    t:eqdict( {1, 2, 'a'}, tableutil.keys({1, 3, a=1}) )
end

function test.duplist(t)
    local du = tableutil.duplist

    local a = { 1 }
    local b = tableutil.duplist( a )
    a[ 2 ] = 2
    t:eq( nil, b[ 2 ], "dup not affected" )

    t:eqdict( {1}, du( { 1, nil, 2 } ) )
    t:eqdict( {1}, du( { 1, a=3 } ) )
    t:eqdict( {1}, du( { 1, [3]=3 } ) )
    t:eqdict( {}, du( { a=1, [3]=3 } ) )

    a = { { 1, 2, 3, a=4 } }
    a[2] = a[1]
    b = du(a)
    t:eqdict({ { 1, 2, 3, a=4 }, { 1, 2, 3, a=4 } }, b)
    t:eq( b[1], b[2] )
end

function test.sub(t)
    local a = { a=1, b=2, c={} }
    t:eqdict( {}, tableutil.sub( a, nil ) )
    t:eqdict( {}, tableutil.sub( a, {} ) )
    t:eqdict( {b=2}, tableutil.sub( a, {"b"} ) )
    t:eqdict( {a=1, b=2}, tableutil.sub( a, {"a", "b"} ) )

    local b = tableutil.sub( a, {"a", "b", "c"} )
    t:neq( b, a )
    t:eq( b.c, a.c, "reference" )

    -- explicitly specify to sub() as a table
    b = tableutil.sub( a, {"a", "b", "c"}, 'table' )
    t:neq( b, a )
    t:eq( b.c, a.c, "reference" )

    -- sub list

    local cases = {
        {{1, 2, 3}, {}, {}},
        {{1, 2, 3}, {2, 3}, {2, 3}},
        {{1, 2, 3}, {2, 3, 4}, {2, 3}},
        {{1, 2, 3}, {3, 4, 2}, {3, 2}},
    }

    for ii, c in ipairs(cases) do
        local tbl, ks, expected = t:unpack(c)
        local msg = 'case: ' .. tostring(ii) .. '-th '
        dd(msg, c)

        local rst = tableutil.sub(tbl, ks, 'list')
        t:eqdict(expected, rst)
    end
end

function test.dup(t)
    local a = { a=1, 10, x={ y={z=3} } }
    a.self = a
    a.selfref = a
    a.x2 = a.x

    local b = tableutil.dup( a )
    b.a = 'b'
    t:eq( 1, a.a, 'dup not affected' )
    t:eq( 10, a[ 1 ], 'a has 10' )
    t:eq( 10, b[ 1 ], 'b inherit 10' )
    b[ 1 ] = 11
    t:eq( 10, a[ 1 ], 'a has still 10' )

    a.x.y.z = 4
    t:eq( 4, b.x.y.z, 'no deep' )

    local deep = tableutil.dup( a, true )
    a.x.y.z = 5
    t:eq( 4, deep.x.y.z, 'deep dup' )
    t:eq( deep, deep.self, 'loop reference' )
    t:eq( deep, deep.selfref, 'loop reference should be dup only once' )
    t:eq( deep.x, deep.x2, 'dup only once' )
    t:neq( a.x, deep.x, 'dup-ed x' )
    t:eq( deep.x.y, deep.x2.y )

end

function test.contains(t)
    local c = tableutil.contains
    t:eq( true, c( nil, nil ) )
    t:eq( true, c( 1, 1 ) )
    t:eq( true, c( "", "" ) )
    t:eq( true, c( "a", "a" ) )

    t:eq( false, c( 1, 2 ) )
    t:eq( false, c( 1, nil ) )
    t:eq( false, c( nil, 1 ) )
    t:eq( false, c( {}, 1 ) )
    t:eq( false, c( {}, "" ) )
    t:eq( false, c( "", {} ) )
    t:eq( false, c( 1, {} ) )

    t:eq( true, c( {}, {} ) )
    t:eq( true, c( {1}, {} ) )
    t:eq( true, c( {1}, {1} ) )
    t:eq( true, c( {1, 2}, {1} ) )
    t:eq( true, c( {1, 2}, {1, 2} ) )
    t:eq( true, c( {1, 2, a=3}, {1, 2} ) )
    t:eq( true, c( {1, 2, a=3}, {1, 2, a=3} ) )

    t:eq( false, c( {1, 2, a=3}, {1, 2, b=3} ) )
    t:eq( false, c( {1, 2 }, {1, 2, b=3} ) )
    t:eq( false, c( {1}, {1, 2, b=3} ) )
    t:eq( false, c( {}, {1, 2, b=3} ) )

    t:eq( true, c( {1, 2, a={ x=1 }}, {1, 2} ) )
    t:eq( true, c( {1, 2, a={ x=1, y=2 }}, {1, 2, a={}} ) )
    t:eq( true, c( {1, 2, a={ x=1, y=2 }}, {1, 2, a={x=1}} ) )
    t:eq( true, c( {1, 2, a={ x=1, y=2 }}, {1, 2, a={x=1, y=2}} ) )

    t:eq( false, c( {1, 2, a={ x=1 }}, {1, 2, a={x=1, y=2}} ) )

    -- self reference
    local a = { x=1 }
    local b = { x=1 }

    a.self = { x=1 }
    b.self = {}
    t:eq( true, c( a, b ) )
    t:eq( false, c( b, a ) )

    a.self = a
    b.self = nil
    t:eq( true, c( a, b ) )
    t:eq( false, c( b, a ) )

    a.self = a
    b.self = b
    t:eq( true, c( a, b ) )
    t:eq( true, c( b, a ) )

    a.self = { self=a }
    b.self = nil
    t:eq( true, c( a, b ) )
    t:eq( false, c( b, a ) )

    a.self = { self=a, x=1 }
    b.self = b
    t:eq( true, c( a, b ) )

    a.self = { self={ self=a, x=1 }, x=1 }
    b.self = { self=b }
    t:eq( true, c( a, b ) )

    -- cross reference
    a.self = { x=1 }
    b.self = { x=1 }
    a.self.self = b
    b.self.self = a
    t:eq( true, c( a, b ) )
    t:eq( true, c( b, a ) )

end

function test.eq(t)
    local c = tableutil.eq
    t:eq( true, c( nil, nil ) )
    t:eq( true, c( 1, 1 ) )
    t:eq( true, c( "", "" ) )
    t:eq( true, c( "a", "a" ) )

    t:eq( false, c( 1, 2 ) )
    t:eq( false, c( 1, nil ) )
    t:eq( false, c( nil, 1 ) )
    t:eq( false, c( {}, 1 ) )
    t:eq( false, c( {}, "" ) )
    t:eq( false, c( "", {} ) )
    t:eq( false, c( 1, {} ) )

    t:eq( true, c( {}, {} ) )
    t:eq( true, c( {1}, {1} ) )
    t:eq( true, c( {1, 2}, {1, 2} ) )
    t:eq( true, c( {1, 2, a=3}, {1, 2, a=3} ) )

    t:eq( false, c( {1, 2}, {1} ) )
    t:eq( false, c( {1, 2, a=3}, {1, 2} ) )

    t:eq( false, c( {1, 2, a=3}, {1, 2, b=3} ) )
    t:eq( false, c( {1, 2 }, {1, 2, b=3} ) )
    t:eq( false, c( {1}, {1, 2, b=3} ) )
    t:eq( false, c( {}, {1, 2, b=3} ) )

    t:eq( true, c( {1, 2, a={ x=1, y=2 }}, {1, 2, a={x=1, y=2}} ) )

    t:eq( false, c( {1, 2, a={ x=1 }}, {1, 2, a={x=1, y=2}} ) )

    -- self reference
    local a = { x=1 }
    local b = { x=1 }

    a.self = { x=1 }
    b.self = {}
    t:eq( false, c( a, b ) )

    a.self = { x=1 }
    b.self = { x=1 }
    t:eq( true, c( a, b ) )

    a.self = a
    b.self = nil
    t:eq( false, c( b, a ) )

    a.self = a
    b.self = b
    t:eq( true, c( a, b ) )
    t:eq( true, c( b, a ) )

    a.self = { self=a }
    b.self = nil
    t:eq( false, c( a, b ) )

    a.self = { self=a, x=1 }
    b.self = b
    t:eq( true, c( a, b ) )

    a.self = { self={ self=a, x=1 }, x=1 }
    b.self = { self=b, x=1 }
    t:eq( true, c( a, b ) )

    -- cross reference
    a.self = { x=1 }
    b.self = { x=1 }
    a.self.self = b
    b.self.self = a
    t:eq( true, c( a, b ) )
    t:eq( true, c( b, a ) )

end


function test.cmp_list(t)

    for _, a, b, desc in t:case_iter(2, {
        {nil,           nil,           },
        {1,             true,          },
        {1,             '',            },
        {true,          true,          },
        {true,          nil,           },
        {{},            1,             },
        {{},            true,          },
        {{'a'},         {1},           },
        {{{'a'}},       {{1}},         },
        {function()end, function()end, },
        {function()end, 1,             },
    }) do

        t:err(function()
            tableutil.cmp_list(a, b)
        end, desc)
    end

    for _, a, b, expected, desc in t:case_iter(3, {
        {0,                 0,                 0  },
        {1,                 0,                 1  },
        {2,                 0,                 1  },
        {2,                 2,                 0  },
        {2,                 3,                 -1 },
        {'',                '',                0  },
        {'a',               'b',               -1 },
        {'c',               'b',               1  },
        {'foo',             'foo',             0  },
        {{},                {},                0  },
        {{1},               {},                1  },
        {{1},               {1},               0  },
        {{1,0},             {1},               1  },
        {{1,0},             {1,0},             0  },
        {{1,0},             {1,0,0},           -1 },
        {{'a'},             {'a',1},           -1 },
        {{'a',1,1},         {'a',1},           1  },
        {{'a',1,{'b'}},     {'a',1,{'b'}},     0  },
        {{'a',1,{'c'}},     {'a',1,{'b'}},     1  },
        {{'a',1,{'c',1}},   {'a',1,{'c',1}},   0  },
        {{'a',1,{'c',1,1}}, {'a',1,{'c',1}},   1  },
        {{'a',1,{'c',1}},   {'a',1,{'c',1,1}}, -1 },
        {{'a',1,{'c',1}},   {'a',1,{'c',2}},   -1 },
        {{'a',1,{'c',2}},   {'a',1,{'c',1}},   1  },
    }) do

        local rst = tableutil.cmp_list(a, b)
        dd('rst: ', rst)

        t:eq(expected, rst, desc)
    end
end


function test.intersection(t)
    local a = { a=1, 10 }
    local b = { 11, 12 }
    local c = tableutil.intersection( { a, b }, true )

    t:eq( 1, tableutil.nkeys( c ), 'c has 1' )
    t:eq( true, c[ 1 ] )

    local d = tableutil.intersection( { a, { a=20 } }, true )
    t:eq( 1, tableutil.nkeys( d ) )
    t:eq( true, d.a, 'intersection a' )

    local e = tableutil.intersection( { { a=1, b=2, c=3, d=4 }, { b=2, c=3 }, { b=2, d=5 } }, true )
    t:eq( 1, tableutil.nkeys( e ) )
    t:eq( true, e.b, 'intersection of 3' )

end

function test.union(t)
    local a = tableutil.union( { { a=1, b=2, c=3 }, { a=1, d=4 } }, 0 )
    t:eqdict( { a=0, b=0, c=0, d=0 }, a )
end

function test.mergedict(t)
    t:eqdict( { a=1, b=2, c=3 }, tableutil.merge( { a=1, b=2, c=3 } ) )
    t:eqdict( { a=1, b=2, c=3 }, tableutil.merge( {}, { a=1, b=2 }, { c=3 } ) )
    t:eqdict( { a=1, b=2, c=3 }, tableutil.merge( { a=1 }, { b=2 }, { c=3 } ) )
    t:eqdict( { a=1, b=2, c=3 }, tableutil.merge( { a=0 }, { a=1, b=2 }, { c=3 } ) )

    local a = { a=1 }
    local b = { b=2 }
    local c = tableutil.merge( a, b )
    t:eq( true, a==c )
    a.x = 10
    t:eq( 10, c.x )
end

function test.depth_iter(t)

    for _, _ in tableutil.depth_iter({}) do
        t:err( "should not get any keys" )
    end

    for ks, v in tableutil.depth_iter({1}) do
        t:eqdict( {1}, ks )
        t:eq( 1, v )
    end

    for ks, v in tableutil.depth_iter({a="x"}) do
        t:eqdict( {{"a"}, "x"}, {ks, v} )
    end

    local a = {
        1, 2, 3,
        { 1, 2, 3, 4 },
        a=1,
        c=100000,
        d=1,
        x={
            1,
            { 1, 2 },
            y={
                a=1,
                b=2
            }
        },
        ['fjklY*(']={
            x=1,
            b=3,
        },
        [100]=33333
    }
    a.z = a.x

    local r = {
        { {1}, 1 },
        { {100}, 33333 },
        { {2}, 2 },
        { {3}, 3 },
        { {4,1}, 1 },
        { {4,2}, 2 },
        { {4,3}, 3 },
        { {4,4}, 4 },
        { {"a"}, 1 },
        { {"c"}, 100000 },
        { {"d"}, 1 },
        { {"fjklY*(","b"}, 3 },
        { {"fjklY*(","x"}, 1 },
        { {"x",1}, 1 },
        { {"x",2,1}, 1 },
        { {"x",2,2}, 2 },
        { {"x","y","a"}, 1 },
        { {"x","y","b"}, 2 },
        { {"z",1}, 1 },
        { {"z",2,1}, 1 },
        { {"z",2,2}, 2 },
        { {"z","y","a"}, 1 },
        { {"z","y","b"}, 2 },
    }

    local i = 0
    for ks, v in tableutil.depth_iter(a) do
        i = i + 1
        t:eqdict( r[i], {ks, v} )
    end

end


function test.has(t)
    local cases = {
        {nil, {}, true},
        {1, {1}, true},
        {1, {1, 2}, true},
        {1, {1, 2, 'x'}, true},
        {'x', {1, 2, 'x'}, true},

        {1, {x=1}, true},

        {'x', {x=1}, false},
        {"x", {1}, false},
        {"x", {1, 2}, false},
        {1, {}, false},
    }

    for ii, c in ipairs(cases) do
        local val, tbl, expected = t:unpack(c)
        local msg = 'case: ' .. tostring(ii) .. '-th '
        dd(msg, c)

        t:eq(expected, tableutil.has(tbl, val))
    end
end


function test.remove_value(t)
    local t1 = {}
    local cases = {
        {{},                nil, {},                nil},
        {{1, 2, 3},         2,   {1, 3},            2},
        {{1, 2, 3, x=4},    2,   {1, 3, x=4},       2},
        {{1, 2, 3},         3,   {1, 2},            3},
        {{1, 2, 3, x=4},    3,   {1, 2, x=4},       3},
        {{1, 2, 3, x=4},    4,   {1, 2, 3},         4},
        {{1, 2, 3, x=t1},   t1,  {1, 2, 3},         t1},

        {{1, 2, t1, x=t1}, t1,   {1, 2, x=t1}, t1},
    }

    for i, case in ipairs(cases) do

        local tbl, val, expected_tbl, expected_rst = case[1], case[2], case[3], case[4]

        local rst = tableutil.remove_value(tbl, val)

        t:eqdict(expected_tbl, tbl, i .. 'th tbl')
        t:eq(expected_rst, rst, i .. 'th rst')
    end
end


function test.remove_all(t)
    local t1 = {}
    local cases = {
        {{},                   nil, {},                0},
        {{1,2,3},              2,   {1, 3},            1},
        {{1,2,3,x=4},          2,   {1, 3, x=4},       1},
        {{1,2,3,x=2},          2,   {1, 3},            2},
        {{1,2,3},              3,   {1, 2},            1},
        {{1,2,3,x=4},          3,   {1, 2, x=4},       1},
        {{1,2,3,4,x=4},        4,   {1, 2, 3},         2},
        {{1,t1,3,x=t1,y=t1},   t1,  {1, 3},            3},

        {{1,2,t1,x=t1},        t1,  {1, 2},            2},
    }

    for i, case in ipairs(cases) do

        local tbl, val, expected_tbl, expected_rst = case[1], case[2], case[3], case[4]

        local rst = tableutil.remove_all(tbl, val)

        t:eqdict(expected_tbl, tbl, i .. 'th tbl')
        t:eq(expected_rst, rst, i .. 'th rst')
    end
end


function test.get_random_elements(t)

    local cases = {
        {1,         nil,        1},
        {'123',     2,          '123'},
        {{},        nil,        {}},
        {{1},       nil,        {1}},
    }

    for ii, c in ipairs(cases) do
        local tbl, n, expected = t:unpack(c)
        local msg = 'case: ' .. tostring(ii) .. '-th '
        dd(msg, c)

        local rst = tableutil.random(tbl, n)
        t:eqdict(expected, rst, msg)
    end

    -- random continuous

    local expected = {
        {1, 2, 3},
        {2, 3, 1},
        {3, 1, 2}
    }

    local rst = tableutil.random({1, 2, 3}, nil)
    t:eqdict(expected[rst[1]], rst, 'rand {1, 2, 3}, nil')
end


function test.list_len(t)
    for _, tbl, kind, expected, desc in t:case_iter(3, {
        {
            {1, 2, 3, 4, {5, 6}, foo={1, 2, 3}}, nil,
            5,
        },
        {
            {1, 2, 3, 4, {5, 6}, foo={1, 2, 3}}, 'max_index',
            5,
        },
        {
            {1, 2, 3, 4, {5, 6}, foo={1, 2, 3}}, 'size',
            5,
        },
        {
            {1, 2, 3, 4, {5, 6}, foo={1, 2, 3}}, 'end_by_nil',
            5,
        },
        {
            {nil, 2, 3, [999]=999, ['1000']=1000}, 'end_by_nil',
            0,
        },
        {
            {nil, 2, 3, [999]=999, ['1000']=1000}, nil,
            0,
        },
        {
            {nil, 2, 3, [998]=998, [999]=999, ['1000']=1000}, 'size',
            3,
        },
        {
            {nil, 2, 3, [998]=998, [999]=999, ['1000']=1000}, 'max_index',
            999,
        },
        {
            {1, {}, '2', nil, [998]=998, ['1000']=1000}, nil,
            3,
        },
        {
            {1, {}, '2', nil, [998]=998, ['1000']=1000}, 'size',
            3,
        },
        {
            {1, {}, '2', nil, [998]=998, ['1000']=1000}, 'max_index',
            998,
        },
        {
            {1, 2, 3, 4, nil, 6}, 'end_by_nil',
            4,
        },
        {
            {1, 2, 3, 4, nil, 6}, 'size',
            6,
        },
        {
            {1, 2, 3, 4, nil, nil}, 'size',
            4,
        },
    }) do
        local r = tableutil.list_len(tbl, kind)
        t:eq(expected, r, desc)
   end
end


function test.test_reverse(t)
    for _, tbl, opts, expected, desc in t:case_iter(3, {
        {
            {1, '2', 3, nil, {5, 6}, [8]=8, foo={1, 2, 3}},
            nil,
            {3, '2', 1},
        },
        {
            {1, '2', 3, nil, {5, 6}, [8]=8, foo={1, 2, 3}},
            {array_len_kind='max_index'},
            {8, nil, nil, {5, 6}, nil, 3, '2', 1},
        },
        {
            {1, '2', 3, nil, {5, 6}, [8]=8, foo={1, 2, 3}},
            {array_len_kind='max_index', recursive='array'},
            {8, nil, nil, {6, 5}, nil, 3, '2', 1},
        },
        {
            {1, '2', 3, nil, {5, 6}, [8]=8, foo={1, 2, 3}},
            {array_len_kind='max_index', recursive='hash'},
            {8, nil, nil, {5, 6}, nil, 3, '2', 1},
        },
        {
            {1, '2', 3, nil, {5, 6}, [8]=8, foo={1, 2, 3}},
            {array_len_kind='max_index', recursive='hash', hash='keep'},
            {8, nil, nil, {5, 6}, nil, 3, '2', 1, foo={3, 2, 1}},
        },
        {
            {1, '2', 3, nil, {5, 6}, [8]=8, foo={1, 2, 3}},
            {array_len_kind='max_index', recursive='array', hash='keep'},
            {8, nil, nil, {6, 5}, nil, 3, '2', 1, foo={1, 2, 3}},
        },
        {
            {1, 2, {3, 4, foo={1, 2}}, foo={1, 2, {3, 4}, bar={1, 2}}},
            nil,
            {{3, 4, foo={1, 2}}, 2, 1},
        },
        {
            {1, 2, {3, 4, foo={1, 2}}, foo={1, 2, {3, 4}, bar={1, 2}}},
            {hash='keep'},
            {{3, 4, foo={1, 2}}, 2, 1, foo={1, 2, {3, 4}, bar={1, 2}}},
        },
        {
            {1, 2, {3, 4, foo={1, 2}}, foo={1, 2, {3, 4}, bar={1, 2}}},
            {hash='keep', recursive='array'},
            {{4, 3, foo={1, 2}}, 2, 1, foo={1, 2, {3, 4}, bar={1, 2}}},
        },
        {
            {1, 2, {3, 4, foo={1, 2}}, foo={1, 2, {3, 4}, bar={1, 2}}},
            {hash='keep', recursive='hash'},
            {{3, 4, foo={1, 2}}, 2, 1, foo={{3, 4}, 2, 1, bar={2, 1}}},
        },
        {
            {1, 2, {3, 4, foo={1, 2}}, foo={1, 2, {3, 4}, bar={1, 2}}},
            {hash='keep', recursive='all'},
            {{4, 3, foo={2, 1}}, 2, 1, foo={{4, 3}, 2, 1, bar={2, 1}}},
        },
        {
            {1, 2, 3, 4, foo={bar={}}},
            {hash='keep'},
            {4, 3, 2, 1, foo={bar={}}},
        },
        {
            {1, 2, 3, 4, foo={bar={}}},
            {hash='discard'},
            {4, 3, 2, 1},
        },
        {
            {},
            {hash='keep', recursive='all', array_len_kind='max_index'},
            {},
        },
        {
            {[1001]=1001, [1005]=1005},
            {hash='keep', recursive='all', array_len_kind='max_index'},
            {1005, nil, nil, nil, 1001},
        },
    }) do

        local r = tableutil.reverse(tbl, opts)
        t:eqdict(expected, r, desc)
    end
end


function test.test_reverse_time(t)
    local large_index = 1024 * 1024 * 1024
    local tbl = {[large_index] = 'foo', [large_index + 1]='bar'}

    local start_ms = time.get_ms()

    local r = tableutil.reverse(tbl, {array_len_kind='max_index'})
    local time_used = time.get_ms() - start_ms

    t:eqdict({'bar', 'foo'}, r)
    test.dd(string.format('reverse with large index time_used: %d ms',
                          time_used))
    t:eq(true, time_used < 10)
end


function test.extends(t)

    for _, a, b, desc in t:case_iter(2, {
        {{'a'},         1,             },
        {{'a'},         'a',           },
        {{'a'},         function()end, },
    }) do

        t:err(function()
            tableutil.extends(a, b)
        end, desc)
    end

    for _, a, b, expected, desc in t:case_iter(3, {
        {{1,2},     {3,4},       {1,2,3,4}      },
        {{1,2},     {3},         {1,2,3}        },
        {{1,2},     {nil},       {1,2}          },
        {{1,2},     {},          {1,2}          },
        {{},        {1,2},       {1,2}          },
        {nil,       {1},         nil            },
        {{1,{2,3}}, {4,5},       {1,{2,3},4,5}  },
        {{1},       {{2,3},4,5}, {1,{2,3},4,5}  },
        {{"xx",2},  {3,"yy"},    {"xx",2,3,"yy"}},
        {{1,2},     {3,nil,4},   {1,2,3}        },
        {{1,nil,2}, {3,4},       {1,3,2,4}      },
    }) do

        local rst = tableutil.extends(a, b)

        dd('rst: ', rst)

        t:eqdict(expected, rst, desc)
    end
end


function test.is_empty(t)
    local cases = {
        {{}          , true},
        {{1}         , false},
        {{key='val'} , false},
    }

    for ii, c in ipairs(cases) do
        local tbl, expected = t:unpack(c)
        local msg = 'case: ' .. tostring(ii) .. '-th '
        dd(msg, c)

        local rst = tableutil.is_empty(tbl)
        t:eq(expected, rst)
    end

    t:eq(false, tableutil.is_empty())
end


function test.get(t)
    local table_key = {}
    local cases = {

        {nil,                               '',                                                 nil, 'NotFound'},
        {nil,                               {''},                                               nil, 'NotFound'},
        {nil,                               'a',                                                nil, 'NotFound'},
        {nil,                               {'a'},                                              nil, 'NotFound'},
        {{},                                'a',                                                nil, nil},
        {{},                                {'a'},                                              nil, nil},
        {{},                                'a.b',                                              nil, 'NotFound'},
        {{},                                {'a','b'},                                          nil, 'NotFound'},
        {{a=1},                             '',                                                 nil, nil},
        {{a=1},                             {''},                                               nil, nil},
        {{a=1},                             'a',                                                1,   nil},
        {{a=1},                             {'a'},                                              1,   nil},
        {{a=1},                             'a.b',                                              nil, 'NotTable'},
        {{a=1},                             {'a','b'},                                          nil, 'NotTable'},
        {{a=true},                          'a.b',                                              nil, 'NotTable'},
        {{a=true},                          {'a','b'},                                          nil, 'NotTable'},
        {{a=""},                            'a.b',                                              nil, 'NotTable'},
        {{a=""},                            {'a','b'},                                          nil, 'NotTable'},
        {{a={b=1}},                         'a.b',                                              1,   nil},
        {{a={b=1}},                         {'a','b'},                                          1,   nil},
        {{a={b=1}},                         'a.b.cc',                                           nil, 'NotTable' },
        {{a={b=1}},                         {'a','b','cc'},                                     nil, 'NotTable' },
        {{a={b=1}},                         'a.b.cc.dd',                                        nil, 'NotTable' },
        {{a={b=1}},                         {'a','b','cc','dd'},                                nil, 'NotTable' },
        {{a={b=1}},                         'a.x.cc',                                           nil, 'NotFound' },
        {{a={b=1}},                         {'a','x','cc'},                                     nil, 'NotFound' },
        {{[table_key]=1},                   { table_key },                                      1,   nil},
        {{[table_key]=1},                   {{}},                                               nil, nil},
        {{[table_key]=1},                   {{},{}},                                            nil, 'NotFound'},
        {{[table_key]=1},                   { table_key, table_key },                           nil, 'NotTable'},
        {{[table_key]={[table_key]=1}},     { table_key, table_key },                           1,   nil},
        {{[table_key]={[table_key]=1}},     {{},{}},                                            nil, 'NotFound'},
        {{[table_key]={[table_key]=1}},     { table_key, table_key, table_key },                nil, 'NotTable'},

    }

    for ii, c in ipairs(cases) do
        local tbl, key_path, expected_rst, expected_err = t:unpack(c)
        local msg = 'case: ' .. tostring(ii) .. '-th '
        dd(msg, c)

        local rst, err = tableutil.get(tbl, key_path)
        t:eq(expected_rst, rst)
        t:eq(expected_err, err)

    end
end


function test.set(t)

    local table_key = {}

    for _, tbl, key_path, value, opts, exp_r, exp_err, desc in t:case_iter(6, {
        {
            nil, nil, 'foo', nil,
            nil, 'NotTable',
        },
        {
            nil, '', 'foo', {},
            nil, 'NotTable',
        },
        {
            nil, {''}, 'foo', {},
            nil, 'NotTable',
        },
        {
            nil, 'foo.bar', 123, nil,
            nil, 'NotTable',
        },
        {
            nil, {'foo','bar'}, 123, nil,
            nil, 'NotTable',
        },
        {
            'foo', 'foo.bar', 123, nil,
            nil, 'NotTable',
        },
        {
            'foo', {'foo','bar'}, 123, nil,
            nil, 'NotTable',
        },
        {
            {}, 'foo', 123, nil,
            {foo=123}, nil,
        },
        {
            {}, {'foo'}, 123, nil,
            {foo=123}, nil,
        },
        {
            {}, 'foo.bar', 123, nil,
            {foo={bar=123}}, nil,
        },
        {
            {}, {'foo','bar'}, 123, nil,
            {foo={bar=123}}, nil,
        },
        {
            {foo='abc'}, 'foo.bar', 123, nil,
            nil, 'NotTable',
        },
        {
            {foo='abc'}, {'foo','bar'}, 123, nil,
            nil, 'NotTable',
        },
        {
            {foo='abc'}, 'foo.bar', 123, {override=true},
            {foo={bar=123}}, nil,
        },
        {
            {foo='abc'}, {'foo','bar'}, 123, {override=true},
            {foo={bar=123}}, nil,
        },
        {
            {foo={foo=123}}, 'foo.bar', 123, {override=true},
            {foo={foo=123, bar=123}}, nil,
        },
        {
            {foo={foo=123}}, {'foo','bar'}, 123, {override=true},
            {foo={foo=123, bar=123}}, nil,
        },
        {
            {a={b={c=1}}}, 'a.b.c', 123, {override=true},
            {a={b={c=123}}}, nil,
        },
        {
            {a={b={c=1}}}, {'a','b','c'}, 123, {override=true},
            {a={b={c=123}}}, nil,
        },
        {
            {a={b={c=1}}}, 'a.b.c', 123, {},
            nil, 'KeyPathExist',
        },
        {
            {a={b={c=1}}}, {'a','b','c'}, 123, {},
            nil, 'KeyPathExist',
        },
        {
            {a={b={c=1}}}, 'a.b.c.d', 123, {override=true},
            {a={b={c={d=123}}}}, nil,
        },
        {
            {a={b={c=1}}}, {'a','b','c','d'}, 123, {override=true},
            {a={b={c={d=123}}}}, nil,
        },
        {
            {a={b={c=1}}}, 'a.b.c.d', 123, {},
            nil, 'NotTable',
        },
        {
            {a={b={c=1}}}, {'a','b','c','d'}, 123, {},
            nil, 'NotTable',
        },
        {
            {a={b={c=1}}}, 'a.b.c.d', {e=123}, {override=true},
            {a={b={c={d={e=123}}}}}, nil,
        },
        {
            {a={b={c=1}}}, {'a','b','c','d'}, {e=123}, {override=true},
            {a={b={c={d={e=123}}}}}, nil,
        },
        {
            {a={b={c=1}}}, 'a.b.e.f', {g=123}, {},
            {a={b={c=1, e={f={g=123}}}}}, nil,
        },
        {
            {a={b={c=1}}}, {'a','b','e','f'}, {g=123}, {},
            {a={b={c=1, e={f={g=123}}}}}, nil,
        },
        {
            {[table_key]=1}, {table_key, table_key}, 2, {override=true},
            {[table_key]={[table_key]=2}}, nil
        },
        {
            {[table_key]={[table_key]=1}}, {table_key}, 2, {},
            nil, 'KeyPathExist'
        },
        {
            {[table_key]={[table_key]=1}}, {table_key}, 2, {override=true},
            {[table_key]=2}, nil
        },
        {
            {[table_key]={[table_key]=1}}, {table_key, table_key}, 2, {override=true},
            {[table_key]={[table_key]=2}}, nil
        },
        {
            {[table_key]={[table_key]=1}}, {table_key, table_key, table_key}, 2, {},
            nil, 'NotTable'
        },
        {
            {}, {table_key}, 1, {},
            {[table_key]=1}, nil
        },
        {
            {}, {table_key, table_key}, 1, {},
            {[table_key]={[table_key]=1}}, nil
        },
        {
            {[table_key]=1}, {table_key}, 2, {},
            nil, 'KeyPathExist'
        },
        {
            {[table_key]=1}, {table_key}, 2, {override=true},
            {[table_key]=2}, nil
        },
        {
            {[table_key]=1}, {table_key, table_key}, 2, {},
            nil, 'NotTable'
        },
    }) do
        local r, err, errmsg = tableutil.set(tbl, key_path, value, opts)
        t:eqdict(exp_r, r, string.format('%s %s %s', desc, err, errmsg))
        t:eq(exp_err, err, desc)
    end
end


function test.updatedict(t)

    local cases = {
        {{},            {},            nil,               {}                },
        {{a=1},         {},            nil,               {a=1}             },
        {{a=1},         {a=2},         nil,               {a=2}             },
        {{a=1},         {a=1,b=2},     nil,               {a=1,b=2}         },
        {{},            {a={b={c=1}}}, nil,               {a={b={c=1}}}     },
        {{a='foo'},     {a={b={c=1}}}, nil,               {a={b={c=1}}}     },
        {{a={}},        {a={b={c=1}}}, nil,               {a={b={c=1}}}     },
        {{1},           {a={b={c=1}}}, nil,               {1,a={b={c=1}}}   },
        {{b=1},         {a={b={c=1}}}, nil,               {b=1,a={b={c=1}}} },
        {{a=1},         {a=2},         {force=false},     {a=1}             },
        {{a={b=1}},     {a={b=2}},     {force=false},     {a={b=1}}         },
        {{a={b=1}},     {a=2},         {force=false},     {a={b=1}}         },
        {{a={b={c=1}}}, {a=2},         {recursive=false}, {a=2}             },
        {{a={b={c=1}}}, {a={}},        {recursive=false}, {a={}}            },
        {{a=1},         {a={}},        {recursive=false}, {a={}}            },
    }

    for ii, c in ipairs(cases) do
        local tbl, src, opts, expected_rst = t:unpack(c)
        local msg = 'case: ' .. tostring(ii) .. '-th '
        dd(msg, c)

        local rst = tableutil.update(tbl, src, opts)
        dd('rst:', rst)

        t:eqdict(expected_rst, rst)
    end

    local a = {}
    a.a1 = a
    a.a2 = a

    local b = tableutil.update({}, a)
    t:eq(b.a1, b.a1.a1, 'test loop reference')
    t:eq(b.a1, b.a2, 'two loop references should be equal')
    t:neq(a, b.a1)
end


function test.make_setter(t)

    local function make_v(current_val)
        return 'made: ' .. tostring(current_val)
    end

    for _, dst, k, v, mode, expected, desc in t:case_iter(5, {
        {{},    'x',            2,   nil,       {x=2}},
        {{},    'x',            2,   'keep',    {x=2}},
        {{},    'x',            2,   'replace', {x=2}},
        {{x=1}, 'x',            2,   nil,       {x=2}},
        {{x=1}, 'x',            2,   'keep',    {x=1}},
        {{x=1}, 'x',            2,   'replace', {x=2}},
        {{x=1}, {x=2,y=3},      nil, nil,       {x=2,y=3}},
        {{x=1}, {x=2,y=3},      nil, 'keep',    {x=1,y=3}},
        {{x=1}, {x=2,y=3},      nil, 'replace', {x=2,y=3}},
        {{x=1}, {x=make_v,y=3}, nil, nil,       {x='made: 1',y=3}},
        {{x=1}, {x=make_v,y=3}, nil, 'keep',    {x=1,y=3}},
        {{x=1}, {x=make_v,y=3}, nil, 'replace', {x='made: 1',y=3}},
    }) do

        local setter = tableutil.make_setter(k, v, mode)
        setter(dst)
        local rst = dst
        dd('rst: ', rst)

        t:eqdict(expected, rst, desc)
    end
end


function test.make_setter_invalid_arg(t)

    for _, mode, expected, desc in t:case_iter(2, {
        {nil,           true  },
        {'replace',     true  },
        {'keep',        true  },
        {'foo',         false },
        {0,             false },
        {true,          false },
        {function()end, false },
        {{},            false },
    }) do

        if expected then
            tableutil.make_setter(1, 1, mode)
        else
            t:err(function() tableutil.make_setter(1, 1, mode) end, desc)
        end
    end
end


function test.default_setter(t)

    local function make_v()
        return 'vv'
    end

    for _, dst, k, v, expected, desc in t:case_iter(4, {
        {{},    'x',                 2,    {x=2}},
        {{x=1}, 'x',                 2,    {x=1}},
        {{x=1}, {x=2,y=3},           nil,  {x=1,y=3}},
        {{x=1}, {x=make_v,y=make_v}, nil,  {x=1,y='vv'}},
    }) do

        local setter = tableutil.default_setter(k, v)
        setter(dst)
        local rst = dst
        dd('rst: ', rst)

        t:eqdict(expected, rst, desc)
    end
end


function test.combine_and_add(t)

    local opts_default = nil

    local opts_recursive = { recursive = true }
    local opts_default_value = { default = 1 }
    local opts_recursive_default_value = { recursive = true, default = 1}
    local opts_recursive_default_value_exclude = { recursive = true, default = 1, exclude={a={b={c={d=true}}},g=true} }
    local cases_recursive = {

        {opts_default,                  {x=1,y=true,z=3},               {x=1,y=2,z=true},               {x=2,y=true,z=3}},
        {opts_default,                  {x=1,y=2,z=3},                  {x=1,y=2,z=3},                  {x=2,y=4,z=6}},
        {opts_default,                  {x=1,y=2,z=3},                  {x=1,z=3},                      {x=2,y=2,z=6}},
        {opts_default,                  {x=1,z=3},                      {x=1,y=2,z=3},                  {x=2,z=6}},
        {opts_default,                  {},                             {x=1,y=2,z=3},                  {}},
        {opts_default,                  {x=1,y=2,z=3},                  {},                             {x=1,y=2,z=3}},
        {opts_default,                  {x=1,y=2,z=3},                  {x={x1=1}},                     {x=1,y=2,z=3}},

        {opts_recursive,                {x={y={z=1}},c=1},              {x={y={z=1}},c=1},              {x={y={z=2}},c=2}},
        {opts_recursive,                {x={y={z=1}},c=1,z={}},         {x={y={z=1}},c=1,z=1,d=1},      {x={y={z=2}},c=2,z={}}},
        {opts_recursive,                {x={y={z=1}},c=1,z={}},         {x={y={z=1}},c=1,z=1},          {x={y={z=2}},c=2,z={}} },
        {opts_recursive,                {x={y=1},c=1},                  {x={z=1},c=1},                  {x={y=1},c=2}},


        {opts_default_value,            {x=1,y=2,z=3},                  {x=1,z=3},                      {x=2,y=2,z=6}},
        {opts_default_value,            {x=1,z=3},                      {x=1,y=2,z=3},                  {x=2,y=3,z=6}},
        {opts_default_value,            {},                             {x=1,y=2,z=3},                  {x=2,y=3,z=4}},
        {opts_default_value,            {x=1,y=2,z=3},                  {},                             {x=1,y=2,z=3}},
        {opts_default_value,            {x=1,y=2,z=3},                  {x={x1=1}},                     {x=1,y=2,z=3}},
        {opts_default_value,            {c=1},                          {x={z=1},c=1},                  {c=2}},

        {opts_recursive_default_value,  {c=1},                          {x={z=1},c=1},                  {x={z=2},c=2}},
        {opts_recursive_default_value,  {x={y={z=1}},c=1},              {x={y={z=1}},c=1},              {x={y={z=2}},c=2}},
        {opts_recursive_default_value,  {x={y={z=1}},c=1,z={}},         {x={y={z=1}},c=1,z=1,d=1},      {x={y={z=2}},c=2,z={},d=2}},
        {opts_recursive_default_value,  {x={y={z=1}},c=1,z={}},         {x={y={z=1,d=1}},c=1,z=1},      {x={y={z=2,d=2}},c=2,z={}}},
        {opts_recursive_default_value,  {x={y=1},c=1},                  {x={z=1},c=1},                  {x={y=1,z=2},c=2}},


        {opts_recursive_default_value_exclude,  {a={b={c={d=1},e=1}},f=1,g=1},  {a={b={c={d=1},e=1}},f=2,e=1,g=1},  {a={b={c={d=1},e=2}},f=3,e=2,g=1}},

    }

    for ii, case in ipairs(cases_recursive) do

        local opts, a, b, expected = t:unpack(case)

        local rst = tableutil.combine(a, b, function(a, b) return a + b end, opts)
        t:eqdict(expected, rst)

        local copy_a = tableutil.dup(a, true)

        tableutil.combineto(copy_a, b, function(a, b) return a + b end, opts)
        t:eqdict(expected, copy_a)

        local rst = tableutil.add(a, b, opts)
        t:eqdict(expected, rst)

        local copy_a = tableutil.dup(a, true)

        tableutil.addto(copy_a, b, opts)
        t:eqdict(expected, copy_a)

    end
end
