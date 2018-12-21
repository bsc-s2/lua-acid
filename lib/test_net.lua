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


function test.ip_class_and_xxx(t)

    local cases = {
        {'1.2.3.4',     'PUB'},
        {'255.255.0.0', 'PUB'},
        {'171.0.0.0',   'PUB'},
        {'173.0.0.0',   'PUB'},
        {'172.15.0.0',  'PUB'},
        {'172.32.0.0',  'PUB'},
        {'9.0.0.0',     'PUB'},
        {'11.0.0.0',    'PUB'},
        {'192.167.0.0', 'PUB'},
        {'192.169.0.0', 'PUB'},
        {'191.168.0.0', 'PUB'},
        {'193.168.0.0', 'PUB'},

        {'127.0.0.1',   'INN'},
        {'127.0.0.255', 'INN'},
        {'172.16.0.0',  'INN'},
        {'172.17.0.0',  'INN'},
        {'172.21.0.0',  'INN'},
        {'172.30.0.0',  'INN'},
        {'172.31.0.0',  'INN'},
        {'10.0.0.0',    'INN'},
        {'192.168.0.0', 'INN'},
    }

    for ii, c in ipairs(cases) do

        local inp, expected = t:unpack(c)
        local msg = 'case: ' .. tostring(ii) .. '-th '
        dd(msg, c)

        local rst = net.ip_class(inp)
        dd('rst: ', rst)

        t:eq(expected, rst, msg)

        if expected == 'PUB' then
            t:eq(true, net.is_pub(inp))
            t:eq(false, net.is_inn(inp))

            t:eqlist({inp}, net.choose_pub({inp, '192.168.0.0'}))
            t:eqlist({inp}, net.choose_pub({'192.168.0.0', inp}))
            t:eqlist({inp}, net.choose({inp, '192.168.0.0'}, 'PUB'))
            t:eqlist({inp}, net.choose({'192.168.0.0', inp}, 'PUB'))
        else
            t:eq(false, net.is_pub(inp))
            t:eq(true, net.is_inn(inp))

            t:eqlist({inp}, net.choose_inn({inp, '1.1.1.1'}))
            t:eqlist({inp}, net.choose_inn({'1.1.1.1', inp}))
            t:eqlist({inp}, net.choose({inp, '1.1.1.1'}, 'INN'))
            t:eqlist({inp}, net.choose({'1.1.1.1', inp}, 'INN'))
        end
    end
end


function test.ips_prefer(t)

    local cases = {
        {{}, net.PUB, {}},
        {{}, net.INN, {}},

        {{'1.2.3.4'}, net.PUB, {'1.2.3.4'}},
        {{'1.2.3.4'}, net.INN, {'1.2.3.4'}},

        {{'172.16.0.1'}, net.PUB, {'172.16.0.1'}},
        {{'172.16.0.1'}, net.INN, {'172.16.0.1'}},

        {{'172.16.0.1', '1.2.3.4'}, net.PUB, {'1.2.3.4', '172.16.0.1'}},
        {{'172.16.0.1', '1.2.3.4'}, net.INN, {'172.16.0.1', '1.2.3.4'}},

        {{'1.2.3.4', '172.16.0.1'}, net.PUB, {'1.2.3.4', '172.16.0.1'}},
        {{'1.2.3.4', '172.16.0.1'}, net.INN, {'172.16.0.1', '1.2.3.4'}},
    }

    for ii, c in ipairs(cases) do

        local inp_ips, inp_clz, expected = t:unpack(c)
        local msg = 'case: ' .. tostring(ii) .. '-th '
        dd(msg, c)

        local rst = net.ips_prefer(inp_ips, inp_clz)
        dd('rst: ', rst)

        t:eqlist(expected, rst, msg)
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

function test.ip_to_binary(t)
    local cases = {
        {'0.0.0.0',                     0 },
        {'1.1.1.1',                     16843009},
        {'255.255.255.255',             4294967295},
        {'255.255.255.1',               4294967041},
        {'255.255.1.1',                 4294902017},
        {'255.1.1.1',                   4278255873},
        {'0.1.1.255',                   66047},
        {'0.1.255.255',                 131071},
        {'0.255.255.255',               16777215},
        {'0.1.1.255',                   66047},
        {'127.0.0.1',                   2130706433},
        {'123.123.123.123',             2071690107},
        {'256.1.1.1',                   nil},
    }

    for ii, c in ipairs(cases) do
        local inp, expected = t:unpack(c)
        t:eq(expected, net.ip_to_binary(inp))
    end

end

function test.binary_to_ip(t)
    local cases = {
        {'0.0.0.0',                     0 },
        {'1.1.1.1',                     16843009},
        {'255.255.255.255',             4294967295},
        {'255.255.255.1',               4294967041},
        {'255.255.1.1',                 4294902017},
        {'255.1.1.1',                   4278255873},
        {'0.1.1.255',                   66047},
        {'0.1.255.255',                 131071},
        {'0.255.255.255',               16777215},
        {'0.1.1.255',                   66047},
        {'127.0.0.1',                   2130706433},
        {'123.123.123.123',             2071690107},
    }

    for ii, c in ipairs(cases) do
        local ip, binary = t:unpack(c)
        t:eq(ip, net.binary_to_ip(binary))
    end
end

function test.ip_in_cidr(t)

    local cases = {
        {'127.0.0.1',                     {'127.0.0.1'},                            true},
        {'127.0.0.127',                   {'127.0.0.1/25'},                         true},
        {'127.15.255.255',                {'127.0.0.1/12'},                         true},
        {'124.0.0.0',                     {'127.0.0.1/6'},                          true},
        {'126.255.255.255',               {'127.0.0.1/1'},                          true},
        {'255.255.255.255',               {'127.0.0.1/0'},                          true},
        {'10.13.2.14',                    {'127.0.0.1','10.13.2.14/28'},            true},

        {'127.0.0.8',                     {'127.0.0.1/29'},          false},
        {'127.0.0.1.1',                   {'127.0.0.1/0'},           false},
        {'127.0.0.1',                     {'127.0.0.1/122'},         false},

    }

    for ii, c in ipairs(cases) do
        local ip, cidrs, expected = t:unpack(c)
        t:eq(expected, net.ip_in_cidr(ip, cidrs))
    end
end


function test.parse_cidr(t)
    local cases = {
        {'127.0.0.1/32',        {'127.0.0.1',   '127.0.0.1',        '255.255.255.255'}},
        {'127.0.0.1/31',        {'127.0.0.0',   '127.0.0.1',        '255.255.255.254'}},
        {'127.0.0.1/30',        {'127.0.0.0',   '127.0.0.3',        '255.255.255.252'}},
        {'127.0.0.1/29',        {'127.0.0.0',   '127.0.0.7',        '255.255.255.248'}},
        {'127.0.0.1/28',        {'127.0.0.0',   '127.0.0.15',       '255.255.255.240'}},
        {'127.0.0.1/27',        {'127.0.0.0',   '127.0.0.31',       '255.255.255.224'}},
        {'127.0.0.1/26',        {'127.0.0.0',   '127.0.0.63',       '255.255.255.192'}},
        {'127.0.0.1/25',        {'127.0.0.0',   '127.0.0.127',      '255.255.255.128'}},
        {'127.0.0.1/24',        {'127.0.0.0',   '127.0.0.255',      '255.255.255.0'}},
        {'127.0.0.1/23',        {'127.0.0.0',   '127.0.1.255',      '255.255.254.0'}},
        {'127.0.0.1/22',        {'127.0.0.0',   '127.0.3.255',      '255.255.252.0'}},
        {'127.0.0.1/21',        {'127.0.0.0',   '127.0.7.255',      '255.255.248.0'}},
        {'127.0.0.1/20',        {'127.0.0.0',   '127.0.15.255',     '255.255.240.0'}},
        {'127.0.0.1/19',        {'127.0.0.0',   '127.0.31.255',     '255.255.224.0'}},
        {'127.0.0.1/18',        {'127.0.0.0',   '127.0.63.255',     '255.255.192.0'}},
        {'127.0.0.1/17',        {'127.0.0.0',   '127.0.127.255',    '255.255.128.0'}},
        {'127.0.0.1/16',        {'127.0.0.0',   '127.0.255.255',    '255.255.0.0'}},
        {'127.0.0.1/15',        {'127.0.0.0',   '127.1.255.255',    '255.254.0.0'}},
        {'127.0.0.1/14',        {'127.0.0.0',   '127.3.255.255',    '255.252.0.0'}},
        {'127.0.0.1/13',        {'127.0.0.0',   '127.7.255.255',    '255.248.0.0'}},
        {'127.0.0.1/12',        {'127.0.0.0',   '127.15.255.255',   '255.240.0.0'}},
        {'127.0.0.1/11',        {'127.0.0.0',   '127.31.255.255',   '255.224.0.0'}},
        {'127.0.0.1/10',        {'127.0.0.0',   '127.63.255.255',   '255.192.0.0'}},
        {'127.0.0.1/9',         {'127.0.0.0',   '127.127.255.255',  '255.128.0.0'}},
        {'127.0.0.1/8',         {'127.0.0.0',   '127.255.255.255',  '255.0.0.0'}},
        {'127.0.0.1/7',         {'126.0.0.0',   '127.255.255.255',  '254.0.0.0'}},
        {'127.0.0.1/6',         {'124.0.0.0',   '127.255.255.255',  '252.0.0.0'}},
        {'127.0.0.1/5',         {'120.0.0.0',   '127.255.255.255',  '248.0.0.0'}},
        {'127.0.0.1/4',         {'112.0.0.0',   '127.255.255.255',  '240.0.0.0'}},
        {'127.0.0.1/3',         {'96.0.0.0' ,   '127.255.255.255',  '224.0.0.0'}},
        {'127.0.0.1/2',         {'64.0.0.0' ,   '127.255.255.255',  '192.0.0.0'}},
        {'127.0.0.1/1',         {'0.0.0.0'  ,   '127.255.255.255',  '128.0.0.0'}},
        {'127.0.0.1/0',         {'0.0.0.0'  ,   '255.255.255.255',  '0.0.0.0'}},
    }

    for ii, c in ipairs(cases) do
        local cidr, expected = t:unpack(c)
        local min, max, mask = net.parse_cidr(cidr)
        t:eq(net.ip_to_binary(expected[1]), min)
        t:eq(net.ip_to_binary(expected[2]), max)
        t:eq(net.ip_to_binary(expected[3]), mask)
    end


    local badcases ={
        {'127.0.0.1.1/0',       {nil  ,         'invalid net'}},
        {'127.0.0.1/122',       {nil  ,         'invalid mask'}},
    }

    for ii, c in ipairs(badcases) do
        local cidr, expected = t:unpack(c)
        local min, max = net.parse_cidr(cidr)
        t:eq(expected[1], min)
        t:eq(expected[2], max)
    end

end
