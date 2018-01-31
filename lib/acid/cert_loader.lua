local fs = require('fs')
local strutil = require('acid.strutil')
local ssl = require('ngx.ssl')
local s2conf = require('s2conf')


local _M = {}

local cert_file_suffix = '.crt'
local cert_key_file_suffix = '.key'


local function reverse_table(table_to_reverse)
    local reversed = {}
    for _, elt in ipairs(table_to_reverse) do
        table.insert(reversed, 1, elt)
    end
    return reversed
end


local function build_cert_info(cert_name, cert_file, key_file)
    local pem_cert, err, msg = fs.read(cert_file)
    if err ~= nil then
        return nil, err, msg
    end

    local pem_key, err, msg = fs.read(key_file)
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


function _M.build_cert_tree(cert_path)
    local cert_tree = {}
    local certs = {}

    local file_names, err, msg = fs.read_dir(cert_path)
    if err ~= nil then
        return nil, err, msg
    end

    if #file_names == 0 then
        return nil, 'NoCertificateError',
                'no file in cert path: ' .. tostring(cert_path)
    end

    for _, file_name in ipairs(file_names) do
        local cert_file = cert_path .. '/' .. file_name
        local key_file = string.sub(cert_file, 1, -1 - #cert_file_suffix)
                             .. cert_key_file_suffix

        if strutil.endswith(file_name, cert_file_suffix) == true then

            local cert_name = string.sub(file_name, 1, -1 - #cert_file_suffix)

            local cert_info, err, msg =
                    build_cert_info(cert_name, cert_file, key_file)
            if err ~= nil then
                return nil, err, msg
            end

            ngx.log(ngx.INFO, 'added certificate: ' .. cert_name)

            certs[cert_name] = cert_info
        end
    end

    for cert_name, cert_info in pairs(certs) do
        local domain_components = strutil.split(cert_name, '[.]')
        local reversed_components = reverse_table(domain_components)

        local node = cert_tree
        for _, component in ipairs(reversed_components) do
            if node[component] == nil then
                node[component] = {}
            end
            node = node[component]
        end

        node['_cert_info'] = cert_info
    end

    return cert_tree, nil, nil
end


local function choose_cert(server_name)
    local node = _M.cert_tree
    if node == nil then
        return nil, 'CertificateError', 'the certificate tree is not built'
    end

    local domain_components = strutil.split(server_name, '[.]')
    local reversed_components = reverse_table(domain_components)

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


local function update_cert_tree(cert_path, cert_update_interval)
    local last_update_ts = _M.last_update_ts or 0
    cert_update_interval = cert_update_interval or
            tonumber(s2conf.cert_update_interval) or 3600

    if _M.cert_tree ~= nil and
            ngx.time() - last_update_ts < cert_update_interval then
        return _M.cert_tree, nil, nil
    end

    cert_path = cert_path or s2conf.cert_path
    if cert_path == nil then
        return nil, 'ConfigureError', 'no valid configue for cert_path'
    end

    local cert_tree, err, msg = _M.build_cert_tree(cert_path)
    if err ~= nil then
        return nil, err, msg
    end

    _M.cert_tree = cert_tree
    _M.last_update_ts = ngx.time()

    return _M.cert_tree, nil, nil
end


local function _load_cert_and_key(cert_path, cert_update_inverval)
    local server_name, err = ssl.server_name()
    if err ~= nil then
        return nil, 'SSLError', 'failed to get server name:' .. err
    end

    if server_name == nil then
        return 'client did not set server name', nil, nil
    end

    local _, err, msg = update_cert_tree(cert_path, cert_update_inverval)
    if err ~= nil then
        return nil, 'UpdateCertError', string.format(
                'failed to update cert_tree: %s, %s', err, msg)
    end

    local cert_info, err, msg = choose_cert(server_name)
    if err ~= nil then
        return nil, 'GetCertError', string.format(
                'failed to get certificate for server_name: %s, %s, %s',
                server_name, err, msg)
    end

    if cert_info == nil then
        return 'no cert for server_name: ' .. server_name, nil, nil
    end

    local ok, err = ssl.clear_certs()
    if not ok then
        return nil, 'SSLError', 'failed to clear existing certificates:' .. err
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


function _M.load_cert_and_key(cert_path, cert_update_interval)
    local result, err, msg = _load_cert_and_key(cert_path, cert_update_interval)
    if err ~= nil then
        ngx.log(ngx.ERR, string.format('failed to load cert and key: %s, %s',
                                       err, msg))
        return nil, err, msg
    end

    if type(result) == 'table' then
        ngx.log(ngx.INFO, 'loaded cert: ' .. result.cert_name)
    else
        ngx.log(ngx.INFO, 'cert not load, the reason is: ' .. result)
    end
end


return _M
