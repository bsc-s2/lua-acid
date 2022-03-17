local strutil = require( "acid.strutil" )
local rpc_logging = require('acid.rpc_logging')

local has_logging = true

--example, how to use
--   local cli = httpclient:new( ip, port, timeout )
--   cli:request( uri, {method='GET', headers={}, body=''} )
--   status = cli.status
--   headers = cli.headers
--   buf = cli:read_body( size )
--or
--   local cli = httpclient:new( ip, port, timeout )
--   cli:send_request( uri, {method='GET', headers={}, body=''} )
--   cli:send_body( body )
--   cli:finish_request()
--   status = cli.status
--   headers = cli.headers
--   buf = cli:read_body( size )

local to_str = strutil.to_str

local DEFAULT_PORT = 80
local DEFAULT_METHOD = 'GET'
local DEFAULT_TIMEOUT = 60000

local NO_CONTENT = 204
local NOT_MODIFIED = 304

local _M = { _VERSION = '1.0' }
local mt = { __index = _M }

local function _trim( s )
    if type( s ) ~= 'string' then
        return s
    end
    return ( s:gsub( "^%s*(.-)%s*$", "%1" ) )
end

local function _read_line( self )
    return self.sock:receiveuntil('\r\n')()
end

local function _read( self, size )
    if size <= 0 then
        return '', nil
    end

    return self.sock:receive( size )
end

local function _discard_lines_until( self, sequence )
    local skip, err_msg
    sequence = sequence or ''

    while skip ~= sequence do
        skip, err_msg = _read_line( self )
        if err_msg ~= nil then
            return nil, 'SocketReadError', err_msg
        end
    end

    return nil, nil, nil
end

local function _load_resp_status( self )
    local status
    local line
    local err_code
    local err_msg
    local elems
    local _

    while true do
        line, err_msg = _read_line( self )
        if err_msg ~= nil then
            return nil, 'SocketReadError', to_str('read status line:', err_msg)
        end

        elems = strutil.split( line, ' ' )
        if table.getn(elems) < 3 then
            return nil, 'BadStatus', to_str('invalid status line:', line)
        end

        status = tonumber( elems[2] )

        if status == nil or status < 100 or status > 999 then
            return nil, 'BadStatus', to_str('invalid status value:', status)
        elseif 100 <= status and status < 200 then
            _, err_code, err_msg = _discard_lines_until( self, '' )
            if err_code ~= nil then
                return nil, err_code, to_str('read header:', err_msg )
            end
        else
            self.status = status
            break
        end
    end

    return nil, nil, nil
end

local function _load_resp_headers( self )
    local elems
    local err_msg
    local line
    local hname, hvalue

    self.ori_headers = {}
    self.headers = {}

    while true do

        line, err_msg = _read_line( self )
        if err_msg ~= nil then
            return nil, 'SocketReadError', to_str('read header:', err_msg)
        end

        if line == '' then
            break
        end

        elems = strutil.split( line, ':' )
        if table.getn(elems) < 2 then
            return nil, 'BadHeader', to_str('invalid header:', line)
        end

        hname = string.lower( _trim( elems[1] ) )
        hvalue = _trim( line:sub(string.len(elems[1]) + 2) )

        self.ori_headers[_trim(elems[1])] = hvalue
        self.headers[hname] = hvalue
    end

    if self.status == NO_CONTENT or self.status == NOT_MODIFIED
        or self.method == 'HEAD' then
        return nil, nil, nil
    end

    if self.headers['transfer-encoding'] == 'chunked' then
        self.chunked = true
        return nil, nil, nil
    end

    local cont_len = self.headers['content-length']
    if cont_len ~= nil then
        cont_len = tonumber( cont_len )
        if cont_len == nil then
            return nil, 'BadHeader', to_str('invalid content-length header:',
                    self.headers['content-length'])
        end
        self.cont_len = cont_len
        return nil, nil, nil
    end

    return nil, nil, nil
end

local function _norm_headers( headers )
    local hs = {}

    for h, v in pairs( headers ) do
        if type( v ) ~= 'table' then
            v = { v }
        end
        for _, header_val in ipairs( v ) do
            table.insert( hs, to_str( h, ': ', header_val ) )
        end
    end

    return hs
end

local function _read_chunk_size( self )
    local line, err_msg = _read_line( self )
    if err_msg ~= nil then
        return nil, 'SocketReadError', to_str('read chunk size:', err_msg)
    end

    local idx = line:find(';')
    if idx ~= nil then
        line = line:sub(1,idx-1)
    end

    local size = tonumber(line, 16)
    if size == nil then
        return nil, 'BadChunkCoding', to_str('invalid chunk size:', line)
    end

    return size, nil, nil
end

local function _next_chunk( self )

    local size, err_code, err_msg = _read_chunk_size( self )
    if err_code ~= nil then
        return nil, err_code, err_msg
    end

    self.chunk_size = size
    self.chunk_pos = 0

    if size == 0 then
        self.body_end = true

        --discard trailer
        local _, err_code, err_msg = _discard_lines_until( self, '' )
        if err_code ~= nil then
            return nil, err_code, to_str('read trailer:', err_msg )
        end
    end

    return nil, nil, nil
end

local function _read_chunk( self, size )
    local _
    local buf
    local err_code
    local err_msg
    local bufs = {}

    while size > 0 do
        if self.chunk_size == nil then
            _, err_code, err_msg = _next_chunk( self )
            if err_code ~= nil then
                return nil, err_code, err_msg
            end

            if self.body_end then
                break
            end
        end

        buf, err_msg = _read( self, math.min(size,
                self.chunk_size - self.chunk_pos))
        if err_msg ~= nil then
            return nil, 'SocketReadError', to_str('read chunked:', err_msg)
        end

        table.insert( bufs, buf )
        size = size - #buf
        self.chunk_pos = self.chunk_pos + #buf
        self.has_read = self.has_read + #buf

        -- chunk end, ignore '\r\n'
        if self.chunk_pos == self.chunk_size then
            _, err_msg =  _read( self, #'\r\n')
            if err_msg ~= nil then
                return nil, 'SocketReadError', to_str('read chunked:', err_msg)
            end
            self.chunk_size = nil
            self.chunk_pos = nil
        end
    end

    return table.concat( bufs ), nil, nil
end

function _M.new( _, ip, port, timeouts, opts )

    opts = opts or {}

    timeouts = timeouts or DEFAULT_TIMEOUT

    local conn_timeout, send_timeout, read_timeout

    -- connect_timeout, send_timeout, read_timeout
    if type(timeouts) == 'table' then
        conn_timeout, send_timeout, read_timeout =
            timeouts[1], timeouts[2], timeouts[3]
    else
        conn_timeout, send_timeout, read_timeout =
            timeouts, timeouts, timeouts
    end

    local sock= ngx.socket.tcp()
    sock:settimeouts( conn_timeout, send_timeout, read_timeout )

    local h = {
        ip = ip,
        port = port or DEFAULT_PORT,

        conn_timeout = conn_timeout,
        send_timeout = send_timeout,
        read_timeout = read_timeout,

        sock = sock,
        has_read = 0,
        cont_len = 0,
        body_end = false,
        chunked  = false,

        ssl = opts.ssl == true,
        reused_session = opts.reused_session,
        server_name = opts.server_name,
        ssl_verify = opts.ssl_verify ~= false,
        send_status_req = opts.send_status_req == true,

        service_key = opts.service_key or 'port-' .. (port or DEFAULT_PORT),
    }

    return setmetatable( h, mt )
end

function _M.request( self, uri, opts )

    local _, err_code, err_msg = self:send_request( uri, opts )
    if err_code ~= nil then
        return nil, err_code, err_msg
    end

    return self:finish_request()
end

function _M.send_request( self, uri, opts )

    opts = opts or {}

    self.uri = uri
    self.method = opts.method or DEFAULT_METHOD

    local body = opts.body or ''
    local headers = opts.headers or {}
    headers.Host = headers.Host or self.ip
    if #body > 0 and headers['Content-Length'] == nil then
        headers['Content-Length'] = #body
    end

    local sbuf = {to_str(self.method, ' ', self.uri, ' HTTP/1.1'),
            unpack( _norm_headers( headers ) )
    }
    table.insert( sbuf, '' )
    table.insert( sbuf, body )

    sbuf = table.concat( sbuf, '\r\n' )

    if has_logging then
        self.log = rpc_logging.new_entry(self.service_key, {
            ip = self.ip,
            port = self.port,
            uri = self.uri,
        })

        if headers['Range'] ~= nil then
            local r, err, _ = _M.parse_request_range(headers['Range'], nil)
            if err == nil then
                self.log.range = {from = r.start, to = r['end']}
            end
        end

        rpc_logging.add_log(self.log)
    end

    local _, err_msg = self.sock:connect( self.ip, self.port )

    rpc_logging.set_time(self.log, 'upstream', 'conn')

    if err_msg ~= nil then
        rpc_logging.set_err(self.log, 'SocketError')
        return nil, 'SocketConnectError', to_str('connect:', err_msg)
    end

    if self.port == 443 or self.ssl == true then
        rpc_logging.reset_start(self.log)

        local session, err_msg = self.sock:sslhandshake(
                self.reused_session, self.server_name,
                self.ssl_verify, self.send_status_req)

        self.ssl_session = session

        rpc_logging.set_time(self.log, 'upstream', 'sslhandshake')

        if err_msg ~= nil then
            rpc_logging.set_err(self.log, 'SocketError')
            return nil, 'SocketSSLHandShakeError',
                    to_str('sslhandshake:', err_msg)
        end
    end

    rpc_logging.reset_start(self.log)

    local _, err_msg = self.sock:send( sbuf )

    rpc_logging.set_time(self.log, 'upstream', 'send')

    if err_msg ~= nil then
        rpc_logging.set_err(self.log, 'SocketError')
        return nil, 'SocketSendError', to_str('request:', err_msg)
    end

    return nil, nil, nil
end

function _M.send_body( self, body )
    local bytes = 0
    local err_msg

    if body ~= nil then

        rpc_logging.reset_start(self.log)

        bytes, err_msg = self.sock:send( body )
        rpc_logging.incr_time(self.log, 'upstream', 'sendbody')

        if err_msg ~= nil then

            rpc_logging.set_err(self.log, err_msg)

            return nil, 'SocketSendError',
                to_str('send body:', err_msg)
        else
            rpc_logging.incr_byte(self.log, 'upstream', 'sendbody', #body)
        end
    end

    return bytes, nil, nil
end

function _M.finish_request( self )
    local _
    local err_code
    local err_msg

    rpc_logging.reset_start(self.log)

    _, err_code, err_msg = _load_resp_status( self )

    rpc_logging.incr_time(self.log, 'upstream', 'recv')
    rpc_logging.set_status(self.log, self.status)
    rpc_logging.set_err(self.log, err_code)

    if err_code ~= nil then
        return nil, err_code, err_msg
    end

    rpc_logging.reset_start(self.log)

    _, err_code, err_msg = _load_resp_headers( self )

    rpc_logging.incr_time(self.log, 'upstream', 'recv')
    rpc_logging.set_err(self.log, err_code)

    if err_code ~= nil then
        return nil, err_code, err_msg
    end

    return nil, nil, nil
end

function _M.read_body(self, size, blocksize)

    local body = {}
    if blocksize == nil or type(blocksize) ~= 'number' or blocksize <= 1024 then
        blocksize = 1024*1024
    end

    while size > 0 do

        rpc_logging.reset_start(self.log)

        local buf, err, errmes = self:read_one_block( math.min(size, blocksize) )

        rpc_logging.incr_stat(self.log, 'upstream', 'recvbody', #(buf or ''))
        rpc_logging.set_err(self.log, err)

        if err ~= nil then
            return nil, err, errmes
        end

        if buf == '' then
            break
        end

        size = size - #buf
        table.insert( body, buf )
    end

    return table.concat( body ), nil, nil
end

function _M.read_one_block( self, size )

    if self.body_end then
        return '', nil, nil
    end

    if self.chunked then
       return _read_chunk( self, size )
    end

    local rest_len = self.cont_len - self.has_read

    local buf, err_msg = _read( self, math.min(size, rest_len))
    if err_msg ~= nil then
        return nil, 'SocketReadError', to_str('read body:', err_msg)
    end

    self.has_read = self.has_read + #buf

    if self.has_read == self.cont_len then
        self.body_end = true
    end


    return buf, nil, nil
end

function _M.set_keepalive( self, timeout, size )
    local _, err_msg = self.sock:setkeepalive( timeout, size )
    if err_msg ~= nil then
        return nil, 'SocketError', to_str('set keepalive:', err_msg)
    end

    return nil, nil, nil
end

function _M.set_timeout( self, time )
    self.sock:settimeout( time )
end

function _M.set_timeouts( self, conn_timeout, send_timeout, read_timeout )
    self.sock:settimeouts( conn_timeout, send_timeout, read_timeout )
end

function _M.close( self )
    local _, err_msg = self.sock:close()
    if err_msg ~= nil then
        return nil, 'SocketCloseError', to_str('close:', err_msg)
    end

    return nil, nil, nil
end

function _M.parse_request_range(range, file_size)

    local s
    local elts
    local r_start, r_end

    -- if file_size is nil, you must make sure range start and end is not empty

    if range == nil and file_size == nil then
        return {}, nil, nil
    end

    if not string.find(range, 'bytes=') or file_size == 0 then
        return nil, 'InvalidRange', 'request range ' .. tostring(range)
                                        .. ' file size: ' .. tostring(file_size)
    end

    s = string.find(range, '=')
    elts = strutil.split( range:sub(s+1), '-' )
    if #elts ~= 2 then
        return nil, 'InvalidRange', 'request range ' .. tostring(range)
    end

    r_start = tonumber( elts[1] )
    r_end = tonumber( elts[2] )
    if r_start == nil and r_end == nil then
        return nil, 'InvalidRange', 'request range ' .. tostring(range)
    end

    if file_size == nil then
        return { ['start'] = r_start, ['end'] = r_end }, nil, nil
    end

    if r_start == nil then
        r_start = file_size - r_end
        r_end = file_size - 1
    elseif r_end == nil then
        r_end = file_size - 1
    end

    if r_start < 0 then
        r_start = 0
    end

    if r_end > file_size - 1 then
        r_end = file_size - 1
    end

    if r_start > r_end then
        return nil, 'InvalidRange', 'request range ' .. tostring(range)
    end

    return { ['start'] = r_start, ['end'] = r_end }, nil, nil

end

function _M.get_reused_times(self)
    local count, err_msg = self.sock:getreusedtimes()
    if err_msg ~= nil then
        return nil, 'SocketError', err_msg
    end

    return count
end

return _M
