local net = require('acid.net')

local dd = test.dd


function test.is_ip4(t)

    local cases = {

        {true,          false},
        {false,         false},
        {1,             false},
        {0,             false},
        {'',            false},
        {'1',           false},
        {{},            false},
        {'1.',          false},
        {'1.1',         false},
        {'1.1.',        false},
        {'1.1.1',       false},
        {'1.1.1.',      false},
        {'.1.1.1',      false},
        {'x.1.1.1',     false},
        {'1.x.1.1',     false},
        {'1.1.x.1',     false},
        {'1.1.1.x',     false},
        {'1.1.1.1.',    false},
        {'.1.1.1.1',    false},
        {'1:1.1.1',     false},
        {'1:1:1.1',     false},
        {'256.1.1.1',   false},
        {'1.256.1.1',   false},
        {'1.1.256.1',   false},
        {'1.1.1.256',   false},
        {'1.1.1.1.',    false},
        {'1.1.1.1.1',   false},
        {'1.1.1.1.1.',  false},
        {'1.1.1.1.1.1', false},

        {'0.0.0.0',         true},
        {'0.0.0.1',         true},
        {'0.0.1.0',         true},
        {'0.1.0.0',         true},
        {'1.0.0.0',         true},
        {'127.0.0.1',       true},
        {'255.255.255.255', true},
    }

    for ii, c in ipairs(cases) do

        local inp, expected = t:unpack(c)
        local msg = 'case: ' .. tostring(ii) .. '-th '
        dd(msg, c)

        local rst = net.is_ip4(inp)
        dd('rst: ', rst)

        t:eq(expected, rst, msg)
    end
end


function test.is_ip4_loopback(t)

    local cases = {

        {'0.0.0.0',         false},
        {'1.1.1.1',         false},
        {'126.0.1.0',       false},
        {'15.1.0.0',        false},
        {'255.0.0.255',     false},
        {'126.0.0.1',       false},
        {'128.0.0.1',       false},
        {'255.255.255.255', false},
        {'127.0.0.0',       true},
        {'127.1.1.1',       true},
        {'127.0.1.0',       true},
        {'127.1.0.0',       true},
        {'127.0.0.255',     true},
        {'127.0.0.1',       true},
        {'127.255.255.255', true},
    }

    for ii, c in ipairs(cases) do

        local inp, expected = t:unpack(c)
        local msg = 'case: ' .. tostring(ii) .. '-th '
        dd(msg, c)

        local rst = net.is_ip4_loopback(inp)
        dd('rst: ', rst)

        t:eq(expected, rst, msg)
    end
end


function test.parse_ip_regexs(t)

    local cases = {
        {'1.2.3.4',          {'1.2.3.4'}},
        {'1.2.3.4,127.0.',   {'1.2.3.4', '127.0.'}},
        {'-1.2.3.4,127.0.',  {{'1.2.3.4', false}, '127.0.'}},
        {'-1.2.3.4,-127.0.', {{'1.2.3.4', false}, {'127.0.', false}}},
    }

    for ii, c in ipairs(cases) do

        local inp, expected = unpack(c)

        local msg = 'case: ' .. tostring(ii) .. '-th '
        dd(msg, c)

        local rst = net.parse_ip_regexs(inp)
        dd('rst: ', rst)

        t:eqdict(expected, rst, msg)
    end
end


function test.parse_ip_regexs_err(t)

    local cases = {
        {'',},
        {',',},
        {' , ',},
        {'1,',},
        {',1',},
        {'-1,',},
        {',-1',},
        {'127,-',},
        {'-,127',},
    }

    for ii, c in ipairs(cases) do

        local inp = unpack(c)

        local msg = 'case: ' .. tostring(ii) .. '-th '
        dd(msg)

        t:err(function ()
            net.parse_ip_regexs(inp)
        end, msg)

    end
end


function test.choose_by_regex(t)

    local cases = {
        {{'127.0.0.1', '192.168.0.1'}, {'^127[.]'},
         {'127.0.0.1'}},

        {{'127.0.0.1', '192.168.0.1'}, {'^2'},
         {}},

        {{'127.0.0.1', '192.168.0.1'}, {'^[.]'},
         {}},

        {{'127.0.0.1', '192.168.0.1'}, {'^1'},
         {'127.0.0.1', '192.168.0.1'}},

        -- negative match
        {{'127.0.0.1', '192.168.0.1'}, {{'^1', false}},
         {}},

        {{'127.0.0.1', '192.168.0.1'}, {{'^127', false}, {'^192', false}},
         {}},

        {{'127.0.0.1', '192.168.0.1'}, {{'^12', false}},
         {'192.168.0.1'}},

        {{'127.0.0.1', '192.168.0.1'}, {'^22', {'^12', false}},
         {}},
    }

    for ii, c in ipairs(cases) do

        local ips, regexs, expected = unpack(c)

        local msg = 'case: ' .. tostring(ii) .. '-th '
        dd(msg, c)

        local rst = net.choose_by_regex(ips, regexs)
        dd('rst: ', rst)

        t:eqdict(expected, rst, msg)
    end
end
