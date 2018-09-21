local _M = { _VERSION = '1.0' }
local strutil = require("acid.strutil")

local ngx = ngx
local max_log_entry = 128

local function addfield(tbl, str, fld, sep)
    if fld ~= nil then
        table.insert(tbl, str)
        table.insert(tbl, strutil.placeholder(fld, fld or '-', '%.3f'))
        if sep then
            table.insert(tbl, sep)
        end
    end
end


function _M.new_entry(service_key, opt)

    opt = opt or {}

    local now = ngx.now()
    local begin_process = ngx.req.start_time()

    local e = {

        service_key = service_key,
        added = false,

        begin_process = begin_process,

        start_in_req = now - begin_process,

        -- start time of conn, send or recv
        start = now,

        -- to other service
        upstream = {
            time = {
                -- conn = nil,
                -- sslhandshake = nil,
                -- send = nil,
                -- sendbody = nil,
                -- recv = nil,
                -- recvbody = nil,
                -- lastrecvbody = nil,
                -- lastsendbody = nil,
            },
            byte = {
                -- send = nil,
                -- sendbody = nil,
                -- recv = nil,
                -- recvbody = nil,
            },
            count = {
                -- recvbody = nil,
                -- sendbody = nil,
                -- entry = nil,
            },
        },

        -- to client.
        -- presents if this log is for a piping rpc.
        -- for downstream, time.conn is meaningless, and it should always be
        -- nil.
        downstream = {
            time = {
                -- conn = nil,
                -- send = nil,
                -- sendbody = nil,
                -- recv = nil,
                -- recvbody = nil,
                -- lastrecvbody = nil,
                -- lastsendbody = nil,
            },
            byte = {
                -- send = nil,
                -- sendbody = nil,
                -- recv = nil,
                -- recvbody = nil,
            },
            count = {
                -- recvbody = nil,
                -- sendbody = nil,
                -- entry = nil,
            },
        },
    }

    e.scheme = opt.scheme
    e.ip = opt.ip
    e.port = opt.port
    e.uri = opt.uri
    e.status = opt.status
    e.err = opt.err
    e.range = opt.range

    e.upstream = opt.upstream or e.upstream
    e.downstream = opt.downstream or e.downstream

    return e
end


local function update_count(entry, updown, field)
    if field ~= 'sendbody' and field ~= 'recvbody' then
        return
    end

    local prev = entry[updown].count[field] or 0
    entry[updown].count[field] = prev + 1
end

local function update_last_time(entry, updown, field)
    if field ~= 'sendbody' and field ~= 'recvbody' then
        return
    end

    local last_time = ngx.now() - entry.begin_process
    entry[updown].time['last'..field] = last_time
end

function _M.reset_start(entry)
    if entry == nil then
        return
    end
    entry.start = ngx.now()
end

function _M.set_time(entry, updown, field)

    if entry == nil then
        return
    end

    local now = ngx.now()
    entry[updown].time[field] = now - entry.start

    entry.start = now
end

function _M.set_time_val(entry, updown, field, val)

    if entry == nil then
        return
    end

    entry[updown].time[field] = val
end

function _M.set_entry_val(entry, updown, val)

    if entry == nil then
        return
    end

    entry[updown].count['entry'] = val
end

function _M.incr_stat(entry, updown, field, size)
    _M.incr_time(entry, updown, field)
    _M.incr_byte(entry, updown, field, size)
end


function _M.incr_time(entry, updown, field)

    if entry == nil then
        return
    end

    local now = ngx.now()
    local prev = entry[updown].time[field] or 0
    entry[updown].time[field] = prev + now - entry.start

    entry.start = now
end


function _M.incr_byte(entry, updown, field, size)

    if entry == nil then
        return
    end

    if size == 0 then
        return
    end

    local prev = entry[updown].byte[field] or 0
    entry[updown].byte[field] = prev + size

    update_last_time(entry, updown, field)
    update_count(entry, updown, field)
end


function _M.set_err(entry, err)
    if entry == nil then
        return
    end

    if err == nil then
        entry.err = nil
        return
    end

    _M.end_entry(entry, {err = err})
end


function _M.set_status(entry, status)
    if entry == nil then
        return
    end
    entry.status = status
end


function _M.end_entry(e, opt)
    if e == nil then
        return
    end

    opt = opt or {}
    e.err = opt.err
    e.status = opt.status

    _M.add_log(e)
end


function _M.add_log(entry)

    if entry == nil then
        return
    end

    if entry.added then
        return
    end

    local logs = ngx.ctx.rpc_logs
    if logs == nil then
        ngx.ctx.rpc_logs = {}
        logs = ngx.ctx.rpc_logs
    end

    if #logs > max_log_entry then
        return
    end

    table.insert(logs, entry)
    entry.added = true
end


function _M.get_logs(service_key)
    local rpc_logs = ngx.ctx.rpc_logs
    if service_key == nil then
        return rpc_logs
    end

    local logs = {}

    for _, e in ipairs(rpc_logs or {}) do
        if e.service_key == service_key then
            table.insert(logs, e)
        end
    end

    return logs
end


function _M.log_str(logs)

    logs = logs or ngx.ctx.rpc_logs or {}

    local s = {}
    for _, e in ipairs(logs) do
        table.insert( s, _M.entry_str(e))
    end

    return table.concat( s, ' ' )
end


function _M.entry_str(e)
    local rng = e.range

    local s = { strutil.placeholder(e.service_key), }
    addfield(s, ',status:', e.status)
    addfield(s, ',err:', e.err)
    addfield(s, ',url:', '')
    addfield(s, '', e.scheme, '://')
    addfield(s, '', e.ip)
    addfield(s, ':', e.port)
    addfield(s, '', e.uri)

    if rng ~= nil then
        table.insert(s, ',range:[' .. strutil.placeholder(rng.from, '-', '%.3f')
             .. ',' .. strutil.placeholder(rng.to, '-', '%.3f') .. ')')
    end

    addfield(s, ',sent:', e.sent)

    addfield(s, ',start_in_req:', e.start_in_req)

    local up = e.upstream
    if up then

        addfield(s, ',upstream:{', '')
        local st

        st = up.time
        if st then
            addfield(s, 'time:{', '')
            addfield(s, 'conn:', st.conn, ',')
            addfield(s, 'send:', st.send, ',')
            addfield(s, 'sendbody:', st.sendbody, ',')
            addfield(s, 'recv:', st.recv, ',')
            addfield(s, 'recvbody:', st.recvbody, ',')
            addfield(s, 'lastsendbody:', st.lastsendbody, ',')
            addfield(s, 'lastrecvbody:', st.lastrecvbody)
            addfield(s, '},', '')
        end

        st = up.byte
        if st then
            addfield(s, 'byte:{', '')
            addfield(s, 'send:', st.send, ',')
            addfield(s, 'sendbody:', st.sendbody, ',')
            addfield(s, 'recv:', st.recv, ',')
            addfield(s, 'recvbody:', st.recvbody)
            addfield(s, '},', '')
        end

        st = up.count
        if st then
            addfield(s, 'count:{', '')
            addfield(s, 'sendbody:', st.sendbody, ',')
            addfield(s, 'recvbody:', st.recvbody, ',')
            addfield(s, 'entry:', st.entry)
            addfield(s, '},', '')
        end

        addfield(s, '}', '')
    end

    local down = e.downstream
    if down then

        addfield(s, ',downstream:{', '')
        local st

        st = down.time
        if st then
            addfield(s, 'time:{', '')
            addfield(s, 'conn:', st.conn, ',')
            addfield(s, 'send:', st.send, ',')
            addfield(s, 'sendbody:', st.sendbody, ',')
            addfield(s, 'recv:', st.recv, ',')
            addfield(s, 'recvbody:', st.recvbody, ',')
            addfield(s, 'lastsendbody:', st.lastsendbody, ',')
            addfield(s, 'lastrecvbody:', st.lastrecvbody)
            addfield(s, '},', '')
        end

        st = down.byte
        if st then
            addfield(s, 'byte:{', '')
            addfield(s, 'send:', st.send, ',')
            addfield(s, 'sendbody:', st.sendbody, ',')
            addfield(s, 'recv:', st.recv, ',')
            addfield(s, 'recvbody:', st.recvbody)
            addfield(s, '},', '')
        end

        st = down.count
        if st then
            addfield(s, 'count:{', '')
            addfield(s, 'sendbody:', st.sendbody, ',')
            addfield(s, 'recvbody:', st.recvbody, ',')
            addfield(s, 'entry:', st.entry)
            addfield(s, '},', '')
        end

        addfield(s, '}', '')

    end
    return table.concat(s)
end
return _M
