local async_cache = require("acid.async_cache")


local str_50m = string.rep('0', 1024 * 1024 * 50)


local function get_random_string()
    return tostring(math.random(10000, 99999))
end


function test.t01_missing_sync_fetch(t)
    local update_handler = {
        get_latest = function(_, _) ngx.sleep(1.1) return {value='foo'} end,
    }
    local cache = async_cache.new('test_shared', 'shared_dict_lock',
                                  'test_service', update_handler, {})

    local cache_key = get_random_string()

    local t1_s = ngx.now()
    local cache_value, err, errmsg = cache:get(cache_key)
    local t1_e = ngx.now()

    t:eq(nil, err, errmsg)
    t:eq('foo', cache_value.value, 'value is not foo')
    t:eq('hit', cache_value.status, 'status is not hit')
    t:eq(true, t1_e - t1_s > 1.0, string.format('t1_s: %f, t1_e: %f',
                                                t1_s, t1_e))

    local t2_s = ngx.now()
    local cache_value, _, _ = cache:get(cache_key)
    local t2_e = ngx.now()
    t:eq('foo', cache_value.value, 'value is not foo')
    t:eq(true, t2_e - t2_s < 0.1, string.format('t2_s: %f, t2_e: %f',
                                                t2_s, t2_e))
end


function test.t02_missing_async_fetch(t)
    local update_handler = {
        get_latest = function(_, _) ngx.sleep(0.5) return {value='foo'} end,
    }
    local cache = async_cache.new('test_shared', 'shared_dict_lock',
                                  'test_service', update_handler,
                                  {async_fetch=true})

    local cache_key = get_random_string()

    local t1_s = ngx.now()
    local cache_value, err, errmsg = cache:get(cache_key)
    local t1_e = ngx.now()

    t:eq(nil, err, errmsg)
    t:eq(nil, cache_value.value, 'value is not nil')
    t:eq('missing', cache_value.status, 'status is not missing')
    t:eq(true, t1_e - t1_s < 0.1, string.format('t1_s: %f, t1_e: %f',
                                                t1_s, t1_e))

    ngx.sleep(0.4)

    local t1_s = ngx.now()
    local cache_value, err, errmsg = cache:get(cache_key)
    local t1_e = ngx.now()

    t:eq(nil, err, errmsg)
    t:eq(nil, cache_value.value, 'value is not nil')
    t:eq('missing', cache_value.status, 'status is not missing')
    t:eq(true, t1_e - t1_s < 0.1, string.format('t1_s: %f, t1_e: %f',
                                                t1_s, t1_e))

    ngx.sleep(0.2)

    local t2_s = ngx.now()
    local cache_value, _, _ = cache:get(cache_key)
    local t2_e = ngx.now()
    t:eq('foo', cache_value.value, 'value is not foo')
    t:eq('hit', cache_value.status, 'status is not hit')
    t:eq(true, t2_e - t2_s < 0.1, string.format('t2_s: %f, t2_e: %f',
                                                t2_s, t2_e))
end


function test.t03_expire_time_sync(t)
    local update_handler = {
        get_latest = function(_, _) return {value='foo'} end,
    }
    local cache = async_cache.new('test_shared', 'shared_dict_lock',
                                  'test_service', update_handler,
                                  {cache_expire_time=1, max_stale_time=1})

    local cache_key = get_random_string()

    local cache_value, _, _ = cache:get(cache_key)
    t:eq('foo', cache_value.value, 'value is not foo')
    t:eq('hit', cache_value.status, 'status is not hit')

    ngx.sleep(1.2)
    local cache_value, _, _ = cache:get(cache_key)
    t:eq('foo', cache_value.value, 'value is not foo')
    t:eq('stale', cache_value.status, 'status is not stale')

    ngx.sleep(3.2)
    local cache_value, _, _ = cache:get(cache_key)
    t:eq('foo', cache_value.value, 'value is not foo')
    t:eq('hit', cache_value.status, 'status is not hit')
end

function test.t03_expire_time_async(t)
    local update_handler = {
        get_latest = function(_, _) return {value='foo'} end,
    }
    local cache = async_cache.new('test_shared', 'shared_dict_lock',
                                  'test_service', update_handler,
                                  {cache_expire_time=1, max_stale_time=1, async_fetch=true})

    local cache_key = get_random_string()

    local cache_value, _, _ = cache:get(cache_key)
    t:eq(nil, cache_value.value, 'value is not nil')
    t:eq('missing', cache_value.status, 'status is not missing')

    ngx.sleep(1.2)
    local cache_value, _, _ = cache:get(cache_key)
    t:eq('foo', cache_value.value, 'value is not foo')
    t:eq('stale', cache_value.status, 'status is not stale')

    ngx.sleep(3.2)
    local cache_value, _, _ = cache:get(cache_key)
    t:eq('foo', cache_value.value, 'value is not foo')
    t:eq('too_stale', cache_value.status, 'status is not too_stale')
end


function test.t03_set_expire_time(t)
    local update_handler = {
        get_latest = function(_, _) return {value='foo', cache_expire_time=1} end,
    }
    local cache = async_cache.new('test_shared', 'shared_dict_lock',
                                  'test_service', update_handler,
                                  {cache_expire_time=10, max_stale_time=3})

    local cache_key = get_random_string()

    local cache_value, _, _ = cache:get(cache_key)
    t:eq('foo', cache_value.value, 'value is not foo')
    t:eq('hit', cache_value.status, 'status is not hit')

    ngx.sleep(1.2)
    local cache_value, _, _ = cache:get(cache_key)
    t:eq('foo', cache_value.value, 'value is not foo')
    t:eq('stale', cache_value.status, 'status is not stale')
end


function test.t04_no_memory(t)
    local update_handler = {
        get_latest = function(_, _) return {value=str_50m} end,
    }
    local cache = async_cache.new('test_shared', 'shared_dict_lock',
                                  'test_service', update_handler, {})

    local cache_key = get_random_string()
    local cache_value, _, _ = cache:get(cache_key)
    t:eq(nil, cache_value.value, 'set shared dict failed, should get nil')
end


function test.t05_get_latest_error(t)
    local update_handler = {
        get_latest = function(_, _) return nil, 'test_error', 'test_error_message' end,
    }
    local cache = async_cache.new('test_shared', 'shared_dict_lock',
                                  'test_service', update_handler)
    local cache_key = get_random_string()
    local cache_value, err, errmsg = cache:get(cache_key)
    t:eq(nil, cache_value, 'failed to get latest, should return nil')
    t:neq(nil, err)
    t:neq(nil, errmsg)
end


function test.t06_invalid_get_latest_return(t)
    local update_handler = {
        get_latest = function(_, _) return 'foo' end,
    }
    local cache = async_cache.new('test_shared', 'shared_dict_lock',
                                  'test_service', update_handler)
    local cache_key = get_random_string()
    local cache_value, err, errmsg = cache:get(cache_key)
    t:eq(nil, cache_value, 'invalid get_latest return, should return nil')
    t:neq(nil, err)
    t:neq(nil, errmsg)
end


function test.t07_invalid_update_handler(t)
    local update_handler = {
        get_latest = 'foo',
    }
    local cache, err, errmsg = async_cache.new(
            'test_shared', 'shared_dict_lock', 'test_service', update_handler)
    t:eq(nil, cache, 'get_latest is not a function, should return nil')
    t:neq(nil, err)
    t:neq(nil, errmsg)
end


function test.t08_invalid_shared_dict(t)
    local update_handler = {
        get_latest = function(_, _) return {value='foo'} end,
    }
    local cache, err, errmsg = async_cache.new(
            'not_exist_shared', 'shared_dict_lock', 'test_service', update_handler)
    t:eq(nil, cache, 'invalid shared dict, should return nil')
    t:neq(nil, err)
    t:neq(nil, errmsg)
end


function test.t09_invalid_lock_shared_dict(t)
    local update_handler = {
        get_latest = function(_, _) return {value='foo'} end,
    }
    local cache, err, errmsg = async_cache.new(
            'test_shared', 'not_exist_shared', 'test_service', update_handler)
    t:eq(nil, cache, 'invalid lock shared dict, should return nil')
    t:neq(nil, err)
    t:neq(nil, errmsg)
end


function test.t10_invalid_service_name(t)
    local update_handler = {
        get_latest = function(_, _) return {value='foo'} end,
    }
    local cache, err, errmsg = async_cache.new(
            'test_shared', 'shared_dict_lock', 123, update_handler)
    t:eq(nil, cache, 'invalid service name, should return nil')
    t:neq(nil, err)
    t:neq(nil, errmsg)
end


function test.t11_value_not_set(t)
    local update_handler = {
        get_latest = function(_, _) ngx.sleep(1.1) return {value=nil} end,
    }
    local cache = async_cache.new('test_shared', 'shared_dict_lock',
                                  'test_service', update_handler, {})

    local cache_key = get_random_string()

    local t1_s = ngx.now()
    local cache_value, err, errmsg = cache:get(cache_key)
    local t1_e = ngx.now()

    t:eq(nil, err, errmsg)
    t:eq(nil, cache_value.value, 'value is not nil')
    t:eq('hit', cache_value.status, 'status is not hit')
    t:eq(true, t1_e - t1_s > 1.0, string.format('t1_s: %f, t1_e: %f',
                                                t1_s, t1_e))

    local t2_s = ngx.now()
    local cache_value, _, _ = cache:get(cache_key)
    local t2_e = ngx.now()
    t:eq(nil, cache_value.value, 'value is not nil')
    t:eq('hit', cache_value.status, 'status is not hit')
    t:eq(true, t2_e - t2_s < 0.1, string.format('t2_s: %f, t2_e: %f',
                                                t2_s, t2_e))
end
