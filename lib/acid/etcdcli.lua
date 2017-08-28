local strutil = require("acid.strutil")
local urlutil = require("acid.urlutil")
local httpclient = require( "acid.httpclient" )
local acid_json = require("acid.json")

local ngx = ngx

local ETCD_PORT_CLIENT = 2379
local ETCD_READ_TIMEOUT = 10000     -- millisecond

local REDIRECT_STATUS = { [301]=true, [302]=true, [303]=true,
                          [307]=true, [308]=true }

-- keys options
local comparison_conditions = {prevValue=true, prevIndex=true, prevExist=true}
local read_options = {recursive=true, wait=true, waitIndex=true,
                      sorted=true, quorum=true}
local del_conditions = {prevValue=true, prevIndex=true}

local etcderrors = {
    [100] = "KeyError",
    [101] = "ValueError",
    [102] = "KeyError",
    [103] = "EtcdError",
    [104] = "KeyError",
    [105] = "KeyError",
    [106] = "KeyError",
    [107] = "ValueError",
    [200] = "ValueError",
    [201] = "ValueError",
    [202] = "ValueError",
    [203] = "ValueError",
    [209] = "ValueError",
    [300] = "EtcdError",
    [301] = "EtcdError",
    [400] = "EtcdWatchError",
    [401] = "EtcdWatchError",
    [500] = "EtcdError",
}

--[[example, how to use
local cli = etcdcli:new( {'172.16.140.81','172.16.235.103'},
                {port=2379,read_timeout=30000} )

local t = {}
t.version = cli:version()
t.machines = cli:machines()

cli response is a table: like
{ status = 200
  headers = { 'x-etcd-index' = 1000 }
  body = response_str
  data = response_table
}

t.root = cli:read( '/', {recursive=true} )
t.read = cli:read( '/test' )
t.write = cli:write( '/test', {value='test'} )
t.get = cli:get( '/test' )
t.watch = cli:watch( '/test', {waitIndex=1024000, timeout=1000} )
t.watchnext = cli:watch( '/test', {timeout=60000} )
t.delete = cli:delete( '/test' )

-- NOTICE:
--      cli:watch() do not set timeout=0,
--      when socket timeout is 0, nginx lua do not
--      collectgarbage( 'collect' ) automatically

--]]


local _M = { _VERSION = '1.0' }
local mt = { __index = _M }


local function url_to_host_port_path( url )
    local host, port, path

    if strutil.startswith( url, '/' ) then
        return nil, nil, url
    end

    if strutil.startswith( url, 'http://' ) then
        url = url:sub( #'http://'+1  )
    end

    host = strutil.split( url, '/' )[1]
    path = url:sub( #host+1 )

    host = strutil.split( host, ':' )
    host, port = host[1], host[2]
    port = port or 80

    return host, tonumber(port), path
end

local function request( self, path, method, params, timeout )

    timeout = timeout or self._read_timeout

    local err, msg, msg_tail

    local body
    local headers, qs

    local _
    local host, port
    local url = self._base_url .. path
    local prev_host = self._host
    local prev_port = self._port

    local resp

    while true do

        host, port, path = url_to_host_port_path( url )
        host = host or prev_host
        port = port or prev_port

        prev_host, prev_port = host, port

        qs = {}
        headers = {}

        if method == 'GET' or method == 'DELETE' then
            if params then
                qs = params
            end

            params = nil
            body = ''
        elseif method == 'PUT' or method == 'POST' then
            body = urlutil.build_query( params or {} )
            headers['Content-Type'] = 'application/x-www-form-urlencoded'
            headers['Content-Length'] = #body
        else
            return nil, "RequestError", "HTTP method " .. method .. " not supported"
        end

        if self._basic_auth_account ~= nil then
            headers['Authorization'] = 'Basic ' .. ngx.encode_base64(self._basic_auth_account)
        end

        local s = string.find( path, '?' )
        if s then
            path = path .. '&' .. urlutil.build_query( qs )
        else
            path = path .. '?' .. urlutil.build_query( qs )
        end

        msg_tail = ' to conn: ' .. method .. ' '
                    .. self._protocol .. '://' .. host .. ':' .. port .. path .. ' timeout:'
                    .. timeout .. 'ms'

        local h = httpclient:new( host, port, timeout )

        _, err, msg = h:send_request( path, {method=method,
                                          headers=headers,
                                          body=body} )
        if err then
            return nil, err, msg .. msg_tail
        end

        _, err, msg = h:finish_request()
        if err then
            return nil, err, msg .. msg_tail
        end

        resp = {}
        resp.status = h.status
        resp.headers = h.headers
        resp.body = ''

        local buf
        while true do
            buf, err, msg = h:read_body( 1024*1024 )
            if err then
                return nil, err, msg .. msg_tail
            end

            if buf == '' then
                break
            end
            resp.body = resp.body .. buf
        end

        if self._allow_redirect and REDIRECT_STATUS[ resp.status ] then
            url = resp.headers['location']
            if url == nil then
                return nil, "ResponseError", "not found location in response headers"
            end
        else
            return resp
        end

    end
end

function _M._handle_server_response( self, resp )

    local err = "ResponseError"
    if resp == nil then
        return nil, err, "no response"
    end

    if resp.status == ngx.HTTP_OK or resp.status == ngx.HTTP_CREATED then
        return resp
    end

    local data, e = acid_json.dec( resp.body )
    if e then
        ngx.log( ngx.INFO, e .. ' : ' .. resp.body )
        return nil, err, 'cannot decode:' .. resp.body
    end

    if data.S3Error then
        return nil, data.S3Error, (data.Message or '')
    end

    local errcode = data.errorCode
    if errcode == nil or etcderrors[ errcode ] == nil then
        return nil, err, 'status:' .. resp.status .. ' body:' .. resp.body
    end

    err = etcderrors[ errcode ]
    return nil, err, 'message:' .. (data.message or '') .. ' cause:' .. (data.cause or '')
end

function _M.next_host( self )
    if self._hostid >= #self._hosts then
        self._hostid = 1
    else
        self._hostid = self._hostid + 1
    end

    self._host = self._hosts[ self._hostid ]
    ngx.log( ngx.INFO, 'try next host ' .. self._host )

    self._base_url = self._protocol .. '://' .. self._host .. ':' .. self._port
end

function _M.api_execute( self, path, method, params, timeout )

    local resp, err, msg

    for _ = 1, #self._hosts * 3 do
        resp, err, msg = request( self, path, method, params, timeout )
        if resp ~= nil then
            break
        end

        ngx.log( ngx.ERR, err .. ' : ' .. msg )
        self:next_host()
    end

    if resp == nil then
        return nil, "RequestError", "request failed while try all hosts"
    end

    return self:_handle_server_response( resp )
end

function _M.new( self, host, opts )

    local err = "InitError"

    opts = opts or {}
    if type(opts) ~= 'table' then
        return nil, err, "opts must be table"
    end

    local hosts = {}
    if host == nil then
        return nil, err, "pls set host for client"
    end

    if type(host) == 'string' then
        hosts = { host }

    elseif type(host) == 'table' then
        for _, v in ipairs(host) do
            table.insert( hosts, v )
        end
    else
        return nil, err, "error type '" .. type(host) .. "' of host "
    end

    if #hosts == 0 then
        return nil, err, "pls set host for client"
    end

    local hostid = 1
    local host = hosts[ hostid ]
    local port = opts.port or ETCD_PORT_CLIENT
    local protocol = opts.protocol or 'http'
    if protocol == 'https' then
        return nil, err, "not supported https right now"
    end

    local base_url = protocol .. '://' .. host .. ':' .. port

    return setmetatable( {
            _host = host,
            _port = port,
            _protocol = protocol,
            _hosts = hosts,
            _hostid = hostid,
            _base_url = base_url,
            _version_prefix = opts.version_prefix or '/v2',
            _read_timeout = opts.read_timeout or ETCD_READ_TIMEOUT,
            _allow_redirect = opts.allow_redirect ~= false,
            _allow_reconnect = opts.allow_reconnect ~= false,
            _expires = opts.expires or 30 * 60,
            _basic_auth_account = opts.basic_auth_account,
        }, mt )
end

local function _sanitize_key( key )
    if strutil.startswith( key, '/' ) then
        return key
    end

    return '/' .. key
end

function _M.keys_endpoint( self )
    return self._version_prefix .. '/keys'
end

function _M._result_from_response( self, resp )

    local data, err = acid_json.dec( resp.body )
    if err then
        return nil, "ResponseError", err .. ' while decode: ' .. resp.body
    end

    local r = {}
    r.status = resp.status
    r.headers = resp.headers
    r.body = resp.body
    r.data = data

    return r
end

function _M.read( self, key, opts )
    --[
    --  key:  Key.
    --  opts:
    --      recursive : If you should fetch recursively a dir
    --      wait      : If we should wait and return next time the key is changed
    --      waitIndex : The index to fetch results from.
    --      sorted    : Sort the output keys (alphanumerically)
    --
    --      timeout   : max milliseconds to wait for a read.
    --]

    opts = opts or {}
    key = _sanitize_key( key )

    local params = {}
    for k, v in pairs( opts ) do
        if read_options[ k ] then
            params[ k ] = tostring( v )
        end
    end

    local resp, err, msg = self:api_execute( self:keys_endpoint() .. key, 'GET',
                                                params, opts.timeout )
    if err then
        ngx.log( ngx.INFO, err .. ' : ' .. msg )
        return nil, err, msg
    end

    return self:_result_from_response( resp )
end

function _M.get( self, key, opts )
    return self:read( key, opts )
end

function _M.write( self, key, opts )
    --[
    -- key
    -- opts:
    --      value : value to set
    --      ttl   : ttl
    --      dir   : Set to true if we are writing a directory; default is nil.
    --      append: If true, it will post to append the new value to the dir,
    --              creating a sequential key. Defaults to nil
    --
    --      prevValue : compare key to this value,
    --                  and swap only if corresponding (optional).
    --      prevIndex : modify key only if actual modifiedIndex
    --                  matches the provided one (optional).
    --      prevExist : If false, only create key; if true, only update key.
    --
    --      timeout   : max milliseconds to wait for a write.
    --]

    opts = opts or {}
    key = _sanitize_key( key )

    local params = {}
    params[ 'value' ] = opts.value
    params[ 'ttl' ] = opts.ttl

    if opts.dir then
        if opts.value then
            return nil, 'RequestError', 'cannot create a directory with a value'
        end
        params[ 'dir' ] = 'true'
    end

    for k, v in pairs( opts ) do
        if comparison_conditions[ k ] then
            params[ k ] = tostring( v )
        end
    end

    local method = "PUT"
    if opts.append then
        method = "POST"
    end

    local resp, err, msg = self:api_execute( self:keys_endpoint() .. key, method,
                                                params, opts.timeout )
    if err then
        ngx.log( ngx.INFO, err .. ' : ' .. msg )
        return nil, err, msg
    end

    return self:_result_from_response( resp )
end

function _M.delete( self, key, opts )
    --[
    -- key
    -- opts:
    --      recursive : recursive
    --      dir       : Set to true if we are writing a directory; default is nil.
    --
    --      prevValue : compare key to this value,
    --                  and swap only if corresponding (optional).
    --      prevIndex : modify key only if actual modifiedIndex
    --                  matches the provided one (optional).
    --
    --      timeout   : max milliseconds to wait for a write.
    --]

    opts = opts or {}
    key = _sanitize_key( key )

    local params = {}

    if opts.recursive then
        params[ 'recursive' ] = 'true'
    end
    if opts.dir then
        params[ 'dir' ] = 'true'
    end

    for k, v in pairs( opts ) do
        if del_conditions[ k ] then
            params[ k ] = tostring( v )
        end
    end

    local resp, err, msg = self:api_execute( self:keys_endpoint() .. key, 'DELETE',
                                                params, opts.timeout )
    if err then
        ngx.log( ngx.INFO, err .. ' : ' .. msg )
        return nil, err, msg
    end

    return self:_result_from_response( resp )
end

function _M.watch( self, key, opts )

    opts = opts or {}

    local r, err, msg = self:get( key )
    if err then
        return r, err, msg
    end

    if opts.waitIndex ~= nil
        and opts.waitIndex > 0
        and opts.waitIndex <= r.data.node.modifiedIndex then
        return r
    else
        opts.waitIndex = r.headers[ 'x-etcd-index' ] + 1
        return self:_watch( key, opts )
    end

end

function _M._watch( self, key, opts )
    --[
    -- key
    -- opts:
    --      wait      : forever true
    --      waitIndex : The index to fetch results from.
    --      recursive : If you should fetch recursively a dir
    --
    --      timeout   : max milliseconds to wait for a write.
    --                  if timeout <= 0, wait forever until a change of key
    --]

    opts = opts or {}
    key = _sanitize_key( key )

    local params = {}
    for k, v in pairs( opts ) do
        if read_options[ k ] then
            params[ k ] = tostring( v )
        end
    end

    params[ 'wait' ] = 'true'

    local timeout = opts.timeout or self._read_timeout
    local resp, err, msg

    if timeout <= 0 then
        while true do
            resp, err, msg = request( self, self:keys_endpoint() .. key,
                                            'GET', params, timeout )
            if resp ~= nil then
                break
            end

            ngx.log( ngx.INFO, err .. ' : ' .. msg )
            self:next_host()
        end
    else
        while true do
            local st = ngx.now() * 1000
            resp, err, msg = request( self, self:keys_endpoint() .. key,
                                            'GET', params, timeout )
            if resp ~= nil then
                break
            end

            timeout = timeout - ( ngx.now() * 1000 - st )
            if timeout <= 0 then
                err, msg = "TimeoutError", "timeout"
                break
            end

            ngx.log( ngx.INFO, err .. ' : ' .. msg )
            self:next_host()
        end
    end

    if resp then
        resp, err, msg = self:_handle_server_response( resp )
    end

    if err then
        ngx.log( ngx.INFO, err .. ' : ' .. msg )
        return nil, err, msg
    end

    return self:_result_from_response( resp )
end

function _M.machines( self )

    local resp, err, msg = self:api_execute( self._version_prefix .. '/machines', 'GET' )
    if err then
        ngx.log( ngx.INFO, err .. ' : ' .. msg )
        return nil, err, msg
    end

    local machines = {}
    for _, v in pairs( strutil.split( resp.body, ',' ) ) do
        table.insert( machines, strutil.strip( v ) )
    end

    return machines
end

function _M.version( self )

    local resp, err, msg = self:api_execute( '/version', 'GET' )
    if err then
        ngx.log( ngx.INFO, err .. ' : ' .. msg )
        return nil, err, msg
    end

    return self:_result_from_response( resp ).data
end

return _M

