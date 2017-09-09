local httpclient = require('acid.httpclient')
local tableutil = require('acid.tableutil')
local json = require('acid.json')
local strutil = require('acid.strutil')
local urlutil = require('acid.urlutil')

-- doc: https://github.com/coreos/etcd/blob/master/Documentation/v2/api.md

local _M = {}

local mt = { __index = _M }


local SUCCESS_STATUS = {
    [200] = true,
    [201] = true,
}


local VALID_PARAMS = {
    set = {
        value = true,
        ttl = true,
        prevExist = true,
        refresh = true,
        dir = true,
        prevValue = true,
        prevIndex = true,
    },
    get = {
        recursive = true,
        wait = true,
        waitIndex = true,
        sorted = true,
    },
    delete = {
        recursive = true,
        dir = true,
        prevValue = true,
        prevIndex = true,
    },
}


local MAX_RESPONSE_BODY_SIZE = 1024 * 1024 * 100


function _M.new(endpoints, opts)
    opts = opts or {}
    local client = {
        timeout = opts.timeout or 60 * 1000,
        endpoints = endpoints,
        uri_prefix = opts.uri_prefix or '/v2'
    }

    local account = opts.basic_auth_account
    if account ~= nil then
        client.auth_header = string.format(
                'Basic %s', ngx.encode_base64(tostring(account)))
    end

    return setmetatable(client, mt), nil, nil
end


function _M.request_one_endpoint(self, endpoint, method, uri, params, opts)
    opts = opts or {}
    local http_cli, err, errmsg = httpclient:new(
            endpoint.host, endpoint.port, opts.timeout, {ssl=endpoint.ssl})
    if err ~= nil then
        return nil, 'NewHttpClientError', string.format(
                'failed to new http client: %s, %s', err, errmsg)
    end

    local body = ''
    local headers = {
        ['Content-Length'] = 0,
        Authorization = self.auth_header,
    }

    if params ~= nil then
        local params_str = urlutil.build_query(params)

        if method == 'PUT' or method == 'POST' then
            body = params_str
            headers['Content-Length'] = #body
            headers['Content-Type'] = 'application/x-www-form-urlencoded'
        else
            if params_str ~= '' then
                uri = uri .. '?' .. params_str
            end
        end
    end

    local _, err, errmsg = http_cli:request(
            uri, {method=method, headers=headers, body=body})
    if err ~= nil then
        return nil, 'HttpRequestError', string.format(
                'http request return error: %s, %s', err, errmsg)
    end

    local resp_body, err, errmsg = http_cli:read_body(MAX_RESPONSE_BODY_SIZE)
    if err ~= nil then
        return nil, 'HttpReadBodyError', string.format(
                'http read body return error: %s, %s', err, errmsg)
    end

    http_cli:set_keepalive(60 * 1000)

    local resp = {
        status = http_cli.status,
        headers = http_cli.headers,
        body = resp_body,
    }

    return resp, nil, nil
end


function _M.request_all_endpoints(self, method, uri, params, opts)
    if self.random_request then
        self.endpoints = tableutil.ramdom(self.endpoints)
    end

    local err, errmsg

    for _, endpoint in ipairs(self.endpoints) do
        local resp, _err, _errmsg = self:request_one_endpoint(
                endpoint, method, uri, params, opts)
        if _err == nil then
            return resp, nil, nil
        end

        err, errmsg = _err, _errmsg

        ngx.log(ngx.INFO, string.format(
                'request: %s %s to endpoint: %s:%d failed, %s, %s',
                method, uri, endpoint.host, endpoint.port, err, errmsg))
    end

    return nil, err, errmsg
end


function _M.request_etcd(self, method, uri, params, opts)
    local resp, err, errmsg = self:request_all_endpoints(
            method, uri, params, opts)
    if err ~= nil then
        return nil, err, errmsg
    end

    if not SUCCESS_STATUS[resp.status] then
        return nil, 'InvalidResponse', string.format(
                'invalid response from etcd: %d, %s', resp.status, resp.body)
    end

    local data, err = json.dec(resp.body)
    if err ~= nil then
        return nil, 'InvalidResponseBody', string.format(
                'the response body: %s.., is not a valid json sting: %s',
                string.sub(resp.body, 1, 100), err)
    end

    return {data=data, headers=resp.headers}, nil, nil
end


function _M.get_key_uri(self, key)
    if strutil.startswith(key, '/') then
        return string.format('%s/keys%s', self.uri_prefix, key)
    else
        return string.format('%s/keys/%s', self.uri_prefix, key)
    end
end


local function check_parameters(op_name, params)
    for k, _ in pairs(params) do
        if not VALID_PARAMS[op_name][k] then
            return nil, 'InvalidParameterError', string.format(
                    'invalid parameter: %s', tostring(k))
        end
    end
    return true, nil, nil
end


function _M.version(self)
    local method = 'GET'
    local uri = '/version'

    local result, err, errmsg = self:request_etcd(method, uri)
    if err ~= nil then
        return nil, err, errmsg
    end

    return result, nil, nil
end


function _M.leader_statistics(self)
    local method = 'GET'
    local uri = self.uri_prefix .. '/stats/leader'

    local result, err, errmsg = self:request_etcd(method, uri)
    if err ~= nil then
        return nil, err, errmsg
    end

    return result, nil, nil
end


function _M.self_statistics(self)
    local method = 'GET'
    local uri = self.uri_prefix .. '/stats/self'

    local result, err, errmsg = self:request_etcd(method, uri)
    if err ~= nil then
        return nil, err, errmsg
    end

    return result, nil, nil
end


function _M.store_statistics(self)
    local method = 'GET'
    local uri = self.uri_prefix .. '/stats/store'

    local result, err, errmsg = self:request_etcd(method, uri)
    if err ~= nil then
        return nil, err, errmsg
    end

    return result, nil, nil
end


function _M.set(self, key, params, opts)
    opts = opts or {}

    local method = opts.method or 'PUT'

    local uri = self:get_key_uri(key)

    if params ~= nil then
        local _, err, errmsg = check_parameters('set', params)
        if err ~= nil then
            return nil, err, errmsg
        end
    end

    local result, err, errmsg = self:request_etcd(method, uri, params, opts)
    if err ~= nil then
        return nil, err, errmsg
    end

    return result, nil, nil
end


function _M.get(self, key, params, opts)
    local method = 'GET'

    local uri = self:get_key_uri(key)

    if params ~= nil then
        local _, err, errmsg = check_parameters('get', params)
        if err ~= nil then
            return nil, err, errmsg
        end
    end

    local result, err, errmsg = self:request_etcd(method, uri, params, opts)
    if err ~= nil then
        return nil, err, errmsg
    end

    return result, nil, nil
end


function _M.delete(self, key, params, opts)
    local method = 'DELETE'

    local uri = self:get_key_uri(key)

    if params ~= nil then
        local _, err, errmsg = check_parameters('delete', params)
        if err ~= nil then
            return nil, err, errmsg
        end
    end

    local result, err, errmsg = self:request_etcd(method, uri, params, opts)
    if err ~= nil then
        return nil, err, errmsg
    end

    return result, nil, nil
end


function _M.watch_index(self, key, params, opts)
    opts = opts or {}

    params.wait = true

    local timeout = opts.timeout or 60 * 10

    local method = 'GET'
    local uri = self:get_key_uri(key)

    local dead_time = ngx.now() + timeout

    local sleep_time = 0.1

    while true do
        local endpoint_index = math.random(1, #self.endpoints)
        local endpoint = self.endpoints[endpoint_index]

        local start_time = ngx.now()
        local time_remain = dead_time - start_time

        local request_timeout = math.max(0.1, time_remain)
        local result, err, errmsg = self:request_one_endpoint(
                endpoint, method, uri, params,
                {timeout=request_timeout * 1000})
        if err == nil then
            return result, nil, nil
        end

        local end_time = ngx.now()
        local time_used = end_time - start_time

        ngx.log(ngx.INFO, string.format(
                'time_remain: %f, request_timeout: %f, time used: %f, %s, %s',
                time_remain, request_timeout, time_used, err, errmsg))

        if end_time > dead_time then
            return nil, 'TimeoutError', string.format(
                    'key: %s not changed after %f seconds expired',
                    key, timeout)
        end

        ngx.sleep(sleep_time)
        sleep_time = math.min(sleep_time * 2, 2)
    end
end


function _M.watch(self, key, params, opts)
    params = params or {}

    local get_result, err, errmsg = self:get(key)
    if err ~= nil then
        return nil, err, errmsg
    end


    local _, err, errmsg = check_parameters('get', params)
    if err ~= nil then
        return nil, err, errmsg
    end

    local next_index = tonumber(get_result.headers['x-etcd-index']) + 1

    if params.waitIndex ~= nil then
        if params.waitIndex <= get_result.data.node.modifiedIndex then
            return get_result, nil, nil
        end
    end

    params.waitIndex = next_index

    return self:watch_index(key, params, opts)
end


return _M
