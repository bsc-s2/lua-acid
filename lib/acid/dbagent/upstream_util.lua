local bisect = require('acid.bisect')
local conf_util = require('acid.dbagent.conf_util')
local tableutil = require('acid.tableutil')

local repr = tableutil.repr

local _M = {}


local function cmp_shard(shard_fields_value, shard)
    return tableutil.cmp_list(shard_fields_value, shard.from)
end


local function get_shard(conf, subject, shard_fields_value)
    local shards = conf.tables[subject]

    if shards == nil then
        return nil, 'NotShardError', string.format(
                'shard not found in conf for subject: %s', subject)
    end

    local _, index = bisect.search(shards, shard_fields_value,
                                   {cmp=cmp_shard})

    if index < 1 or index > #shards then
        return nil, 'ShardIndexErrr', string.format(
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
        table.insert(shard_fields_value, api_ctx.args[field_name])
    end

    if conf_util.conf == nil then
        ngx.log(ngx.INFO, 'conf ##: conf not inited, init conf first')
        local _, err, errmsg = conf_util.init_conf()
        if err ~= nil then
            return nil, err, errmsg
        end
    end

    api_ctx.conf = conf_util.conf.value

    local shard, err, errmsg = get_shard(api_ctx.conf, api_ctx.subject,
                                         shard_fields_value)
    if err ~= nil then
        return nil, err, errmsg
    end

    api_ctx.curr_shard = shard.curr_shard
    api_ctx.next_shard = shard.next_shard

    local table_name = api_ctx.subject
    if next(api_ctx.curr_shard.from) ~= nil then
        table_name = string.format('%s_%s', table_name,
                                   table.concat(api_ctx.curr_shard.from, '_'))
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
