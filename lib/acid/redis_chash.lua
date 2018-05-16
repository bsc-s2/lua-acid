local strutil = require("acid.strutil")
local tableutil = require("acid.tableutil")
local acid_redis = require("acid.redis")
local ngx_timer = require("acid.ngx_timer")
local acid_chash = require( "acid.chash" )
local semaphore = require("ngx.semaphore")

local to_str = strutil.to_str
local str_split = strutil.split

local _M = {}
local mt = { __index = _M }

--redis_conf = {
    --['cluster_redis'] = {
        --expires = 0,
        --updates = 0,
        --semaphore = semaphore.new(1),
        --servers = {},
        --chash = nil,
        --get_redis_servers = get_redis_servers,
    --}
--}
--
local redis_conf = {}
local servers_expires_seconds = 600
local servers_updates_seconds = 300

local function update_chash(self)
    local conf = self.conf

    local _, err = conf.semaphore:wait(1)
    if err then
        ngx.log(ngx.INFO, err, " other timer is updating servers")
        return
    end

    local now = ngx.time()
    if now < conf.updates then
        ngx.log(ngx.INFO, "servers were updated by other timer")

        conf.semaphore:post(1)
        return
    end

    local servers = self.conf.get_redis_servers()
    if servers == nil then
        conf.semaphore:post(1)
        return
    end

    local now = ngx.time()
    if conf.chash == nil then
       conf.chash = acid_chash.new(servers)
    else
        conf.chash:update_server(servers)
    end

    conf.servers = servers

    conf.expires = now + servers_expires_seconds
    conf.updates = now + servers_updates_seconds

    ngx.log(ngx.INFO, "consistent hash built")
    conf.semaphore:post(1)
end

local function get_chash(self)
    local conf = self.conf
    local now = ngx.time()

    if now >= conf.updates then
        if conf.updates == 0 then
            update_chash(self)
        else
            ngx_timer.at(0.01, update_chash, self)
        end
    end

    if now < conf.expires then
        return conf.chash
    else
        ngx.log(ngx.ERR, "consistent servers was expired")
    end

    return nil
end

local function optimize_choose_servers(addrs, least)
    return addrs
end

local function get_redis_addrs(self, k, n, least)
    local chash = get_chash(self)
    if chash == nil then
        return {}
    end

    local addrs, err_code, err_msg = chash:choose_server(k, {nr_choose=n})
    if err_code ~= nil then
        return nil, err_code, err_msg
    end

    return self.conf.optimize_choose_servers(addrs, least)
end

local function run_cmd_on_redis(ip, port, cmd, cmd_args, pexpire)
    local r_opts = {
        retry_count = 1,
        tiemout = 1000,
        keepalive_timeout = 10 * 1000,
        keepalive_size = 64,
        min_log_time = 0,
    }

    local redis_cli = acid_redis:new(ip, port, r_opts)

    if pexpire ~= nil and cmd == 'hset' then
        local cmd_and_args = {
            {cmd, cmd_args},
            {'pexpire', {cmd_args[1], pexpire}},
        }

        local multi_rst, err_code, err_msg = redis_cli:transaction(cmd_and_args)
        if err_code ~= nil then
            return nil, err_code, err_msg
        end

        if (tonumber(multi_rst[1]) ~= 1 or tonumber(multi_rst[1]) ~= 0)
            and tonumber(multi_rst[2]) ~= 1 then
            return nil, 'RunRedisCMDError', 'transaction HSET error'
        end

        return
    end

    if pexpire ~= nil then
        cmd_args = tableutil.dup(cmd_args, true)
        table.insert(cmd_args, 'PX')
        table.insert(cmd_args, pexpire)
    end

    return redis_cli[cmd](redis_cli, unpack(cmd_args))
end

local function run_xget_cmd(self, cmd, cmd_args, n, r)
    local addrs, err_code, err_msg = get_redis_addrs(self, cmd_args[1], n, r)
    if err_code ~= nil then
        return nil, err_code, err_msg
    end

    for nread, addr in ipairs(addrs) do
        local ipport = str_split(addr, ':')

        local val, err_code, err_msg = run_cmd_on_redis(ipport[1], ipport[2], cmd, cmd_args)
        if err_code ~= nil then
            ngx.log(ngx.ERR, to_str(cmd, ' value to ', addr,
                'error. err_code=', err_code, ', err_msg=', err_msg))
        end

        if val ~= nil and val ~= ngx.null then
            return {value=val, addr=addr}
        end

        if nread > r then
            break
        end
    end

    return nil, 'NotFound', to_str('cmd=', cmd, ', args=', cmd_args)
end

local function run_xset_cmd(self, cmd, cmd_args, n, w, pexpire)
    local addrs, err_code, err_msg = get_redis_addrs(self, cmd_args[1], n, w)
    if err_code ~= nil then
        return nil, err_code, err_msg
    end

    local nok = 0
    for _, addr in ipairs(addrs) do
        local ipport = str_split(addr, ':')

        local _, err_code, err_msg =
            run_cmd_on_redis(ipport[1], ipport[2], cmd, cmd_args, pexpire)
        if err_code == nil then
            nok = nok + 1
        else
            ngx.log(ngx.ERR, to_str(cmd, ' value to ', addr,
                'error. err_code=', err_code, ', err_msg=', err_msg))
        end
    end

    if nok < w then
        return nil, "QuorumNotEnough", to_str('w=', w, ', ok=', nok)
    end
end

function _M.hget(self, args, n, r)
    return run_xget_cmd(self, 'hget', args, n, r)
end

function _M.hset(self, args, n, w, expire)
    return run_xset_cmd(self, 'hset', args, n, w, expire)
end

function _M.get(self, args, n, r)
    return run_xget_cmd(self, 'get', args, n, r)
end

function _M.set(self, args, n, w, expires)
    return run_xset_cmd(self, 'set', args, n, w, expires)
end

function _M.new( _, name, get_redis_servers, opts)
    local opts = opts or {}

    if redis_conf[name] == nil then
        redis_conf[name] = {
            expires = 0,
            updates = 0,
            semaphore = semaphore.new(1),
            servers = {},
            chash = nil,
            get_redis_servers = get_redis_servers,
            optimize_choose_servers =
                opts.optimize_choose_servers or optimize_choose_servers,
        }
    end

    local obj = {
        conf = redis_conf[name],
    }

    return setmetatable( obj, mt )
end

return _M
