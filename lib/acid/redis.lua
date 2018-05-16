local resty_redis = require("resty.redis")
local strutil = require("acid.strutil")
local rpc_logging = require("acid.rpc_logging")

local to_str = strutil.to_str

local _M = {}
local mt = { __index = _M }

local function get_redis_cli(self)
    local redis_cli, err_msg = resty_redis:new()
    if redis_cli == nil then
        return nil, nil, 'NewRedisError', err_msg
    end

    redis_cli:set_timeout(self.timeout)

    local ok, err_msg = redis_cli:connect( self.ip, self.port )
    if ok == nil then
        return nil, 'ConnectRedisError', err_msg
    end

    return redis_cli
end

local function run_redis_cmd(self, cmd, ...)
    local args = {...}

    local log_entry = rpc_logging.new_entry('redis', {
            ip   = self.ip,
            port = self.port,
            uri  = to_str(cmd, ':', args[1])})

    local redis_cli, err_code, err_msg = get_redis_cli(self)
    rpc_logging.set_time(log_entry, 'upstream', 'conn')
    if err_code ~= nil then
        rpc_logging.set_err(log_entry, err_code)
        rpc_logging.add_log(log_entry)
        return nil, err_code, err_msg
    end

    local val, err_msg = redis_cli[cmd](redis_cli, ... )
    rpc_logging.set_time(log_entry, 'upstream', 'recv')

    if val == nil or err_msg ~= nil then
        rpc_logging.set_err(log_entry, err_msg)
        rpc_logging.add_log(log_entry)
        return nil, 'RunRedisCMDError', to_str('cmd: ', cmd, ', err: ', err_msg)
    end

    local itv = log_entry.upstream.time.conn + log_entry.upstream.time.recv
    if  itv >= self.min_log_time then
        rpc_logging.add_log(log_entry)
    end

    if self.keepalive_timeout ~= nil then
        redis_cli:set_keepalive(self.keepalive_timeout, self.keepalive_size)
    end

    return val
end

function _M.new(_, ip, port, opts)
    local opts = opts or {}

    local obj = {
        ip = ip,
        port = port,
        timeout = opts.timeout or 1000,

        retry_count = opts.retry_count or 1,

        keepalive_size = opts.keepalive_size,
        keepalive_timeout = opts.keepalive_timeout,

        min_log_time = opts.min_log_time or 0.005,
    }

    return setmetatable( obj, mt )
end

function _M.retry(self, n)
    self.retry_count = n

    return self
end

function _M.transaction(self, cmds)
    local ok, err_code, err_msg = self:multi()
    if err_code ~= nil then
        return nil, err_code, err_msg
    end

    if ok ~= 'OK' then
        return nil, 'RunRedisCMDError', 'multi no reply with the string OK'
    end

    for _, cmd_and_args in ipairs(cmds) do
        local cmd, cmd_args = unpack(cmd_and_args)
        local rst, err_code, err_msg = self[cmd](self, unpack(cmd_args or {}))
        if err_code ~= nil then
            self['discard'](self)
            return nil, err_code, err_msg
        end

        if rst ~= 'QUEUED' then
            self['discard'](self)
            return nil, 'RunRedisCMDError', cmd .. ' no reply with the string QUEUED'
        end
    end

    local multi_rst, err_code, err_msg = self['exec'](self)
    if err_code ~= nil then
        self['discard'](self)
        return nil, err_code, err_msg
    end

    return multi_rst
end

setmetatable(_M, {__index = function(_, cmd)
    local method = function (self, ...)
            local val, err_code, err_msg

            for ii = 1, self.retry_count, 1 do
                val, err_code, err_msg = run_redis_cmd(self, cmd, ...)
                if err_code == nil then
                    return val, nil, nil
                end

                ngx.log(ngx.WARN, to_str('redis retry ', ii, ' error. ', err_code, ':', err_msg))
            end

            return nil, err_code, err_msg
        end

    _M[cmd] = method
    return method
end})

return _M
