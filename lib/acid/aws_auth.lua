local aws_authenticator = require("resty.awsauth.aws_authenticator")

local _M = {}

local function get_secret_key(ak, sk)
    return function(ctx)
        if ctx.access_key ~= ak then
            return nil, 'InvalidAccessKeyId',
                'access key does not exists: ' .. ctx.access_key
        end

        return sk
    end
end

local function bucket_from_host(host)
    return host, nil, nil
end

function _M.check(ak, sk, get_bucket_from_host, shared_dict, opts)
    if ak == nil or sk == nil then
        return
    end

    get_bucket_from_host = get_bucket_from_host or bucket_from_host

    local authenticator = aws_authenticator.new(
        get_secret_key(ak, sk), get_bucket_from_host, shared_dict, opts)
    local ctx, err_code, err_msg = authenticator:authenticate()
    if err_code ~= nil then
        return nil, 'InvalidSignature', err_msg
    end

    if ctx.anonymous == true then
        return nil, 'AccessDenied', 'anonymous user are not allowed'
    end
end

return _M
