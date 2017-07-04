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

local function exec_callbacks()
    for cb_name, cb in pairs(ngx.ctx.callback_functions or {}) do
        if type(cb.func) == 'function' then
            cb.func(unpack(cb.args or {}))
        end
    end
end

function _M.add_callback(func, ...)
    local phase = ngx.get_phase()
    if allowed_phase[phase] == nil then
        return nil, 'InstallOnAbortError', phase .. ' not allowed'
    end
    local ctx = ngx.ctx

    local ok, err = ngx.on_abort( exec_callbacks )
    if err then
        if err ~= 'duplicate call' then
            ngx.log( ngx.ERR, tostring( err ), ' while install on_abort' )
            return nil, 'InstallOnAbortError', err
        end
    end

    if ctx.callback_functions == nil then
        ctx.callback_functions = {}
    end

    local cb = {func=func, args={...}}

    ctx.callback_functions[cb] = cb

    return cb
end

function _M.remove_callback(cb)
    local ctx = ngx.ctx

    if cb == nil or ctx.callback_functions == nil then
        return
    end

    ctx.callback_functions[cb] = nil
end

function _M.install_running()
    local running = true

    local function is_running()
        return running
    end

    local function abort_cb()
        running = false
    end

    local rst, err, errmes = _M.add_callback(abort_cb)

    return is_running, err, errmes
end


return _M
