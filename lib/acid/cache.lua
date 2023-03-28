local json = require('acid.json')
local resty_lock = require("resty.lock")
local tableutil = require("acid.tableutil")
local strutil = require("acid.strutil")
local ngx_abort = require("acid.ngx_abort")

local to_str = strutil.to_str
local ngx = ngx

local _M = { _VERSION  = '1.0' }

-- TODO test

-- use cache must be declare shared dict 'shared_dict_lock'
-- in nginx configuration

_M.shared_dict_lock = 'shared_dict_lock'

_M.accessor = {

    proc = {

        get = function( dict, key, opts )

            if opts.flush then
                return nil
            end

            local use_stale = opts.use_stale or nil
            local val = dict[key]

            ngx.log(ngx.DEBUG, "get [", key, "] value from proc cache: ", to_str(val))

            if val ~= nil and (val.expires > ngx.time() or
                        (use_stale == true and val.stale_expires > ngx.time())) then
                if opts.dup ~= false then
                    return tableutil.dup( val.data, true )
                end
                return val.data
            end

            return nil
        end,

        set = function( dict, key, val, opts )

            -- set but timeout at once
            if opts.exptime == 0 then
                dict[key] = nil
                return
            end

            local expires = ngx.time() + (opts.exptime or 60)
            local stale_expires = expires + (opts.stale_exptime or 0)

            val = { expires = expires,
                    stale_expires = stale_expires,
                    data = val }

            dict[key] = val
        end,
    },

    shdict = {

        get = function( dict, key, opts )

            if opts.flush then
                return nil
            end

            local use_stale = opts.use_stale or nil
            -- NOTICE: The expires value may be nil, when nginx reload is executed
            -- and no flags is specified in the previous shdict set.
            local val, expires = dict:get( key )

            ngx.log(ngx.DEBUG, "get [", key, "] value from shdict cache: ", to_str(val))
            if val ~= nil and (expires == nil or
                    (expires > ngx.time() or use_stale == true)) then
                val = json.dec( val )

                return val
            end
            return nil
        end,

        set = function( dict, key, val, opts )

            -- shareddict:set(exptime=0) means never timeout

            if opts.exptime == 0 then
                dict:delete(key)
                return
            end

            local expires = ngx.time() + (opts.exptime or 60)
            local exptime = (opts.exptime or 60) + (opts.stale_exptime or 0)

            dict:set( key, json.enc(val), exptime, expires)
        end,
    },
}

local function abort_cb(lock)
    if lock ~= nil then
        lock:unlock()
    end
end

function _M.cacheable( dict, key, func, opts )

    local val
    local elapsed
    local err_code
    local err_msg

    opts = tableutil.dup( opts or {}, true )

    if opts.accessor == nil then

        opts.accessor = _M.accessor.proc

        if type(dict.flush_all) == 'function' then
            opts.accessor = _M.accessor.shdict
        end

    end

    opts.accessor = {
        get = opts.accessor.get or _M.accessor.proc.get,
        set = opts.accessor.set or _M.accessor.proc.set,
    }

    val = opts.accessor.get( dict, key, opts )
    if val ~= nil then
        return val, nil, nil
    end

    local lock, err_msg = resty_lock:new( _M.shared_dict_lock,
            { exptime=opts.lock_exptime or 30, timeout=opts.lock_timeout or 30 } )
    if err_msg ~= nil then
        return nil, 'LockError',
                err_msg .. ' while new lock:' .. _M.shared_dict_lock
    end

    local cb = ngx_abort.add_callback(abort_cb, lock)

    elapsed, err_msg = lock:lock( tostring(dict) .. key )

    if (elapsed or 0.2) > 0.2 then
        ngx.log(ngx.INFO, 'elapsed: ', elapsed, ' seconds, when try lock:', key)
    end

    if err_msg ~= nil then
        ngx_abort.remove_callback(cb)
        return nil, 'LockTimeout', err_msg .. ' while lock:' .. key
    end

    val, err_code, err_msg =
        _M.cacheable_nolock( dict, key, func, opts )

    lock:unlock()
    ngx_abort.remove_callback(cb)

    return val, err_code, err_msg
end

function _M.cacheable_nolock( dict, key, func, opts )

    local val
    local err_code
    local err_msg

    val = opts.accessor.get( dict, key, opts )
    if val ~= nil then
        return val, nil, nil
    end

    val, err_code, err_msg = func(unpack(opts.args or {}))
    if err_code ~= nil then
        if opts.use_stale_val_if_error == true then
            opts.use_stale = true
            val = opts.accessor.get( dict, key, opts )
            if val ~= nil then
                return val
            end
        end
        return nil, err_code, err_msg
    end

    if val ~= nil then
        opts.accessor.set( dict, key, val, opts )
    end

    return val, nil, nil
end

return _M
