local chash = require('acid.chash')
local consistenthash = require('consistenthash')
local time = require('acid.time')


math.randomseed(ngx.now() * 1000)


function test.consistenthash_get(t)
    for _, nr_server, nr_choose, nr_rep, desc in t:case_iter(3, {
        {500, 1, 1000 * 10},

    }) do

        local server_names = {}
        for _ = 1, nr_server do
            local server_name = 'test_server_' .. tostring(math.random(99999))
            table.insert(server_names, server_name)
        end

        local c_hash = consistenthash:new(server_names)

        local keys = {}
        for _ = 1, nr_rep do
            table.insert(keys, 'test-key' .. tostring(math.random(9999999)))
        end

        local start_ms = time.get_ms()

        for key in ipairs(keys) do
            c_hash:get(key, nr_choose)
        end

        local end_ms = time.get_ms()

        local ms_used = end_ms - start_ms

        test.dd(string.format('consistenthash get ms used for: %s is: %d',
                              desc, ms_used))
    end
end


function test.consistenthash_new(t)
    for _, nr_server, nr_rep, desc in t:case_iter(2, {
        {500, 1},

    }) do

        local server_names = {}
        for _ = 1, nr_server do
            local server_name = 'test_server_' .. tostring(math.random(99999))
            table.insert(server_names, server_name)
        end

        local start_ms = time.get_ms()

        for _ = 1, nr_rep do
            local c_hash = consistenthash:new(server_names)
        end

        local end_ms = time.get_ms()

        local ms_used = end_ms - start_ms

        test.dd(string.format('consistenthash new ms used for: %s is: %d',
                              desc, ms_used))

        --ngx.log(ngx.ERR, 'worker pid: ' .. tostring(ngx.worker.pid()))
        --ngx.sleep(100)
    end
end


function test.chash_choose_server(t)
    for _, nr_server, nr_vn, nr_choose, nr_rep, desc in t:case_iter(4, {
        {500, 160, 1, 1000 * 10},

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

        test.dd(string.format('chash choose server ms used for: %s is: %d',
                              desc, ms_used))
    end
end


function test.chash_new(t)
    for _, nr_server, nr_vn, nr_rep, desc in t:case_iter(3, {
        {500, 160, 1},
    }) do

        local servers = {}
        for _ = 1, nr_server do
            local server_name = 'test_server_' .. tostring(math.random(99999))
            servers[server_name] = nr_vn
        end

        local start_ms = time.get_ms()

        for _ = 1, nr_rep do
            local c_hash, err, errmsg = chash.new(servers)
        end

        local end_ms = time.get_ms()

        local ms_used = end_ms - start_ms

        test.dd(string.format('chash new ms used for: %s is: %d',
                              desc, ms_used))
        --ngx.log(ngx.ERR, 'worker pid: ' .. tostring(ngx.worker.pid()))
        --ngx.sleep(100)
    end
end
