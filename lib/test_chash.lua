local chash = require('acid.chash')
local time = require('acid.time')


math.randomseed(ngx.now() * 1000)


function test.basic(t)
    for _, nr_server, nr_vn, nr_choose, exp_err, desc in t:case_iter(4, {
        {0,   0,    0,   nil},
        {0,   0,    1,   'ServerNotEnough'},
        {1,   1,    1,   nil              },
        {1,   1,    2,   'ServerNotEnough'},
        {2,   1,    2,   nil              },
        {2,   1000, 2,   nil              },
        {2,   1000, 3,   'ServerNotEnough'},
        {2,   100,  2,   nil              },
        {100, 100,  100, nil              },
    }) do
        local servers = {}
        for _ = 1, nr_server do
            local server_name = 'test_server_' .. tostring(math.random(99999))
            servers[server_name] = nr_vn
        end

        local c_hash, err, errmsg = chash.new(servers)
        t:eq(nil, err, errmsg)

        local server_names, err, errmsg = c_hash:choose_server(
                'key_foo', {nr_choose=nr_choose})
        t:eq(exp_err, err, desc)
        if err == nil then
            t:eq(nr_choose, #server_names, desc)
        end
    end
end


function test.consistent_rate(t)
    local server_names = {
        'server_' .. tostring(math.random(1, 99999)),
        'server_' .. tostring(math.random(1, 99999)),
        'server_' .. tostring(math.random(1, 99999)),
    }

    local c_hash, err, errmsg = chash.new({[server_names[1]] = 1024},
                                          {debug = true})
    t:eq(nil, err, errmsg)

    t:eq(0, c_hash.consistent_rate)
    t:eq(1, c_hash.load_distribution[server_names[1]])

    local info, err, errmsg = c_hash:update_server({[server_names[2]] = 1024})
    t:eq(nil, err, errmsg)
    test.dd(info)

    t:eq(true, 0.1 > math.abs(info.consistent_rate - 0.5))
    t:eq(true, 0.1 > math.abs(info.load_distribution[server_names[1]] - 0.5))
    t:eq(true, 0.1 > math.abs(info.load_distribution[server_names[2]] - 0.5))

    local info, err, errmsg = c_hash:update_server({[server_names[3]] = 1024})
    t:eq(nil, err, errmsg)
    test.dd(info)

    t:eq(true, 0.1 > math.abs(info.consistent_rate - 2.0/3.0))
    t:eq(true, 0.1 > math.abs(info.load_distribution[server_names[1]] - 1.0/3.0))
    t:eq(true, 0.1 > math.abs(info.load_distribution[server_names[2]] - 1.0/3.0))
    t:eq(true, 0.1 > math.abs(info.load_distribution[server_names[3]] - 1.0/3.0))
end


function test.consistent_rate_virtual_node_number_change(t)
    for _, nr_server, nr_vn_old, nr_vn_new, rate, _ in t:case_iter(4, {
        {200,  100,  50,  0.5},
        {200,  100,  80,  0.8},
        {100,  1000, 600, 0.6},
        {1000, 100,  40,  0.4},
    }) do
        local servers = {}
        for _ = 1, nr_server do
            local server_name = 'test_server_' .. tostring(math.random(99999))
            servers[server_name] = nr_vn_old
        end

        local c_hash, err, errmsg = chash.new(servers, {debug = true})
        t:eq(nil, err, errmsg)

        for server_name, _ in pairs(servers) do
            servers[server_name] = nr_vn_new
        end
        local info, err, errmsg = c_hash:update_server(servers)
        t:eq(nil, err, errmsg)

        test.dd(info.consistent_rate)
        t:eq(true, 0.05 > math.abs(info.consistent_rate - rate))
    end
end


function test.consistent_rate_add_server(t)
    for _, nr_server, nr_server_add, nr_vn, rate, _ in t:case_iter(4, {
        {200, 200, 128, 0.5},
        {270, 30,  128, 0.9},
    }) do
        local servers = {}
        for _ = 1, nr_server do
            local server_name = 'test_server_' .. tostring(math.random(99999))
            servers[server_name] = nr_vn
        end

        local c_hash, err, errmsg = chash.new(servers, {debug = true})
        t:eq(nil, err, errmsg)

        local add_servers = {}
        for _ = 1, nr_server_add do
            local server_name = 'test_server_' .. tostring(math.random(99999))
            add_servers[server_name] = nr_vn
        end

        local info, err, errmsg = c_hash:update_server(add_servers)
        t:eq(nil, err, errmsg)

        test.dd(info.consistent_rate)
        t:eq(true, 0.05 > math.abs(info.consistent_rate - rate))
    end
end


function test.consistent_rate_real(t)
    for _, nr_server, nr_server_add, nr_vn, rate, _ in t:case_iter(4, {
        {200, 200, 128, 0.5},
        {90,  10,  128, 0.9},
    }) do
        local keys = {}
        for _ = 1, 1000 * 10 do
            table.insert(keys, 'test-key' .. tostring(math.random(9999999)))
        end

        local servers = {}
        for _ = 1, nr_server do
            local server_name = 'test_server_' .. tostring(math.random(99999))
            servers[server_name] = nr_vn
        end

        local c_hash, err, errmsg = chash.new(servers, {debug = true})
        t:eq(nil, err, errmsg)

        local old_server = {}
        for _, key in ipairs(keys) do
            local server_names, err, errmsg = c_hash:choose_server(key)
            t:eq(nil, err, errmsg)
            old_server[key] = server_names[1]
        end

        local add_servers = {}
        for _ = 1, nr_server_add do
            local server_name = 'test_server_' .. tostring(math.random(99999))
            add_servers[server_name] = nr_vn
        end

        local _, err, errmsg = c_hash:update_server(add_servers)
        t:eq(nil, err, errmsg)

        local new_server = {}
        for _, key in ipairs(keys) do
            local server_names, err, errmsg = c_hash:choose_server(key)
            t:eq(nil, err, errmsg)
            new_server[key] = server_names[1]
        end

        local consistent_n = 0
        for _, key in ipairs(keys) do
            if old_server[key] == new_server[key] then
                consistent_n = consistent_n + 1
            end
        end

        local real_rate = consistent_n / #keys
        t:eq(true, 0.05 > math.abs(real_rate - rate))
    end
end


function test.consistent_rate_real_pick_3(t)
    for _, nr_server, nr_server_add, nr_vn, rate, _ in t:case_iter(4, {
        {200, 200, 100, 0.5},
        {180, 20,  100, 0.9},
    }) do
        local keys = {}
        for _ = 1, 1000 * 10 do
            table.insert(keys, 'test-key' .. tostring(math.random(9999999)))
        end

        local servers = {}
        for _ = 1, nr_server do
            local server_name = 'test_server_' .. tostring(math.random(99999))
            servers[server_name] = nr_vn
        end

        local c_hash, err, errmsg = chash.new(servers)
        t:eq(nil, err, errmsg)

        local old_server = {{}, {}, {}}
        for _, key in ipairs(keys) do
            local server_names, err, errmsg = c_hash:choose_server(
                    key, {nr_choose = 3})
            t:eq(nil, err, errmsg)
            old_server[1][key] = server_names[1]
            old_server[2][key] = server_names[2]
            old_server[3][key] = server_names[3]
        end

        for _ = 1, nr_server_add do
            local server_name = 'test_server_' .. tostring(math.random(99999))
            servers[server_name] = nr_vn
        end

        local _, err, errmsg = c_hash:update_server(servers)
        t:eq(nil, err, errmsg)

        local new_server = {{}, {}, {}}
        for _, key in ipairs(keys) do
            local server_names, err, errmsg = c_hash:choose_server(
                    key, {nr_choose = 3})
            t:eq(nil, err, errmsg)
            new_server[1][key] = server_names[1]
            new_server[2][key] = server_names[2]
            new_server[3][key] = server_names[3]
        end

        local real_rate = {}
        for i = 1, 3 do
            local consistent_n = 0
            for _, key in ipairs(keys) do
                if old_server[i][key] == new_server[i][key] then
                    consistent_n = consistent_n + 1
                end
            end

            table.insert(real_rate, consistent_n / #keys)
        end

        t:eq(true, 0.05 > math.abs(real_rate[1] - rate))
    end
end


function test.performance_choose_server(t)
    for _, nr_server, nr_vn, nr_choose, nr_rep, ms_use, desc in t:case_iter(5, {
        {  200,  1024, 1,  1024 * 10, 1000},
        {  200,  1024, 10, 1024 * 10, 1000},
        {  400,  512,  1,  1024 * 10, 1000},
        {  400,  512,  10, 1024 * 10, 1000},
        { 4000,  128,  1,  1024 * 10, 1000},

    }) do

        local servers = {}
        for _ = 1, nr_server do
            local server_name = 'test_server_' .. tostring(math.random(99999))
            servers[server_name] = nr_vn
        end

        local c_hash, err, errmsg = chash.new(servers)
        t:eq(nil, err, errmsg)

        local keys = {}
        for _ = 1, nr_rep do
            table.insert(keys, 'test-key' .. tostring(math.random(9999999)))
        end

        local start_ms = time.get_ms()

        for key in ipairs(keys) do
            c_hash:choose_server(key, {nr_choose = nr_choose})
        end

        local end_ms = time.get_ms()

        local ms_used = end_ms - start_ms

        test.dd(string.format('ms used for: %s is: %d', desc, ms_used))

        t:eq(true, ms_used < ms_use)
    end
end


function test.performance_reinit(t)
    for _, nr_server, nr_vn, nr_rep, ms_use, desc in t:case_iter(4, {
        {  200, 100,  1,  2000},
        { 2000, 10,   1,  2000},
    }) do

        local servers = {}
        for _ = 1, nr_server do
            local server_name = 'test_server_' .. tostring(math.random(99999))
            servers[server_name] = nr_vn
        end

        local start_ms = time.get_ms()

        for _ = 1, nr_rep do
            local c_hash, err, errmsg = chash.new(servers)
            t:eq(nil, err, errmsg)
            t:neq(nil, c_hash, desc)
        end

        local end_ms = time.get_ms()

        local ms_used = end_ms - start_ms

        test.dd(string.format('ms used for: %s is: %d', desc, ms_used))

        t:eq(true, ms_use > ms_used, desc)
    end
end
