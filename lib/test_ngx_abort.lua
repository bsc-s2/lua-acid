local ngx_abort = require('acid.ngx_abort')


local function callback_func()
end


function test.basic(t)
    ngx.ctx.callbacks = nil

    local cb_1, err, errmsg = ngx_abort.add_callback(callback_func)
    t:eq(nil, err)
    t:eq(nil, errmsg)
    t:eq(cb_1, ngx.ctx.callbacks[1][1])

    local cb_2, err, errmsg = ngx_abort.add_callback(callback_func)
    t:eq(nil, err)
    t:eq(nil, errmsg)
    t:eq(cb_1, ngx.ctx.callbacks[1][1])
    t:eq(cb_2, ngx.ctx.callbacks[1][2])

    local _, err, errmsg = ngx_abort.remove_callback(cb_1)
    t:eq(nil, err)
    t:eq(nil, errmsg)
    t:eq(cb_2, ngx.ctx.callbacks[1][1])
    t:eq(nil, ngx.ctx.callbacks[1][2])

    local _, err, errmsg = ngx_abort.remove_callback(cb_1)
    t:eq(nil, err)
    t:eq(nil, errmsg)
    t:eq(cb_2, ngx.ctx.callbacks[1][1])
    t:eq(nil, ngx.ctx.callbacks[1][2])

    local _, err, errmsg = ngx_abort.remove_callback(cb_2)
    t:eq(nil, err)
    t:eq(nil, errmsg)
    t:eq(nil, ngx.ctx.callbacks[1][1])
    t:eq(nil, ngx.ctx.callbacks[1][2])
end


function test.last(t)
    ngx.ctx.callbacks = nil

    local cb, err, errmsg = ngx_abort.add_callback_with_opts(
            callback_func, {position='last'})
    t:eq(nil, err)
    t:eq(nil, errmsg)
    t:eq(cb, ngx.ctx.callbacks.last[1])
end


function test.opts_position(t)
    ngx.ctx.callbacks = nil

    local cb_1, err, errmsg = ngx_abort.add_callback_with_opts(
            callback_func, {position=100})
    t:eq(nil, err)
    t:eq(nil, errmsg)
    t:eq(cb_1, ngx.ctx.callbacks[100][1])

    local cb_2, err, errmsg = ngx_abort.add_callback_with_opts(
            callback_func, {position=100})
    t:eq(nil, err)
    t:eq(nil, errmsg)
    t:eq(cb_1, ngx.ctx.callbacks[100][1])
    t:eq(cb_2, ngx.ctx.callbacks[100][2])

    local cb_3, err, errmsg = ngx_abort.add_callback(callback_func)
    t:eq(nil, err)
    t:eq(nil, errmsg)
    t:eq(cb_1, ngx.ctx.callbacks[100][1])
    t:eq(cb_2, ngx.ctx.callbacks[100][2])
    t:eq(cb_3, ngx.ctx.callbacks[1][1])

    local cb_4, err, errmsg = ngx_abort.add_callback_with_opts(
            callback_func, {position=101})
    t:eq(nil, err)
    t:eq(nil, errmsg)
    t:eq(cb_1, ngx.ctx.callbacks[100][1])
    t:eq(cb_2, ngx.ctx.callbacks[100][2])
    t:eq(cb_3, ngx.ctx.callbacks[1][1])
    t:eq(cb_4, ngx.ctx.callbacks[101][1])
end


function test.args(t)
    ngx.ctx.callbacks = nil
    local cb, err, errmsg = ngx_abort.add_callback(callback_func, 1, 2, 3)
    t:eq(nil, err)
    t:eq(nil, errmsg)
    t:eq(1, cb.args[1])
    t:eq(2, cb.args[2])
    t:eq(3, cb.args[3])
    t:eq(nil, cb.args[4])

    local cb, err, errmsg = ngx_abort.add_callback(callback_func)
    t:eq(nil, err)
    t:eq(nil, errmsg)
    t:eq(nil, next(cb.args))

    local cb, err, errmsg = ngx_abort.add_callback_with_opts(
            callback_func, nil, 1, 2, 3)
    t:eq(nil, err)
    t:eq(nil, errmsg)
    t:eq(1, cb.args[1])
    t:eq(2, cb.args[2])
    t:eq(3, cb.args[3])
    t:eq(nil, cb.args[4])
end


function test.invalid_funv(t)
    local _, err, errmsg = ngx_abort.add_callback('foo')
    t:neq(nil, err)
    t:neq(nil, errmsg)

    local _, err, errmsg = ngx_abort.add_callback_with_opts('foo')
    t:neq(nil, err)
    t:neq(nil, errmsg)
end


function test.remove(t)
    ngx.ctx.callbacks = nil

    local cb_1, err, errmsg = ngx_abort.add_callback_with_opts(
            callback_func, {position='last'})
    t:eq(nil, err)
    t:eq(nil, errmsg)
    t:eq(cb_1, ngx.ctx.callbacks.last[1])

    local _, err, errmsg = ngx_abort.remove_callback(cb_1)
    t:eq(nil, err)
    t:eq(nil, errmsg)
    t:eq(0, #ngx.ctx.callbacks.last)
end
