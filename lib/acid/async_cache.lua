local acid_json = require('acid.json')
local resty_lock = require('resty.lock')

local _M = {}

local mt = { __index = _M }

local RUNNING_TIMERS = {}


function _M.new(shared_dict_name, lock_dict_name, service_name,
                update_handler, opts)
    opts = opts or {}
    local shared_dict = ngx.shared[shared_dict_name]
    if shared_dict == nil then
        return nil, 'InvalidArgument', string.format(
                'the shared dict: %s is not exists', shared_dict_name)
    end

    local lock_shared_dict = ngx.shared[lock_dict_name]
    if lock_shared_dict == nil then
        return nil, 'InvalidArgument', string.format(
                'the shared dict: %s is not exists', lock_dict_name)
    end

    if type(service_name) ~= 'string' then
        return nil, 'InvalidArgument', string.format(
                'the service_name argument: %s, is not a string',
                tostring(service_name))
    end

    if type(update_handler) ~= 'table' then
        return nil, 'InvalidArgument', string.format(
                'the update_handler argument is not a table, is type: %s',
                type(update_handler))
    end

    if type(update_handler.get_latest) ~= 'function' then
        return nil, 'InvalidArgument',
                'the update handler must implement function: get_latest'
    end

    return setmetatable({
        shared_dict_name=shared_dict_name,
        shared_dict=shared_dict,
        lock_dict_name=lock_dict_name,
        service_name=service_name,
        update_handler=update_handler,
        cache_expire_time=tonumber(opts.cache_expire_time) or 60 * 20,
        max_stale_time=tonumber(opts.max_stale_time) or 60 * 2,
        async_fetch=opts.async_fetch == true,
        }, mt), nil, nil
end


function _M.update_value(self, key, old_value)
    local storage_key = self.service_name .. '/' .. key
    local storage_vi, err, errmsg = self.update_handler:get_latest(
            storage_key, old_value)
    if err ~= nil then
        return nil, 'GetLatestError', string.format(
                'failed to get storage value info for key: %s, use function '..
                'passed in, %s, %s', storage_key, err, errmsg)
    end

    if type(storage_vi) ~= 'table' then
        return nil, 'GetLatestError', string.format(
                'get invalid storage value info: %s, for key: %s, '..
                'is not a table, is type: %s',
                tostring(storage_vi), storage_key, type(storage_vi))
    end

    local ts_now = ngx.time()
    local cache_expire_time =
            storage_vi.cache_expire_time or self.cache_expire_time
    local value_info = {
        update_ts=ts_now,
        cache_expire_time = cache_expire_time,
        value = storage_vi.value
    }

    local value_info_json_string, err = acid_json.enc(value_info)
    if err ~= nil then
        return  nil, 'JsonEncodeError', string.format(
                'failed to json encode vaule info: %s', err)
    end

    -- prevent the cached item from being freed
    local expire_time = math.max(cache_expire_time * 2, 60 * 60 * 24 * 7)

    local shared_dict_key = storage_key

    ngx.log(ngx.INFO, string.format(
            'async_cache: shared dict update: %s/%s to %s',
            self.shared_dict_name, shared_dict_key,
            string.sub(value_info_json_string, 1, 100) .. '...'))

    local success, err, forcible = self.shared_dict:set(shared_dict_key,
                                                        value_info_json_string,
                                                        expire_time)
    if forcible == true then
        ngx.log(ngx.ERR, string.format(
                'async_cache: shared dict: %s, is lack of memory',
                self.shared_dict_name))
    end
    if success == false then
        ngx.log(ngx.ERR, string.format(
                'async_cache: failed to set value info of key: %s, '..
                'to shared dict: %s, %s',
                shared_dict_key, self.shared_dict_name, err))
    end

    return true, nil, nil
end


function _M.update_value_with_lock(self, key, old_value)
    local lock, err = resty_lock:new(self.lock_dict_name,
                                     {exptime=10, timeout=10})
    if err ~= nil then
        return nil, 'NewLockError', string.format(
                'failed to new lock use shared dict: %s, %s',
                self.lock_dict_name, err)
    end

    local lock_key = self.service_name .. '/' .. key
    local _, err = lock:lock(lock_key)
    if err ~= nil then
        return nil, 'LockError', string.format(
                'failed to lock key: %s, %s', lock_key, err)
    end

    local cache_value, err, errmsg = self:get_from_cache(key)
    if err ~= nil then
        local _, _err = lock:unlock()
        if _err ~= nil then
            ngx.log(ngx.ERR, string.format(
                    'failed to unlock key: %s, %s', lock_key, _err))
        end
        return nil, err, errmsg
    end

    if cache_value.need_update ~= true then
        local _, _err = lock:unlock()
        if _err ~= nil then
            ngx.log(ngx.ERR, string.format(
                    'failed to unlock key: %s, %s', lock_key, _err))
        end

        return cache_value, nil, nil
    end

    local _, err, errmsg = self:update_value(key, old_value)

    local _, _err = lock:unlock()
    if _err ~= nil then
        ngx.log(ngx.ERR, string.format(
                'failed to unlock key: %s, %s', lock_key, _err))
    end

    if err ~= nil then
        return nil, err, errmsg
    end

    return self:get_from_cache(key)
end


function _M.update_value_worker(prematrue, self, key, old_value)
    local timer_ident = self.service_name .. '/' .. key

    if prematrue then
        ngx.log(ngx.INFO,
                'async_cache: timer work not excuted, it is prematrue')
        RUNNING_TIMERS[timer_ident] = nil
        return false, nil, nil
    end

    local ok, value_info_or_error, err, errmsg = pcall(self.update_value_with_lock,
                                                       self, key, old_value)
    if not ok then
        ngx.log(ngx.ERR, string.format(
                'async_cache: got error when update value in timer '..
                'for key: %s, %s', key, value_info_or_error))
    end

    if err ~= nil then
        ngx.log(ngx.ERR, string.format(
                'async_cache: failed to update value in timer '..
                'for key: %s, %s, %s', key, err, errmsg))
    end

    RUNNING_TIMERS[timer_ident] = nil

    return ok and err == nil, nil, nil
end


function _M.update_value_async(self, key, old_value)
    local timer_ident = self.service_name .. '/' .. key

    if RUNNING_TIMERS[timer_ident] == true then
        ngx.log(ngx.INFO, string.format(
                'async_cache: timer: %s is running, '..
                'do not need to create new timer', timer_ident))
        return true, nil, nil
    end

    RUNNING_TIMERS[timer_ident] = true

    local ok, err = ngx.timer.at(0, self.update_value_worker, self, key,
                                 old_value)
    if not ok then
        RUNNING_TIMERS[timer_ident] = nil
        return nil, 'CreateTimerError', string.format(
                'failed to create timer: %s', err)
    end

    return true, nil, nil
end


function _M.get_from_cache(self, key)
    local cache_value = {}

    local shared_dict_key = self.service_name .. '/' .. key

    local value_info_json_string, err, _ =
            self.shared_dict:get_stale(shared_dict_key)
    if err ~= nil then
        return nil, 'SharedDictGetStaleError', string.format(
                'failed to get value of: %s, from shared dict: %s, %s',
                shared_dict_key, self.shared_dict_name, err)
    end

    if value_info_json_string == nil then
        cache_value.status = 'missing'
        cache_value.need_update = true
        return cache_value, nil, nil
    end

    local value_info, err = acid_json.dec(value_info_json_string)
    if err ~= nil then
        return nil, 'JsonDecodeError', string.format(
                'failed to json decode value info: %s, %s',
                string.sub(value_info_json_string, 1, 100) .. '...', err)
    end

    cache_value.status = 'hit'
    cache_value.value = value_info.value

    local ts_now = ngx.time()
    local stale_time = ts_now - (value_info.update_ts +
                                 value_info.cache_expire_time)

    if stale_time >= 0 then
        cache_value.status = 'stale'
        cache_value.need_update = true

        if stale_time > self.max_stale_time then
            cache_value.status = 'too_stale'
        end
    end

    return cache_value, nil, nil
end


function _M.get(self, key)
    local cache_value, err, errmsg = self:get_from_cache(key)
    if err ~= nil then
        return nil, err, errmsg
    end

    if not cache_value.need_update then
        return cache_value, nil, nil
    end

    ngx.log(ngx.INFO, string.format(
            'async_cache: need to update key: %s, for status is: %s',
            key, cache_value.status))

    if (cache_value.status == 'missing' or cache_value.status == 'too_stale') and self.async_fetch ~= true then
        local value_info, err, errmsg = self:update_value_with_lock(key)
        if err ~= nil then
            return nil, err, errmsg
        end
        return value_info, nil, nil
    end

    local _, err, errmsg = self:update_value_async(key, cache_value.value)
    if err ~= nil then
        ngx.log(ngx.ERR, string.format(
                'async_cache: failed to add async update timer '..
                'for key: %s, %s, %s', key, err, errmsg))
    end

    return cache_value, nil, nil
end


return _M
