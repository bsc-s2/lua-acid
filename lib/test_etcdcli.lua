local etcdcli = require('acid.etcdcli')


local function get_random_file()
    return 'test_file_' .. tostring(math.random(10000, 99999))
end


local function get_random_dir()
    return 'test_dir_' .. tostring(math.random(10000, 99999))
end


local function get_client()
    return etcdcli:new('127.0.0.1', {port=3344})
end


function test.version(t)
    local cli = get_client()

    local version, err, errmsg = cli:version()
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)
    t:eq('string', type(version.etcdserver))
    t:eq('string', type(version.etcdcluster))
end


function test.read_not_found(t)
    local cli = get_client()

    local key = get_random_file()
    local r, err, errmsg = cli:read(key)
    t:neq(nil, err, errmsg)
    t:neq(nil, errmsg)
    t:eq(nil, r)
end


function test.read_dir(t)
    local cli = get_client()

    local dir_key = '/' .. get_random_dir()
    local file_key = dir_key .. '/' .. get_random_file()

    local _, err, errmsg = cli:write(file_key)
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)

    local r, err, errmsg = cli:read(dir_key)
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)

    t:eq(200, r.status)
    t:eq('get', r.data.action)
    t:eq(true, r.data.node.dir)
    t:eq(dir_key, r.data.node.key)
    t:eq(nil, r.data.node.nodes[1].dir)
    t:eq(file_key, r.data.node.nodes[1].key)
    t:eq('', r.data.node.nodes[1].value)
end


function test.read_file(t)
    local cli = get_client()

    local dir_key = '/' .. get_random_dir()
    local file_key = dir_key .. '/' .. get_random_file()

    local _, err, errmsg = cli:write(file_key, {value='test_data'})
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)

    local r, err, errmsg = cli:read(file_key)
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)
    t:eq(200, r.status)
    t:eq('get', r.data.action)
    t:eq(nil, r.data.node.dir)
    t:eq(file_key, r.data.node.key)
    t:eq('test_data', r.data.node.value)
end


function test.read_recursive(t)
    local cli = get_client()

    local dir_key = '/' .. get_random_dir()
    local sub_dir_key = dir_key .. '/' .. get_random_dir()
    local file_key = sub_dir_key .. '/' .. get_random_file()

    local _, err, errmsg = cli:write(file_key, {value='test_data'})
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)

    local r, _, _ = cli:read(dir_key)
    t:eq(true, r.data.node.dir)
    t:eq(dir_key, r.data.node.key)
    t:eq(true, r.data.node.nodes[1].dir)
    t:eq(sub_dir_key, r.data.node.nodes[1].key)
    t:eq(nil, r.data.node.nodes[1].nodes)

    local r, _, _ = cli:read(dir_key, {recursive=true})
    t:eq(file_key, r.data.node.nodes[1].nodes[1].key)
    t:eq('test_data', r.data.node.nodes[1].nodes[1].value)
end


function test.read_sorted(t)
    local cli = get_client()

    local dir_key = '/' .. get_random_dir()

    local _, err, errmsg = cli:write(dir_key .. '/' .. 'c')
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)

    local _, err, errmsg = cli:write(dir_key .. '/' .. 'b')
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)

    local _, err, errmsg = cli:write(dir_key .. '/' .. 'a')
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)

    local r, _, _ = cli:read(dir_key, {sorted=true})
    t:eq(dir_key .. '/' .. 'a', r.data.node.nodes[1].key)
    t:eq(dir_key .. '/' .. 'b', r.data.node.nodes[2].key)
    t:eq(dir_key .. '/' .. 'c', r.data.node.nodes[3].key)
end


function test.watch(t)
    local cli = get_client()

    local file_key = '/' .. get_random_file()
    local r, err, errmsg = cli:write(file_key, {value='test_data'})
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)

    local index = r.headers['x-etcd-index']

    local r, err, errmsg = cli:watch(file_key, {timeout=1, waitIndex=1})
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)
    t:eq(index, r.headers['x-etcd-index'])
    t:eq(file_key, r.data.node.key)
    t:eq('test_data', r.data.node.value)
end


function test.delete(t)
    local cli = get_client()

    local file_key = '/' .. get_random_file()
    local _, err, errmsg = cli:write(file_key, {value='test_data'})
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)

    local _, err, errmsg = cli:read(file_key)
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)

    local _, err, errmsg = cli:delete(file_key)
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)

    local _, err, errmsg = cli:read(file_key)
    t:neq(nil, err)
    t:neq(nil, errmsg)
end


function test.write_ttl(t)
    local cli = get_client()

    local file_key = '/' .. get_random_file()
    local _, err, errmsg = cli:write(file_key, {ttl=1, value='test_data'})
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)

    local r, err, errmsg = cli:read(file_key)
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)
    t:eq('test_data', r.data.node.value)

    ngx.sleep(2)
    local _, err, errmsg = cli:read(file_key)
    t:neq(nil, err)
    t:neq(nil, errmsg)
end
