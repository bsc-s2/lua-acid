local acid_json = require("acid.json")
local acid_nwr = require("acid.nwr")
local strutil = require("acid.strutil")
local tableutil = require("acid.tableutil")
local redis_chash = require("acid.redis_chash")
local aws_authenticator = require("resty.awsauth.aws_authenticator")

local _M = { _VERSION = "0.1" }
local mt = { __index = _M }

local to_str = strutil.to_str

local ERR_CODE = {
    NotFound        = ngx.HTTP_NOT_FOUND,
    InvalidRequest  = ngx.HTTP_BAD_REQUEST,
    InvalidCommand  = ngx.HTTP_FORBIDDEN,
    QuorumNotEnough = ngx.HTTP_SERVICE_UNAVAILABLE,
    RequestForbidden = ngx.HTTP_FORBIDDEN,
    InvalidSignature = ngx.HTTP_FORBIDDEN,
}

-- http method, count of args, need value args, optional args name
local redis_cmd_model = {
    -- get(key)
    GET  = {'GET', 1, false, {}},

    -- set(key, val, expire=nil)
    SET  = {'PUT', 2, true, {'expire'}},

    -- hget(hashname, hashkey)
    HGET = {'GET', 2, false, {}},

    -- hset(hashname, hashkey, val, expire=nil)
    HSET = {'PUT', 3, true, {'expire'}},
}

local redis_cmd_names = tableutil.keys(redis_cmd_model)

local function get_secret_key(access_key, secret_key)
    return function(ctx)
        if ctx.access_key ~= access_key then
            return nil, 'InvalidAccessKey', 'access key does not exists: ' .. ctx.access_key
        end

        return secret_key
    end
end

local function check_auth(self)
    if ngx.var.server_addr == '127.0.0.1'
        or self.access_key == nil
        or self.secret_key == nil then
        return
    end

    local authenticator = aws_authenticator.new(self.get_secret_key)
    local ctx, err_code, err_msg = authenticator:authenticate()
    if err_code ~= nil then
        ngx.log(ngx.INFO, err_code, ':', err_msg)
        return nil, 'InvalidSignature', 'signature is not correct'
    end

    if ctx.anonymous == true then
        return nil, 'RequestForbidden', 'anonymous user are not allowed'
    end
end

local function output(rst, err_code, err_msg)
    local status, body, headers = 200, '', {}

    local request_id = ngx.var.requestid

    if err_code ~= nil then
        ngx.log( ngx.WARN, "requestid: ", request_id,
             " err_code: ", err_code, " err_msg: ", err_msg )

        status = ERR_CODE[err_code] or ngx.HTTP_BAD_REQUEST

        headers["Content-Type"] = "application/json"

        local Error = {
                  Code      = err_code,
                  Message   = err_msg,
                  RequestId = request_id,
                }
        body = acid_json.enc( Error )
    else
        rst = rst or {}

        headers['X-REDIS-ADDR'] = rst.addr
        body = rst.value or ''
    end

    ngx.header["request-id"] = ngx.var.requestid
    headers['Content-Length'] = #body

    ngx.status = status

    for k, v in pairs(headers) do
        ngx.header[k] = v
    end

    ngx.say(body)
    ngx.eof()
    ngx.exit(ngx.HTTP_OK)
end

local function read_cmd_value()
    local headers = ngx.req.get_headers()
    local content_length = tonumber(headers['content-length'])

    if content_length == nil then
        return nil, 'InvalidRequest', 'Content-Length is nil'
    elseif content_length == 0 then
        return ''
    end

    ngx.req.read_body()
    local value = ngx.req.get_body_data()
    if value == nil then
        return nil, 'InvalidRequest', 'Invalid request body'
    end

    return value
end

local function get_cmd_args()
    local uri_regex = '^/redisproxy/v\\d+/(\\S+?)/(\\S+)$'
    local urilist = ngx.re.match(ngx.var.uri, uri_regex, 'o')
    if urilist == nil then
        return nil, 'InvalidRequest', 'uri must like:'.. uri_regex
    end

    local cmd = urilist[1]
    local cmd_args = strutil.split(urilist[2], '/')

    local cmd_model = redis_cmd_model[cmd]
    if cmd_model == nil then
        return nil, 'InvalidCommand', to_str('just support: ', redis_cmd_names)
    end

    local http_method, nargs, needed_value, _ = unpack(cmd_model)

    if http_method ~= ngx.var.request_method then
        return nil, 'InvalidRequest',
            to_str(cmd, ' cmd request method must be ', http_method)
    end

    if needed_value then
        local cmd_val, err_code, err_msg = read_cmd_value()
        if err_code ~= nil then
            return nil, err_code, err_msg
        end

        table.insert(cmd_args, cmd_val)
    end

    if #(cmd_args) ~= nargs then
        return nil, 'InvalidCommand', to_str(cmd, ' need ', nargs, ' args')
    end

    local qs = ngx.req.get_uri_args()

    return {
        cmd = string.lower(cmd),
        cmd_args = cmd_args,
        expire = tonumber(qs.expire),
        nwr = {
            tonumber(qs.n) or 1,
            tonumber(qs.w) or 1,
            tonumber(qs.r) or 1,
        },
    }
end

function _M.new(_, access_key, secret_key, get_redis_servers, opts)
    local obj = {
        access_key = access_key,
        secret_key = secret_key,
        get_secret_key = get_secret_key(access_key, secret_key),
        redis_chash = redis_chash:new(
            "cluster_redisproxy", get_redis_servers, opts)
    }

    return setmetatable( obj, mt )
end

function _M.proxy(self)
    local _, err_code, err_msg = check_auth(self)
    if err_code ~= nil then
        return output(nil, err_code, err_msg)
    end

    local args, err_code, err_msg = get_cmd_args()
    if err_code ~= nil then
        return output(nil, err_code, err_msg)
    end

    local cmd, cmd_args, nwr, expire =
        args.cmd, args.cmd_args, args.nwr, args.expire

    local nok, rst, err_code, err_msg
    if cmd == 'set' or cmd == 'hset' then
        nok, err_code, err_msg =
            self.redis_chash[cmd](self.redis_chash, cmd_args, nwr[1], expire)
        if err_code == nil then
            _, err_code, err_msg = acid_nwr.assert_w_ok(nwr, nok)
        end
    else
        rst, err_code, err_msg = self.redis_chash[cmd](self.redis_chash, cmd_args, nwr[3])
    end

    return output(rst, err_code, err_msg)
end

return _M
