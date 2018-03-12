local ngx_timer = require('ngx_timer')

local _M = {}

_M.conf = nil
_M.get_conf_callback_func = nil
_M.locked = 0


local function get_conf_safe(opts)
    if opts == nil then
        opts = {}
    end

    if opts.only_init == true then
        if _M.conf ~= nil then
            return _M.conf, nil, nil
        end
    end

    local curr_version = (_M.conf or {}).version

    ngx.log(ngx.INFO, string.format(
            'conf ##: worker %d start to get conf with current version: %s',
            ngx.worker.id(), tostring(curr_version)))

    local ok, err_or_conf, err, errmsg = pcall(_M.get_conf_callback_func,
                                               _M.conf)
    if not ok then
        ngx.log(ngx.ERR, string.format('conf ##: failed to run callback get_conf: %s',
                                       err_or_conf))
        return nil, 'RunCallbackError', 'failed to run callback function'
    end

    if err ~= nil then
        ngx.log(ngx.ERR, string.format('conf ##: failed to get conf: %s, %s',
                                       err, errmsg))
        return nil, 'CallbackReturnError', 'callback function return error'
    end

    _M.conf = err_or_conf

    ngx.log(ngx.INFO, string.format(
            'conf ##: worker %d curr conf version: %s',
            ngx.worker.id(), tostring(_M.conf.version)))

    return _M.conf, nil, nil
end


function _M.init_conf_update(get_conf)
    _M.get_conf_callback_func = get_conf

    local _, err, errmsg = ngx_timer.loop_work(0.5, get_conf_safe)
    if err ~= nil then
        ngx.log(ngx.ERR, 'conf ##: failed to init ngx timer')
        return nil, err, errmsg
    end

    return true, nil, nil
end


function _M.init_conf()
    for _ = 1, 100 do
        if _M.locked == 1 then
            ngx.sleep(0.05)
        else
            break
        end
    end

    if _M.locked == 0 then
        _M.locked = 1
    else
        ngx.log(ngx.ERR, 'conf ##: failed to get lock in 5 seconds')
        return nil, 'GetLockError', 'failed to get lock'
    end

    if _M.conf ~= nil then
        _M.locked = 0
        return _M.conf, nil, nil
    end

    ngx.log(ngx.INFO, 'conf ##: init conf with lock')
    local _, err, errmsg = get_conf_safe({only_init = true})
    if err ~= nil then
        _M.locked = 0
        return nil, err, errmsg
    end

    _M.locked = 0

    return _M.conf, nil, nil
end


return _M
