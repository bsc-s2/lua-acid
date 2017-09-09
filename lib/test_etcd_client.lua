
local etcd_client = require('acid.etcd_client')

local function get_random_file()
    return 'test_file_' .. tostring(math.random(10000, 99999))
end


local function get_random_dir()
    return 'test_dir_' .. tostring(math.random(10000, 99999))
end


local function get_client()
    return etcd_client.new({{host='127.0.0.1', port=3344, ssl=true}},
                           {basic_auth_account='root:123456'})
end

local est = {}

function est.change_value_of_key(t)
    local client = get_client()

    local key = get_random_file()

    local result, err, errmsg = client:set(key, {value='1'})
    t:eq(nil, err, errmsg)
    t:eq('1', result.data.node.value)
    t:eq(nil, result.data.prevNode)

    local result, err, errmsg = client:set(key, {value='2'})
    t:eq(nil, err, errmsg)
    t:eq('1', result.data.prevNode.value)
    t:eq('2', result.data.node.value)
end

function est.delete_key(t)
    local client = get_client()

    local key = get_random_file()

    local result, err, errmsg = client:set(key, {value='foo'})
    t:eq(nil, err, errmsg)

    local result, err, errmsg = client:delete(key)
    t:eq(nil, err, errmsg)

    t:eq('foo', result.data.prevNode.value)
    t:eq(nil, result.data.node.value)

    local _, err, errmsg = client:get(key)
    t:neq(nil, err)
end

function est.ttl(t)
    local client = get_client()

    local key = get_random_file()

    local result, err, errmsg = client:set(key, {value='foo', ttl=1})
    t:eq(nil, err, errmsg)

    ngx.sleep(1.3)

    local _, err, errmsg = client:get(key)
    t:neq(nil, err)
end

function est.refresh_ttl(t)
    local client = get_client()

    local key = get_random_file()

    local result, err, errmsg = client:set(key, {value='foo', ttl=1})
    t:eq(nil, err, errmsg)

    local result, err, errmsg = client:set(
            key, {ttl=5, refresh=true, prevExist=true})
    local _, err, errmsg = client:get(key)

    ngx.sleep(1.3)
    local result, err, errmsg = client:get(key)
    t:eq('foo', result.data.node.value)
end


function est.waitIndex(t)
    local client = get_client()

    local key = get_random_file()

    local result, err, errmsg = client:set(key, {value='foo'})
    t:eq(nil, err, errmsg)
    local index = result.data.node.modifiedIndex

    local result, err, errmsg = client:get(key, {wait=true, waitIndex=index})
    t:eq(nil, err, errmsg)
    t:eq(index, result.data.node.modifiedIndex)
    t:eq('foo', result.data.node.value)
end


function est.create_in_order_keys(t)
    local client = get_client()

    local key = get_random_dir()

    for i = 1, 5 do
        local result, err, errmsg = client:set(
                key, {value=tostring(i)}, {method='POST'})
        t:eq(nil, err, errmsg)
    end

    local result, err, errmsg = client:get(key, {recursive=true})
    t:eq(nil, err, errmsg)
    t:eq(5, #result.data.node.nodes)
    t:eq('3', result.data.node.nodes[3].value)
end


function est.atomic_compare_and_swap(t)
    local client = get_client()

    local key = get_random_dir()

    local result, err, errmsg = client:set(key, {value='one'})
    t:eq(nil, err, errmsg)

    local result, err, errmsg = client:set(
            key, {prevExist=false, value='three'})
    test.dd(err)
    test.dd(errmsg)
    t:neq(nil, err)
    t:neq(nil, errmsg)

    local result, err, errmsg = client:set(
            key, {prevValue='two', value='three'})
    test.dd(err)
    test.dd(errmsg)
    t:neq(nil, err)
    t:neq(nil, errmsg)

    local result, err, errmsg = client:set(
            key, {prevValue='one', value='two'})
    t:eq(nil, err, errmsg)
    t:eq('two', result.data.node.value)
end


function est.atomic_compare_and_delete(t)
    local client = get_client()

    local key = get_random_dir()

    local result, err, errmsg = client:set(key, {value='one'})
    t:eq(nil, err, errmsg)

    local result, err, errmsg = client:delete(key, {prevValue='two'})
    test.dd(err)
    test.dd(errmsg)
    t:neq(nil, err)
    t:neq(nil, errmsg)

    local result, err, errmsg = client:delete(key, {prevIndex=1})
    test.dd(err)
    test.dd(errmsg)
    t:neq(nil, err)
    t:neq(nil, errmsg)

    local result, err, errmsg = client:delete(key, {prevValue='one'})
    t:eq(nil, err, errmsg)
    t:eq(nil, result.data.node.value)
end


function est.create_and_delete_directory(t)
    local client = get_client()

    local key = get_random_dir()

    local result, err, errmsg = client:set(key, {dir=true})
    t:eq(nil, err, errmsg)
    t:eq(true, result.data.node.dir)

    local _, err, errmsg = client:delete(key)
    t:neq(nil, err)
    t:neq(nil, errmsg)

    local _, err, errmsg = client:delete(key, {dir=true})
    t:eq(nil, err, errmsg)
end


function est.leader_statistics(t)
    local client = get_client()

    local result, err, errmsg = client:leader_statistics()
    t:eq(nil, err, errmsg)
    test.dd(result)
end

function est.self_statistics(t)
    local client = get_client()

    local result, err, errmsg = client:self_statistics()
    t:eq(nil, err, errmsg)
    test.dd(result)
end

function est.store_statistics(t)
    local client = get_client()

    local result, err, errmsg = client:store_statistics()
    t:eq(nil, err, errmsg)
    test.dd(result)
end

function test.version(t)
    local client, err, errmsg = get_client()
    t:eq(nil, err, errmsg)

    local result, err, errmsg = client:version()
    test.dd(result)
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)
end

function est.set(t)
    local client, err, errmsg = get_client()

    local result, err, errmsg = client:set('/foo', {value='bar'})
    test.dd(result)
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)
end

function est.get(t)
    local client, err, errmsg = get_client()
    t:eq(nil, err, errmsg)

    local result, err, errmsg = client:get('/foo')
    test.dd(result)
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)
end

function est.get_not_exist(t)
    local client = get_client()

    local key = get_random_file()
    local r, err, errmsg = client:get(key)
    test.dd(err)
    test.dd(errmsg)
    t:neq(nil, err, errmsg)
    t:neq(nil, errmsg)
    t:eq(nil, r)
end


function est.get_dir(t)
    local client = get_client()

    local dir_key = '/' .. get_random_dir()
    local file_key = dir_key .. '/' .. get_random_file()

    local _, err, errmsg = client:set(file_key)
    t:eq(nil, err, errmsg)

    local r, err, errmsg = client:get(dir_key)
    t:eq(nil, err, errmsg)

    t:eq('get', r.data.action)
    t:eq(true, r.data.node.dir)
    t:eq(dir_key, r.data.node.key)
    t:eq(nil, r.data.node.nodes[1].dir)
    t:eq(file_key, r.data.node.nodes[1].key)
    t:eq('', r.data.node.nodes[1].value)
end


function est.get_recursive(t)
    local client = get_client()

    local dir_key = '/' .. get_random_dir()
    local sub_dir_key = dir_key .. '/' .. get_random_dir()
    local file_key = sub_dir_key .. '/' .. get_random_file()

    client:set(file_key, {value='test_data'})

    local r, err, errmsg = client:get(dir_key)
    t:eq(nil, err, errmsg)
    t:eq(true, r.data.node.dir)
    t:eq(dir_key, r.data.node.key)
    t:eq(true, r.data.node.nodes[1].dir)
    t:eq(sub_dir_key, r.data.node.nodes[1].key)
    t:eq(nil, r.data.node.nodes[1].nodes)

    local r, err, errmsg = client:get(dir_key, {recursive=true})
    test.dd(r)
    t:eq(nil, err, errmsg)
    t:eq(file_key, r.data.node.nodes[1].nodes[1].key)
    t:eq('test_data', r.data.node.nodes[1].nodes[1].value)
end


function est.get_sorted(t)
    local client = get_client()

    local dir_key = '/' .. get_random_dir()

    local _, err, errmsg = client:set(dir_key .. '/' .. 'c')
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)

    local _, err, errmsg = client:set(dir_key .. '/' .. 'b')
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)

    local _, err, errmsg = client:set(dir_key .. '/' .. 'a')
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)

    local r, _, _ = client:get(dir_key, {sorted=true})
    t:eq(dir_key .. '/' .. 'a', r.data.node.nodes[1].key)
    t:eq(dir_key .. '/' .. 'b', r.data.node.nodes[2].key)
    t:eq(dir_key .. '/' .. 'c', r.data.node.nodes[3].key)
end


function est.wait_time_out(t)
    local client = get_client()

    local key = get_random_file()

    local result, err, errmsg = client:set(key)
    t:eq(nil, err, errmsg)

    local wait_index = result.data.node.modifiedIndex + 1

    local _, err, errmsg = client:get(
            key, {wait=true, waitIndex=wait_index}, {timeout=1})
    test.dd(err)
    test.dd(errmsg)
    t:neq(nil, err)
    t:neq(nil, errmsg)
end


function est.watch(t)
    local client = get_client()

    local key = get_random_file()

    local result, err, errmsg = client:set(key, {value='foo'})
    t:eq(nil, err, errmsg)
    local index = tonumber(result.headers['x-etcd-index'])

    local result, err, errmsg = client:watch(key, {waitIndex=index})
    t:eq(nil, err, errmsg)
    t:eq('foo', result.data.node.value)

    local _, err, errmsg = client:watch(key, nil, {timeout=2})
    test.dd(err)
    test.dd(errmsg)
    t:neq(nil, err)
    t:neq(nil, errmsg)
end
