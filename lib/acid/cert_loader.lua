local fsutil = require('acid.fsutil')
local strutil = require('acid.strutil')
local ssl = require('ngx.ssl')
local time = require('acid.time')
local tableutil = require('acid.tableutil')
local async_cache = require('acid.async_cache')


local _M = {
    cert_tree = nil,
    update_time = 0,
    expire_time = 60 * 10,

    cache = nil,
    cache_expire_time = 60 * 60,

    cert_path = '/usr/local/cert',
    cert_suffix = '.crt',
    cert_key_suffix = '.key',
}


local function build_cert_info(cert_name, cert_file, key_file)
    local pem_cert, err, msg = fsutil.read(cert_file)
    if err ~= nil then
        return nil, err, msg
    end

    local pem_key, err, msg = fsutil.read(key_file)
    if err ~= nil then
        return nil, err, msg
    end

    local der_cert, err = ssl.cert_pem_to_der(pem_cert)
    if err ~= nil then
        return nil, 'CertificateError', string.format(
                'failed to convert certificate of: %s to der format:%s',
                cert_name, err)
    end

    local der_key, err = ssl.priv_key_pem_to_der(pem_key)
    if err ~= nil then
        return nil, 'CertificateError', string.format(
                'failed to convert private key of: %s to der format:%s',
                cert_name, err)
    end

    local cert_info = {
        cert_name = cert_name,
        der_cert = der_cert,
        der_key = der_key,
    }

    return cert_info, nil, nil
end


function _M.build_cert_tree(self, key_name)
    local _ = key_name
    local start_ms = time.get_ms()

    ngx.log(ngx.INFO, string.format(
            'at ms: %d, worker: %d start to build cert tree',
            start_ms, ngx.worker.id()))

    local cert_tree = {}
    local certs = {}

    local file_names, err, errmsg = fsutil.read_dir(self.cert_path)
    if err ~= nil then
        return nil, err, errmsg
    end

    if #file_names == 0 then
        return nil, 'NoCertificateError',
                'no file in cert path: ' .. tostring(self.cert_path)
    end

    for _, file_name in ipairs(file_names) do
        local cert_file = self.cert_path .. '/' .. file_name
        local key_file = string.sub(cert_file, 1, -1 - #self.cert_suffix)
                             .. self.cert_key_suffix

        if strutil.endswith(file_name, self.cert_suffix) == true then

            local cert_name = string.sub(file_name, 1, -1 - #self.cert_suffix)

            local cert_info, err, errmsg =
                    build_cert_info(cert_name, cert_file, key_file)
            if err ~= nil then
                ngx.log(ngx.ERR, string.format(
                        'failed to build cert info for: %s, %s, %s',
                        cert_name, err, errmsg))
            else
                ngx.log(ngx.INFO, 'added certificate: ' .. cert_name)

                certs[cert_name] = cert_info
            end
        end
    end

    for cert_name, cert_info in pairs(certs) do
        local domain_components = strutil.split(cert_name, '[.]')
        local reversed_components = tableutil.reverse(domain_components)

        local node = cert_tree
        for _, component in ipairs(reversed_components) do
            if node[component] == nil then
                node[component] = {}
            end
            node = node[component]
        end

        node['_cert_info'] = cert_info
    end

    local end_ms = time.get_ms()
    ngx.log(ngx.INFO, string.format(
            'at ms: %d, worker: %d finished to build cert tree, time used: %d ms',
            end_ms, ngx.worker.id(), end_ms - start_ms))

    return {value=cert_tree}, nil, nil
end


local function init_async_cache(opts)
    if _M.cache ~= nil then
        return _M.cache, nil, nil
    end

    local update_handler = {
        get_latest = _M.build_cert_tree,
        cert_path = opts.cert_path or _M.cert_path,
        cert_suffix = opts.cert_suffix or _M.cert_suffix,
        cert_key_suffix = opts.cert_key_suffix or _M.cert_key_suffix,
    }

    local cache, err, errmsg = async_cache.new(
            opts.shared_dict_name,
            opts.lock_shared_dict_name,
            'cert_loader',
            update_handler,
            {cache_expire_time=opts.cache_expire_time or _M.cache_expire_time}
            )
    if err ~= nil then
        return nil, err, errmsg
    end

    _M.cache = cache

    return _M.cache, nil, nil
end


function _M.get_cert_tree(opts)
    local _, err, errmsg = init_async_cache(opts)
    if err ~= nil then
        return nil, err, errmsg
    end

    local expire_time = opts.expire_time or _M.expire_time
    if _M.cert_tree ~= nil and ngx.time() - _M.update_time < expire_time then
        return _M.cert_tree, nil, nil
    end

    local cache_value, err, errmsg = _M.cache:get('cert_tree')
    if err ~= nil then
        return nil, err, errmsg
    end

    _M.cert_tree = cache_value.value
    _M.update_time = ngx.time()

    ngx.log(ngx.INFO, string.format('worker: %s updated cert from cache',
                                    ngx.worker.id()))

    return _M.cert_tree, nil, nil
end


function _M.choose_cert(cert_tree, server_name)
    local node = cert_tree

    local domain_components = strutil.split(server_name, '[.]')
    local reversed_components = tableutil.reverse(domain_components)

    local cert_info = node._cert_info

    for _, component in ipairs(reversed_components) do
        node = node[component]
        if type(node) ~= 'table' then
            break
        end

        if node._cert_info ~= nil then
            cert_info = node._cert_info
        end
    end

    return cert_info, nil, nil
end


local function set_cert(cert_info)
    local ok, err = ssl.clear_certs()
    if not ok then
        return nil, 'SSLError',
                'failed to clear existing certificates: ' .. err
    end

    local _, err = ssl.set_der_cert(cert_info.der_cert)
    if err ~= nil then
        return nil, 'SSLError', 'failed to set der certificate:' .. err
    end

    local _, err = ssl.set_der_priv_key(cert_info.der_key)
    if err ~= nil then
        return nil, 'SSLError', 'failed to set der private key:' .. err
    end

    return cert_info, nil, nil
end


local function _load_cert_and_key(opts)
    if opts == nil then
        opts = {}
    end

    local server_name = opts.server_name
    if server_name == nil then
        local request_server_name, err = ssl.server_name()
        if err ~= nil then
            local log_info = string.format(
                    'failed to get server name: %s', err)
            ngx.log(ngx.ERR,log_info)
            return {reason=log_info}
        end
        server_name = request_server_name
    end

    if server_name == nil then
        local log_info = 'client did not set server name'
        ngx.log(ngx.INFO, log_info)
        return {reason=log_info}
    end

    local cert_tree, err, errmsg = _M.get_cert_tree(opts)
    if err ~= nil then
        local log_info = string.format(
                'failed to get cert tree: %s, %s', err, errmsg)
        ngx.log(ngx.ERR, log_info)
        return {reason=log_info}
    end

    local cert_info = _M.choose_cert(cert_tree, server_name)

    if cert_info == nil then
        local log_info = string.format('no cert for: %s', server_name)
        ngx.log(ngx.INFO, log_info)
        return {reason=log_info}
    end

    ngx.log(ngx.INFO, string.format('use cert: %s for server name: %s',
                                    cert_info.cert_name, server_name))

    local _, err, errmsg = set_cert(cert_info)
    if err ~= nil then
        local log_info = string.format(
                'failed to set cert: %s, %s, %s',
                cert_info.cert_name, err, errmsg)
        ngx.log(ngx.ERR, log_info)
        return {reason=log_info}
    end

    return cert_info
end


function _M.load_cert_and_key(opts)
    local ok, r_or_err = pcall(_load_cert_and_key, opts)
    if not ok then
        local log_info = string.format(
                'failed to run _load_cert_and_key: %s', r_or_err)
        ngx.log(ngx.ERR, log_info)
        return {reason=log_info}
    end

    return r_or_err
end


return _M
