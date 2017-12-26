local strutil = require('acid.strutil')
local time = require('acid.time')


local to_str = strutil.to_str


local _M = {}


local level_to_str = {
    [ngx.DEBUG] = '[debug]',
    [ngx.INFO] = '[info]',
    [ngx.NOTICE] = '[notice]',
    [ngx.WARN] = '[warn]',
    [ngx.ERR] = '[error]',
    [ngx.CRIT] = '[crit]',
    [ngx.ALERT] = '[alert]',
    [ngx.EMERG] = '[emerg]',
}


local function write_to_file(log_path, log_ctx)
    if log_ctx == nil then
        return
    end

    table.insert(log_ctx.log_entry, to_str(log_ctx.counter) .. '\n')

    local data = table.concat(log_ctx.log_entry, '')

    local f = io.open(log_path, 'a+')
    f:write(data)
    f:close()
end


local function feed_log_entry(level, repeat_n, prefix, args)
    local log_ctx = ngx.ctx.category_log
    local log_entry = log_ctx.log_entry

    if #log_entry >= _M.max_entry_n then
        return
    end

    if repeat_n > _M.max_repeat_n then
        return
    end

    local time_str = time.format(ngx.time(), 'nginxerrorlog')
    local level_str = level_to_str[level]

    local parts = {time_str, level_str, ngx.worker.pid(), prefix}

    for _, v in ipairs(args) do
        table.insert(parts, tostring(v))
    end

    local log_line = table.concat(parts, ', ') .. '\n'

    table.insert(log_entry, log_line)

    return
end


local function _get_request_id()
    local request_id = ngx.var.requestid
    return request_id
end


local function get_request_id()
    local ok, request_id = pcall(_get_request_id)
    if not ok then
        return
    end

    return request_id
end


local function log_by_category(level, src_file_name, line_number, prefix, args)
    local log_ctx = ngx.ctx.category_log

    local counter = log_ctx.counter

    local ident = string.format('%s_%d', src_file_name, line_number)
    counter[ident] = (counter[ident] or 0) + 1

    local repeat_n = counter[ident]

    feed_log_entry(level, repeat_n, prefix, args)

    return
end


local function _category_log(level, ...)
    if ngx.ctx.category_log == nil then
        ngx.ctx.category_log = {
            -- contain log entries.
            log_entry = {},
            -- save how many times a log on same source file
            -- and same line nubmer have repeated.
            counter = {},
        }
    end

    local log_ctx = ngx.ctx.category_log

    if log_ctx.request_id == nil then
        log_ctx.request_id = get_request_id()
    end

    -- get info of function at level 4 of the call stack, which is the
    -- function called ngx.log
    local debug_info = debug.getinfo(4)
    local path_parts = strutil.rsplit(debug_info.short_src, '/',
                                      {plain=true, maxsplit=1})
    local src_file_name = path_parts[#path_parts]
    local line_number = debug_info.currentline
    local func_name = debug_info.name

    local prefix = string.format('%s %s:%d %s() ', log_ctx.request_id,
                                 src_file_name, line_number, func_name)

    _M.origin_log(level, prefix, ...)

    if level > _M.log_level then
        return
    end

    log_by_category(level, src_file_name, line_number, prefix, {...})

    return
end


local function category_log(level, ...)
    local ok, err = pcall(_category_log, level, ...)
    if not ok then
        _M.origin_log(ngx.ERR, 'failed to do category log: %s' .. err)
    end
end


function _M.wrap_log(opts)
    if _M.origin_log ~= nil then
        ngx.log(ngx.ERR, 'ngx.log can be wrapped only once')
        return
    end

    _M.origin_log = ngx.log

    if opts == nil then
        opts = {}
    end

    _M.get_category_file = opts.get_category_file
    _M.max_repeat_n = opts.max_repeat_n
    _M.max_entry_n = opts.max_entry_n
    _M.log_level = opts.log_level or ngx.INFO

    ngx.log = category_log

    return
end


local function write_log_timer(premature, log_path, log_ctx)
    if premature then
        _M.origin_log(ngx.WARN, 'write log timer premature')
        return
    end

    write_to_file(log_path, log_ctx)
end


function _M.write_log()
    local log_ctx = ngx.ctx.category_log
    if log_ctx == nil then
        return
    end

    local log_path = _M.get_category_file()
    if log_path == nil then
        return
    end

    local ok, err = ngx.timer.at(0, write_log_timer, log_path, log_ctx)
    if not ok then
        _M.origin_log(ngx.ERR, 'failed to add write log timer: ' .. err)
    end
end


return _M
