local strutil         = require("acid.strutil")
local tableutil       = require("acid.tableutil")
local acid_redis      = require("acid.redis")
local acid_json       = require("acid.json")
local acid_chash_conf = require("acid.chash_conf")

local to_str = strutil.to_str
local str_split = strutil.split

local _M = { _VERSION = "0.1" }
local mt = { __index = _M }

local redis_conf = {}


local function get_redis_addrs(self, k, n)
    local chash = self.chash_conf:get_chash()
    if chash == nil then
        return {}
    end

    local addrs, err_code, err_msg = chash:choose_server(k, {nr_choose=n})
    if err_code ~= nil then
        return nil, err_code, err_msg
    end

    if self.optimize_choose_servers ~= nil then
        return self.optimize_choose_servers(addrs)
    end

    return addrs
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
            ngx.log(ngx.INFO, to_str('transaction runs hset cmd result: ', multi_rst))
            return nil, 'RunRedisCMDError', 'transaction runs hset cmd result error'
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

local function is_merge_cmd(cmd)
    if cmd == 'hgetall' or cmd == 'hkeys' then
        return true
    end

    return false
end

local function merge_result(cmd, addr, values)
    local rst = {}
    local err
    if cmd == "hkeys" then
        for _, val in ipairs(values) do
            for _, k in ipairs(val) do
                if not tableutil.has(rst, k) then
                    table.insert(rst, k)
                end
            end
        end
    end

    if cmd == "hgetall" then
        for _, val in ipairs(values) do
            for i=1, #(val), 2 do
                local k = val[i]
                local v = val[i + 1]
                if rst[k] == nil then
                    v, err = acid_json.dec(v)
                    if err ~= nil then
                        ngx.log(ngx.ERR, to_str("hgetall json decode the result error:", err))
                        return nil, "JsonDecodeError", err
                    end
                    rst[k] = v
                end
            end
        end
    end

    return {value=rst, addr=addr}
end

local function run_xget_cmd(self, cmd, cmd_args, n)
    local addrs, err_code, err_msg = get_redis_addrs(self, cmd_args[1], n)
    if err_code ~= nil then
        return nil, err_code, err_msg
    end

    local values = {}
    local first_addr
    for _, addr in ipairs(addrs) do
        local ipport = str_split(addr, ':')

        local val, err_code, err_msg = run_cmd_on_redis(ipport[1], ipport[2], cmd, cmd_args)
        if err_code ~= nil then
            ngx.log(ngx.ERR, to_str(cmd, ' value to ', addr,
                'error. err_code=', err_code, ', err_msg=', err_msg))
        end

        if val ~= nil and val ~= ngx.null then
            if first_addr == nil then
                first_addr = addr
            end
            if not is_merge_cmd(cmd) then
                return {value=val, addr=addr}
            else
                table.insert(values, val)
            end
        end
    end

    if is_merge_cmd(cmd) and #values > 0 then
        return merge_result(cmd, first_addr, values)
    end

    return nil, 'NotFound', to_str('cmd=', cmd, ', args=', cmd_args)
end

local function run_xset_cmd(self, cmd, cmd_args, n, pexpire)
    local addrs, err_code, err_msg = get_redis_addrs(self, cmd_args[1], n)
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

    return nok
end

local function run_xdel_cmd(self, cmd, cmd_args, n)
    local addrs, err_code, err_msg = get_redis_addrs(self, cmd_args[1], n)
    if err_code ~= nil then
        return 0, err_code, err_msg
    end

    local nok = 0
    local err_code, err_msg
    local n_failed = 0

    for _, addr in ipairs(addrs) do
        local ipport = str_split(addr, ':')

        _, err_code, err_msg =
            run_cmd_on_redis(ipport[1], ipport[2], cmd, cmd_args)

        if err_code ~= nil then
            n_failed = n_failed + 1
        else
            nok = nok + 1
        end
    end

    return nok, err_code, err_msg
end

function _M.del(self, args, n)
    return run_xdel_cmd(self, 'del', args, n)
end

function _M.hdel(self, args, n)
    return run_xdel_cmd(self, 'hdel', args, n)
end

function _M.hget(self, args, n)
    return run_xget_cmd(self, 'hget', args, n)
end

function _M.hkeys(self, args, n)
    local rst, err, errmsg = run_xget_cmd(self, 'hkeys', args, n)
    if err ~= nil then
        return nil, err ,errmsg
    end

    local json_val, err = acid_json.enc(rst.value)
    if err ~= nil then
        ngx.log(ngx.ERR, "hkeys json encode error:", err)
        return nil, "JsonEncodeError", err
    end

    rst.value = json_val
    return rst
end

function _M.hvals(self, args, n)
    -- can not merge results in different nodes, use hgetall
    local rst, err, errmsg = run_xget_cmd(self, 'hgetall', args, n)
    if err ~= nil then
        return nil, err ,errmsg
    end

    local vals = {}
    for k, v in pairs(rst.value) do
        table.insert(vals, v)
    end

    local json_vals, err = acid_json.enc(vals)
    if err ~= nil then
        ngx.log(ngx.ERR, "hvals json encode error:", err)
        return nil, "JsonEncodeError", err
    end

    rst.value = json_vals
    return rst
end

function _M.hgetall(self, args, n)
    local rst, err, errmsg = run_xget_cmd(self, 'hgetall', args, n)
    if err ~= nil then
        return nil, err ,errmsg
    end

    local json_val, err = acid_json.enc(rst.value)
    if err ~= nil then
        ngx.log(ngx.ERR, "hgetall json encode error:", err)
        return nil, "JsonEncodeError", err
    end

    rst.value = json_val
    return rst
end

function _M.hset(self, args, n, expire)
    return run_xset_cmd(self, 'hset', args, n, expire)
end

function _M.get(self, args, n)
    return run_xget_cmd(self, 'get', args, n)
end

function _M.set(self, args, n, expires)
    return run_xset_cmd(self, 'set', args, n, expires)
end

function _M.new( _, name, get_redis_servers, opts)
    local opts = opts or {}

    if redis_conf[name] == nil then
        redis_conf[name] = acid_chash_conf.new({get_servers=get_redis_servers})
    end

    local obj = {
        chash_conf = redis_conf[name],
        optimize_choose_servers = opts.optimize_choose_servers,
    }

    return setmetatable(obj, mt)
end

return _M
