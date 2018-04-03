local convertor = require('acid.dbagent.convertor')
local json = require('acid.json')
local strutil = require('acid.strutil')


local _M = {}


function _M.extract_request_info(api_ctx)
    local method = ngx.var.request_method

    if method ~= 'POST' and method ~= 'GET' then
        return nil, 'MethodNotAllowed', 'only POST and GET allowed'
    end
    api_ctx.method = method

    api_ctx.query_args = ngx.req.get_uri_args()
    api_ctx.uri = ngx.var.request_uri
    api_ctx.headers = ngx.req.get_headers()

    local path = strutil.split(api_ctx.uri, '?')[1]
    local parts = strutil.split(path, '/')

    -- /api/v1/bucket/ls
    api_ctx.subject = parts[4] or ''
    api_ctx.action = parts[5] or ''

    if method == 'GET' then
        api_ctx.args = api_ctx.query_args
        return true, nil, nil
    end

    ngx.req.read_body()
    local body = ngx.req.get_body_data()

    if body == nil or body == '' then
        return nil, 'InvalidRequest', 'the body is empty'
    end

    local post_args, err = json.dec(body)
    if err ~= nil then
        return nil, 'InvalidRequest', 'the body is not a valid json: ' .. err
    end

    if type(post_args) ~= 'table' then
        return nil, 'InvalidRequest', 'the json decoded body is not a table'
    end

    api_ctx.args = post_args

    return true, nil, nil
end


function _M.make_resp_value(api_ctx)
    if api_ctx.query_result.affected_rows ~= nil then
        return api_ctx.query_result, nil, nil
    end

    setmetatable(api_ctx.query_result, json.empty_array_mt)

    local _, err, errmsg = convertor.convert_result(api_ctx)
    if err ~= nil then
        return nil, err, errmsg
    end

    local resp_value = api_ctx.query_result
    if api_ctx.action_model.unpack_list == true then
        if #resp_value > 1 then
            return nil, 'UnpackListError', 'more than one element in list'
        end
        resp_value = resp_value[1]
    end

    return resp_value, nil, nil
end


function _M.output_json(resp)
    local body = json.enc(resp)

    ngx.say(body)
    ngx.eof()
    ngx.exit(ngx.HTTP_OK)
end


return _M
