local net = require('acid.net')

local dd = test.dd


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
