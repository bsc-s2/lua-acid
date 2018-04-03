local api_util = require('acid.dbagent.api_util')
local arg_util = require('acid.dbagent.arg_util')
local convertor = require('acid.dbagent.convertor')
local model_util = require('acid.dbagent.model_util')
local mysql_util = require('acid.dbagent.mysql_util')
local sql_util = require('acid.dbagent.sql_util')
local upstream_util = require('acid.dbagent.upstream_util')
local json = require('acid.json')
local dbagent_conf = require('dbagent_conf')


local _M = {}


local function set_shard_header(api_ctx)
    local prefix = dbagent_conf.shard_header_prefix or 'x-acid-'
    ngx.header[prefix .. 'shard-current'] = json.enc(api_ctx.curr_shard.from)
    ngx.header[prefix .. 'shard-next'] = json.enc((api_ctx.next_shard or {}).from)
end


local function _do_api(api_ctx)
    local _, err, errmsg = api_util.extract_request_info(api_ctx)
    if err ~= nil then
        return nil, 'ExtractError', string.format(
                'failed to extract request info: %s, %s', err, errmsg)
    end

    local _, err, errmsg = model_util.choose_model(api_ctx)
    if err ~= nil then
        return nil, 'PickModelError', string.format(
                'failed to choose model: %s, %s', err, errmsg)
    end

    local _, err, errmsg = arg_util.set_default(api_ctx)
    if err ~= nil then
        return nil, 'SetDefaultError', string.format(
                'failed to set default: %s, %s', err, errmsg)
    end

    local _, err, errmsg = arg_util.check(api_ctx)
    if err ~= nil then
        return nil, 'CheckArgumentError', string.format(
                'failed to check argument: %s, %s', err, errmsg)
    end

    local _, err, errmsg = convertor.convert_arg(api_ctx)
    if err ~= nil then
        return nil, 'ConvertArgumentError', string.format(
                'failed to convert argument: %s, %s', err, errmsg)
    end

    local _, err, errmsg = upstream_util.get_upstream(api_ctx)
    if err ~= nil then
        return nil, 'GetUpstreamError', string.format(
                'failed to get upstream: %s, %s', err, errmsg)
    end

    set_shard_header(api_ctx)

    local _, err, errmsg = sql_util.make_sqls(api_ctx)
    if err ~= nil then
        return nil, 'MakeSqlError', string.format(
                'failed to make sql: %s, %s', err, errmsg)
    end

    local _, err, errmsg = mysql_util.do_query(api_ctx)
    if err ~= nil then
        return nil, 'DoQueryError', string.format(
                'failed to do query: %s, %s', err, errmsg)
    end

    local resp_value, err, errmsg = api_util.make_resp_value(api_ctx)
    if err ~= nil then
        return nil, 'MakeRespValueError', string.format(
                'failed to make resp value: %s, %s', err, errmsg)
    end

    return resp_value, nil, nil
end


function _M.do_api(opts)
    if opts == nil then
        opts = {}
    end

    ngx.ctx.api = {}

    local api_ctx = ngx.ctx.api

    api_ctx.opts = opts

    local resp

    local resp_value, err, errmsg = _do_api(api_ctx)
    if err ~= nil then
        ngx.log(ngx.ERR, string.format(
                'failed to do api for subject: %s, action: %s, %s, %s',
                api_ctx.subject, api_ctx.action, err, errmsg))
        resp = {error_code = err, error_message = errmsg}
    else
        resp = {value = resp_value}
    end

    api_util.output_json(resp)
end


return _M
