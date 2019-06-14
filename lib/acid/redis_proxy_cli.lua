--example, how to use
--  local opts = {
--      nwr = {3, 2, 2},
--      ak_sk = {'accesskey', 'secret_key'},
--      timeouts = {1, 1, 1},
--  }
--  local cli = redis_proxy_cli:new({{ip, port}}, opts)
--
--  "retry(another N times) is optional"
--  cli:get(key, retry)
--  E.g. cli:get('key1')
--  E.g. cli:get('key1', 1)
--
--  "expire(msec) and retry(another N times) are optional"
--  cli:set(key, val, expire, retry)
--  E.g. cli:set('key1', 'val1')
--  E.g. cli:set('key1', 'val1', 1000)
--  E.g. cli:set('key1', 'val1', nil, 2)
--  E.g. cli:set('key1', 'val1', 1000, 2)
--
--  "retry(another N times) is optional"
--  cli:hget(hashname, hashkey, retry)
--  E.g. cli:hget('hashname1', 'hashkey1')
--  E.g. cli:hget('hashname1', 'hashkey1', 2)
--
--  "expire(msec) and retry(another N times) are optional"
--  cli:hset(hashname, hashkey, val, expire, retry)
--  E.g. cli:hset('hashname1', 'hashkey1', 'val')
--  E.g. cli:hset('hashname1', 'hashkey1', 'val', 1000)
--  E.g. cli:hset('hashname1', 'hashkey1', 'val', nil, 2)
--  E.g. cli:hset('hashname1', 'hashkey1', 'val', 1000, 2)

local http_cli   = require("acid.httpclient")
local aws_signer = require('resty.awsauth.aws_signer')
local tableutil  = require('acid.tableutil')
local strutil    = require('acid.strutil')
local json       = require('acid.json')

local _M = { _VERSION = '1.0' }
local mt = { __index  = _M }

local to_str = strutil.to_str

-- cmd: {"redis operation", "http method", "args count", "optional args names"}
local cmds = {
    get     = {"get",     "GET",    2, {}},
    set     = {"set",     "PUT",    4, {"expire"}},
    hget    = {"hget",    "GET",    3, {}},
    hset    = {"hset",    "PUT",    5, {"expire"}},
    hkeys   = {"keys",    "GET",    2, {}},
    hvals   = {"hvals",   "GET",    2, {}},
    hgetall = {"hgetall", "GET",    2, {}},
    delete  = {"del",     "DELETE", 2, {}},
    hdel    = {"hdel",    "DELETE", 3, {}},
}


local function _sign_req(rp_cli, req)
    if rp_cli.access_key == nil or rp_cli.secret_key == nil then
        return nil, nil, nil
    end

    local signer, err, errmsg = aws_signer.new(rp_cli.access_key,
                                               rp_cli.secret_key,
                                               {default_expires = 600})
    if err ~= nil then
        return nil, err, errmsg
    end

    local opts = {
        query_auth = true,
        sign_payload = (req['body'] ~= nil),
    }

    return signer:add_auth_v4(req, opts)
end


local function _make_req_uri(rp_cli, params, opts, qs_values)
    local path = tableutil.extends({rp_cli.ver}, params)

    local qs_list = {
        string.format('n=%s', rp_cli.n),
        string.format('w=%s', rp_cli.w),
        string.format('r=%s', rp_cli.r),
    }

    for i = 1, #opts do
        if opts[i] ~= nil and qs_values[i] ~= nil then
            table.insert(qs_list, string.format('%s=%s', opts[i], qs_values[i]))
        end
    end

    return string.format(
        '%s?%s',
        table.concat(path, '/'),
        table.concat(qs_list, '&')
    )
end


local function _req(rp_cli, ip, port, request)
    local req = tableutil.dup(request, true)
    req['headers'] = req['headers'] or {}

    if req['headers']['Host'] == nil then
        req['headers']['Host'] = string.format('%s:%s', ip, port)
    end

    if req['body'] ~= nil then
        req['headers']['Content-Length'] = #req['body']
    end

    local _, err, errmsg = _sign_req(rp_cli, req)
    if err ~= nil then
        return nil, err, errmsg
    end

    local cli = http_cli:new(ip, port, rp_cli.timeouts)
    local req_opts = {
        method  = req['verb'],
        headers = req['headers'],
        body    = req['body'],
    }

    local _, err, errmsg = cli:request(req['uri'], req_opts)
    if err ~= nil then
        return nil, err, errmsg
    end

    local res, err, errmsg = cli:read_body(100*1024*1024)
    if err ~= nil then
        return nil, err, errmsg
    end

    if cli.status == 404 then
        return nil, 'KeyNotFoundError', to_str('Uri:', req['uri'])

    elseif cli.status ~= 200 then
        return nil, 'ServerResponseError', to_str('Res:', res, ' Uri:', req['uri'])

    end

    return res, nil, nil
end


local function can_proxy(proxy_hosts, verb, err)
    if #proxy_hosts == 0 then
        return false
    end

    if verb == 'PUT' and err == nil then
        return true
    end

    if verb == 'GET' and err ~= nil then
        return true
    end

    return false
end


local function _send_req(rp_cli, request)
    local rst, err, errmsg
    for _, h in ipairs(rp_cli.hosts) do
        local ip, port = h[1], h[2]
        rst, err, errmsg = _req(rp_cli, ip, port, request)
        if err == nil then
            break
        end
    end

    if not can_proxy(rp_cli.proxy_hosts, request.verb, err) then
        return rst, err, errmsg
    end

    for _, hosts in ipairs(rp_cli.proxy_hosts) do
        ngx.log(ngx.INFO, to_str("send req to proxy hosts:", hosts))
        for _, h in ipairs(hosts) do
            local ip, port = h[1], h[2]
            rst, err, errmsg = _req(rp_cli, ip, port, request)
            if err == nil then
                break
            end
        end

        if not can_proxy(rp_cli.proxy_hosts, request.verb, err) then
            break
        end
    end

    ngx.log(ngx.INFO, to_str("finish send req to proxy hosts error:", err, ",", errmsg))
    return rst, err, errmsg
end


local function _parse_args(cmd, args, args_cnt, http_mtd, opts)

    local path = {string.upper(cmd)}

    -- (args count) - (#opts) - "retry"
    local path_args_cnt = args_cnt - #opts - 1
    if http_mtd == "PUT" then
        -- remove body
        path_args_cnt = path_args_cnt - 1
    end

    for _ = 1, path_args_cnt do
        table.insert(path, args[1])
        table.remove(args, 1)
    end

    local body
    if http_mtd == "PUT" then
        body = args[1]
        table.remove(args, 1)
    end

    local retry
    if #args > #opts then
        retry = args[#args]
        table.remove(args, #args)
    end

    return path, args, body, retry
end


local function _do_cmd(rp_cli, cmd, ...)
    ngx.log(ngx.INFO, to_str("start do cmd:", cmd))

    local cmd_info = cmds[cmd]
    if cmd_info == nil then
        local support_keys = tableutil.keys(cmds)
        return nil, 'NotSupportCmd', to_str(cmd, ' not in ', support_keys)
    end

    local args = {...}
    local http_mtd, args_cnt, opts = cmd_info[2], cmd_info[3], cmd_info[4]
    local path, qs_values, body, retry = _parse_args(cmd_info[1], args, args_cnt, http_mtd, opts)

    local req = {
        verb = http_mtd,
        uri = _make_req_uri(rp_cli, path, opts, qs_values),
    }

    local res, err, errmsg
    if body ~= nil then
        req['body'], err = json.enc(body)
        if err ~= nil then
            return nil, err, to_str("json encode error:", body)
        end
    end

    retry = retry or 0
    for _ = 1, retry + 1 do
        res, err, errmsg = _send_req(rp_cli, req)
        if err == nil then
            break
        end
    end

    if err ~= nil then
        return nil, err, errmsg
    end

    if http_mtd == 'GET' then
        res, err = json.dec(res)
        if err ~= nil then
            return nil, err, to_str("json decode error:", res)
        end
        return res, nil, nil
    end

    return nil, nil, nil
end


function _M.new(_, hosts, opts)
    opts = opts or {}
    local nwr = opts.nwr or {3, 2, 2}
    local ak_sk = opts.ak_sk or {}
    local n, w, r = nwr[1], nwr[2], nwr[3]
    local access_key, secret_key = ak_sk[1], ak_sk[2]

    return setmetatable({
        ver         = '/redisproxy/v1',
        hosts       = hosts,
        proxy_hosts = opts.proxy_hosts or {},
        n           = n,
        w           = w,
        r           = r,
        access_key  = access_key,
        secret_key  = secret_key,
        timeouts    = opts.timeouts,
    }, mt)
end


for cmd, _ in pairs(cmds) do
    _M[cmd] = function (self, ...)
        return _do_cmd(self, cmd, ...)
    end
end


return _M
