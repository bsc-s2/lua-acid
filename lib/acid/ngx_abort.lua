local tableutil = require('acid.tableutil')


local _M = {}

--- NOTE:
-- 1.Every request, subrequests and sub location, has its own copy of the ngx.ctx.
--   so, the callback will be discarded, if request subrequest or sub location.
-- 2.Due to the limitation of ngx.on_abort, only allow these phases: rewrite, access, content

local allowed_phase = {
    rewrite = true,
    access  = true,
    content = true,
}


local function _comp_callback_index(a, b)
    if type(a) == 'number' and type(b) == 'number' then
        return a < b
    end

    if b == 'last' then
        return true
    end

    if a == 'last' then
        return false
    end

    return tostring(a) < tostring(b)
end


local function exec_callbacks()
    local callbacks = ngx.ctx.callbacks
    if callbacks == nil then
        return
    end

    local indexes = tableutil.keys(callbacks)
    table.sort(indexes, _comp_callback_index)

    for _, index in ipairs(indexes) do
        local cb_array = callbacks[index]

        for _, cb in ipairs(cb_array) do
            local ok, rst = pcall(cb.func, unpack(cb.args))
            if not ok then
                ngx.log(ngx.ERR, 'callback crash: ', rst)
            end
        end
    end

    return
end


local function register()
    local phase = ngx.get_phase()
    if allowed_phase[phase] == nil then
        return nil, 'InstallOnAbortError', phase .. ' not allowed'
    end

    local ok, err = ngx.on_abort(exec_callbacks)
    if not ok then
        if err ~= 'duplicate call' then
            ngx.log(ngx.ERR, tostring(err), ' while install on_abort')
            return nil, 'InstallOnAbortError', err
        end
    end

    if ngx.ctx.callbacks == nil then
        ngx.ctx.callbacks = {}
    end

    return true, nil, nil
end


function _M.add_callback_with_opts(func, opts, ...)
    if type(func) ~= 'function' then
        return nil, 'InvalidCallback', string.format(
                'argument func: %s is not function, is %s',
                tostring(func), type(func))
    end

    local _, err, errmsg = register()
    if err ~= nil then
        return nil, err, errmsg
    end

    local callbacks = ngx.ctx.callbacks
    local cb = {func=func, args={...}}

    opts = opts or {}

    local index = opts.position or 1

    if callbacks[index] == nil then
        callbacks[index] = {}
    end

    table.insert(callbacks[index], cb)
    return cb, nil, nil
end


function _M.add_callback(func, ...)
    return _M.add_callback_with_opts(func, nil, ...)
end


function _M.remove_callback(cb)
    local callbacks = ngx.ctx.callbacks

    if callbacks == nil then
        return
    end

    for _, cb_array in pairs(callbacks) do
        for i, _cb in ipairs(cb_array) do
            if _cb == cb then
                table.remove(cb_array, i)
                return
            end
        end
    end

    return
end


function _M.install_running()
    local running = true

    local function is_running()
        return running
    end

    local function abort_cb()
        running = false
    end

    local _, err, errmes = _M.add_callback(abort_cb)

    return is_running, err, errmes
end


return _M
