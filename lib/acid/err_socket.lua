local _M = {
    [ "default" ]        = "InvalidRequest",
    [ "timeout" ]        = "RequestTimeout",
    [ "client aborted" ] = "InvalidRequest",
    [ "connection reset by peer" ] = "InvalidRequest",
}

function _M.to_code( err, default )

    default = default or _M.default

    return _M[err] or default
end

return _M
