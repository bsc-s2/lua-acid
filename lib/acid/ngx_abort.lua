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
    local callback_functions = ngx.ctx.callback_functions or {}
    local advance = callback_functions.advance or {}
    local postpone = callback_functions.postpone or {}

    for cb_name, cb in pairs(advance) do
        if type(cb.func) == 'function' then
            cb.func(unpack(cb.args or {}))
        end
    end

    for cb_name, cb in pairs(postpone) do
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
        ctx.callback_functions = {
            advance = {},
            postpone = {},
        }
    end

    local cb = {func=func, args={...}}

    local opts = ...
    if type(opts) == 'table' and opts.postpone == true then
        if next(ctx.callback_functions.postpone) ~= nil then
            return nil, 'InstallOnAbortError',
                    'only one postpone callback is allowed'
        end
        ctx.callback_functions.postpone[cb] = cb
    else
        ctx.callback_functions.advance[cb] = cb
    end

    return cb
end

function _M.remove_callback(cb)
    local ctx = ngx.ctx

    if cb == nil or ctx.callback_functions == nil then
        return
    end

    if ctx.callback_functions.advance ~= nil then
        ctx.callback_functions.advance[cb] = nil
    end

    if ctx.callback_functions.postpone ~= nil then
        ctx.callback_functions.postpone[cb] = nil
    end
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
