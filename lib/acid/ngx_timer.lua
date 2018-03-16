local _M = {}


local function callback(premature, opts, func, ...)
    if opts.allow_premature == false and premature then
        ngx.log(ngx.INFO, 'Premature expiration happens, func will not run')
        return
    end

    local ok, err = pcall(func, ...)
    if not ok then
        ngx.log(ngx.ERR, 'failed to run func in timer: ' .. err)
    end

    if opts.loop_interval == nil then
        return
    end

    local ok, err = ngx.timer.at(opts.loop_interval, callback, opts, func, ...)
    if not ok then
        ngx.log(ngx.ERR, 'failed to create timer in callback: ' .. err)
    end
end


function _M.one_work(delay, func, ...)
    local opts = {
        allow_premature = true,
    }
    local ok, err = ngx.timer.at(delay, callback, opts, func, ...)
    if not ok then
        return nil, 'CreateTimerError', 'failed to create timer: ' .. err
    end

    return true, nil, nil
end


function _M.loop_work(interval, func, ...)
    local opts = {
        loop_interval = interval,
        allow_premature = true,
    }
    local ok, err = ngx.timer.at(interval, callback, opts, func, ...)
    if not ok then
        return nil, 'CreateTimerError', 'failed to create timer: ' .. err
    end

    return true, nil, nil
end

return _M
