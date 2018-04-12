local bisect = require('acid.bisect')
local upstream_conf = require('acid.dbagent.upstream_conf')
local tableutil = require('acid.tableutil')
local dbagent_conf = require('dbagent_conf')

local repr = tableutil.repr
local string_format = string.format
local table_insert = table.insert
local table_concat = table.concat

local _M = {
    upstream_config = nil,
    locked = 0,
}


function _M.init_upstream_config()
    if _M.upstream_config ~= nil then
        return _M.upstream_config, nil, nil
    end

    for _ = 1, 100 do
        if _M.locked == 1 then
            ngx.sleep(0.02)
        else
            break
        end
    end

    if _M.locked == 0 then
        _M.locked = 1
    else
        ngx.log(ngx.ERR, 'conf ##: failed to get lock in 2 seconds')
        return nil, 'GetLockError', 'failed to get lock'
    end

    if _M.upstream_config ~= nil then
        _M.locked = 0
        return _M.upstream_config, nil, nil
    end

    ngx.log(ngx.INFO, 'conf ##: init upstream config with lock')

    local upstream_config, err, errmsg = upstream_conf.new(
            dbagent_conf.fetch_upstream_conf)
    if err ~= nil then
        _M.locked = 0
        return nil, err, errmsg
    end

    _M.locked = 0
    _M.upstream_config = upstream_config

    return _M.upstream_config, nil, nil
end


local function cmp_shard(shard_fields_value, shard)
    return tableutil.cmp_list(shard_fields_value, shard.from)
end


local function get_shard(conf, subject, shard_fields_value)
    local shards = conf.tables[subject]

    if shards == nil then
        return nil, 'NoShardError', string_format(
                'shard not found in conf for subject: %s', subject)
    end

    local _, index = bisect.search(shards, shard_fields_value,
                                   {cmp=cmp_shard})

    if index < 1 then
        return nil, 'ShardIndexErrr', string_format(
                'get invalid shard index: %d, with: %s',
                index, repr({shards, shard_fields_value}))
    end

    return {
        curr_shard = shards[index],
        next_shard = shards[index + 1],
    }, nil, nil
end


function _M.get_upstream(api_ctx)
    local shard_fields = api_ctx.subject_model.shard_fields

    local shard_fields_value = {}
    for _, field_name in ipairs(shard_fields) do
        table_insert(shard_fields_value, api_ctx.args[field_name])
    end

    local _, err, errmsg = _M.init_upstream_config()
    if err ~= nil then
        return nil, err, errmsg
    end

    api_ctx.conf = _M.upstream_config.conf.value

    local shard, err, errmsg = get_shard(api_ctx.conf, api_ctx.subject,
                                         shard_fields_value)
    if err ~= nil then
        return nil, err, errmsg
    end

    api_ctx.curr_shard = shard.curr_shard
    api_ctx.next_shard = shard.next_shard

    local table_name = api_ctx.subject
    if next(api_ctx.curr_shard.from) ~= nil then
        table_name = string_format('%s_%s', table_name,
                                   table_concat(api_ctx.curr_shard.from, '_'))
    end

    local upstream = {
        db_name = api_ctx.curr_shard.db,
        table_name = table_name,
    }

    api_ctx.upstream = upstream

    return true, nil, nil
end


function _M.get_connection(api_ctx)
    local db_name = api_ctx.upstream.db_name
    local dbs = api_ctx.conf.dbs
    local rw = api_ctx.action_model.rw

    local connections = dbs[db_name][rw]

    if rw == 'r' and #connections == 0 then
        connections = dbs[db_name].w
    end

    local connection = tableutil.random(connections, 1)[1]

    return connection, nil, nil
end


return _M
