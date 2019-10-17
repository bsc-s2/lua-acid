local strutil = require('acid.strutil')
local tableutil = require('acid.tableutil')
local time = require('acid.time')

local to_str = strutil.to_str
local NR_BUCKET = math.pow(2, 32)

local _M = {}

local _mt = {__index = _M}


local function compare_position(point1, point2)
    if point1.position < point2.position then
        return true
    end

    return false
end


local function sort_and_spread(points)
    local none_empty_index

    local max_collision = 0

    for index, points_in_one_index in ipairs(points) do
        if index % 1000 == 0 then
            ngx.sleep(0.001)
        end

        local collision = #points_in_one_index

        if collision > 0 then
            none_empty_index = index
        end

        if collision > 1 then
            table.sort(points_in_one_index, compare_position)
        end

        if collision > max_collision then
            max_collision = collision
        end
    end

    ngx.log(ngx.INFO, string.format(
            'hash of %d points, max collision is: %d',
            #points, max_collision))

    local curr_index = none_empty_index

    for _ = 1, #points - 1 do
        local pre_index = curr_index - 1
        if pre_index == 0 then
            pre_index = #points
        end

        if #points[pre_index] == 0 then
            table.insert(points[pre_index], points[curr_index][1])
        end

        curr_index = pre_index
    end
end


local function get_position_list(points)
    local positions = {}

    for _, points_in_one_index in ipairs(points) do
        for _, point in ipairs(points_in_one_index) do
            if #positions == 0 or
                    point.position > positions[#positions].position then
                table.insert(positions,
                             {position = point.position,
                              server_name = point.server_name})
            end
        end
    end

    return positions
end


local function merge_sort_postions(old_positions, new_positions)
    local merged_positions = {}

    local index_old = 1
    local index_new = 1

    while true do
        if index_old > #old_positions then
            break
        end

        if index_new > #new_positions then
            break
        end

        local old_position = old_positions[index_old]
        local new_position = new_positions[index_new]

        if old_position.position <= new_position.position then
            table.insert(merged_positions,
                         {old_position.position,
                          old_position.server_name,
                          new_position.server_name})
            index_old = index_old + 1
        else
            table.insert(merged_positions,
                         {new_position.position,
                          old_position.server_name,
                          new_position.server_name})
            index_new = index_new + 1
        end
    end

    if index_old <= #old_positions then
        for index = index_old, #old_positions do
            table.insert(merged_positions,
                         {old_positions[index].position,
                          old_positions[index].server_name,
                          new_positions[1].server_name})
        end
    end

    if index_new <= #new_positions then
        for index = index_new, #new_positions do
            table.insert(merged_positions,
                         {new_positions[index].position,
                          old_positions[1].server_name,
                          new_positions[index].server_name})
        end
    end

    return merged_positions
end


local function calc_consistent_rate(old_points, new_points)
    local old_positions = get_position_list(old_points)
    if #old_positions == 0 then
        return 0
    end

    local new_positions = get_position_list(new_points)
    if #new_positions == 0 then
        return 0
    end

    local merged_positions = merge_sort_postions(old_positions, new_positions)

    local consistent_n = 0

    for index = 1, #merged_positions do
        local bucket_n
        if index == 1 then
            bucket_n = NR_BUCKET - merged_positions[#merged_positions][1] +
                    merged_positions[index][1]
        else
            bucket_n = merged_positions[index][1] -
                    merged_positions[index - 1][1]
        end

        if merged_positions[index][2] == merged_positions[index][3] then
            consistent_n = consistent_n + bucket_n
        end
    end

    return consistent_n / NR_BUCKET
end


local function calc_load_distribution(points)
    local load_distribution = {}

    local positions = get_position_list(points)

    for index = 1, #positions do
        local bucket_n
        if index == 1 then
            bucket_n = NR_BUCKET - positions[#positions].position +
                    positions[index].position
        else
            bucket_n = positions[index].position -
                    positions[index - 1].position
        end

        local server_name = positions[index].server_name
        if load_distribution[server_name] == nil then
            load_distribution[server_name] = 0
        end

        load_distribution[server_name] = load_distribution[server_name] + bucket_n
    end

    for server_name, bucket_n in pairs(load_distribution) do
        load_distribution[server_name] = bucket_n / NR_BUCKET
    end

    return load_distribution
end


function _M.reinit(c_hash)
    local points = {}
    local nr_point = 0

    local init_ms_used = {}
    local start_ts = time.get_ms()

    for _, nr_virtual_node in pairs(c_hash.servers) do
        nr_point = nr_point + nr_virtual_node
    end

    for point_index = 1, nr_point do
        points[point_index] = {}
    end

    init_ms_used.init_array = time.get_ms() - start_ts

    local count = 0
    for server_name, nr_virtual_node in pairs(c_hash.servers) do
        count = count + 1
        if count % 100 == 0 then
            ngx.sleep(0.001)
        end
        for i = 1, nr_virtual_node do
            local hash_key = server_name .. tostring(i)
            local hash_code = c_hash.hash_func(hash_key)
            hash_code = (hash_code % NR_BUCKET) + 1

            local point = {
                server_name = server_name,
                virtual_node_seq = i,
                position = hash_code,
            }

            local point_index = math.ceil(
                    nr_point * hash_code / NR_BUCKET)

            table.insert(points[point_index], point)
        end
    end

    init_ms_used.hash = time.get_ms() - start_ts

    sort_and_spread(points)

    init_ms_used.sort = time.get_ms() - start_ts

    if c_hash.debug then
        local consistent_rate = calc_consistent_rate(c_hash.points, points)
        ngx.log(ngx.INFO, string.format('after reinit, consistent rate is: %f',
                                        consistent_rate))
        c_hash.consistent_rate = consistent_rate

        init_ms_used.consistent_rate = time.get_ms() - start_ts

        local load_distribution = calc_load_distribution(points)
        ngx.log(ngx.INFO, string.format('after reinit, load distribution is: %s',
                                        to_str(load_distribution)))
        c_hash.load_distribution = load_distribution

        init_ms_used.load_distribution = time.get_ms() - start_ts
    end

    c_hash.init_ms_used = init_ms_used
    ngx.log(ngx.INFO, 'init ms used: ' .. to_str(init_ms_used))

    c_hash.points = points
    c_hash.nr_point = nr_point

    return c_hash, nil, nil
end


function _M.new(servers, opts)
    if opts == nil then
        opts = {}
    end

    local c_hash = {
        servers = servers,
        server_names = tableutil.keys(servers),
        points = {},
        nr_point = 0,
        hash_func = opts.hash_func or ngx.crc32_long,
        debug = opts.debug == true,
    }

    local _, err, errmsg = _M.reinit(c_hash)
    if err ~= nil then
        return nil, err, errmsg
    end

    return setmetatable(c_hash, _mt), nil, nil
end


function _M.scan_for_extra_server(self, scan_start_index, scan_sub_index,
                                  nr_choose, chose_servers)
    local curr_index = scan_start_index
    local nr_scaned = 0
    local enough = false

    for n = 1, self.nr_point + 1 do
        if n ~= 1 then
            scan_sub_index = 1
        end
        local points_in_one_index = self.points[curr_index]

        for i = scan_sub_index, #points_in_one_index do
            local p = points_in_one_index[i]

            nr_scaned = nr_scaned + 1

            if not tableutil.has(chose_servers, p.server_name) then
                table.insert(chose_servers, p.server_name)
                if #chose_servers >= nr_choose then
                    enough = true
                    break
                end
            end
        end

        if enough then
            break
        end

        curr_index = curr_index + 1
        if curr_index >= self.nr_point then
            curr_index = 1
        end
    end

    if nr_scaned > 100 then
        ngx.log(ngx.WARN, string.format('scaned %d points to find %d servers',
                                        nr_scaned, nr_choose))
    end

    if not enough then
        return nil, 'FindServerError', string.format(
                'failed to find %d servers, scaned %d points',
                nr_choose, nr_scaned)
    end
end


function _M.choose_server(self, key, opts)
    if opts == nil then
        opts = {}
    end

    local nr_choose = opts.nr_choose or 1

    if nr_choose < 1 then
        return {}
    end

    if nr_choose > #self.server_names then
        return nil, 'ServerNotEnough', string.format(
                'server number: %d is less than %d',
                #self.server_names, nr_choose)
    end

    if nr_choose == #self.server_names then
        return tableutil.dup(self.server_names, true), nil, nil
    end

    local hash_code = self.hash_func(key)
    hash_code = (hash_code % NR_BUCKET) + 1

    local start_index = math.ceil(
            self.nr_point * hash_code / NR_BUCKET)

    local next_index = start_index + 1
    if next_index > self.nr_point then
        next_index = 1
    end

    local points = self.points[start_index]
    local point = points[#points]

    local scan_start_index = start_index
    local scan_sub_index = 1

    if hash_code > point.position then
        point = self.points[next_index][1]
        scan_start_index = next_index
        scan_sub_index = 2
    else
        for i = #points - 1, 1, -1 do
            if points[i].position >= hash_code then
                point = points[i]
                scan_sub_index = i + 1
            end
        end
    end

    local chose_servers = {point.server_name}

    if nr_choose == 1 then
        return chose_servers
    end

    local _, err, errmsg = self:scan_for_extra_server(
            scan_start_index, scan_sub_index, nr_choose, chose_servers)
    if err ~= nil then
        return nil, err, errmsg
    end

    return chose_servers
end


function _M.update_server(self, servers)
    self.servers = tableutil.dup(servers, true)

    self.server_names = tableutil.keys(self.servers)

    _M.reinit(self)

    local info = {
        load_distribution = self.load_distribution,
        consistent_rate = self.consistent_rate,
    }

    return info, nil, nil
end


function _M.delete_server(self, server_names)
    for _, server_name in ipairs(server_names) do
        self.servers[server_name] = nil
    end

    self.server_names = tableutil.keys(self.servers)

    _M.reinit(self)

    local info = {
        load_distribution = self.load_distribution,
        consistent_rate = self.consistent_rate,
    }

    return info, nil, nil
end


return _M
