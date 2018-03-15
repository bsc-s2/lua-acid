local _M = {}


function _M.get_connect_repr(options)
    return string.format('connection %s %05d: host: %s, port: %s',
                         tostring(ngx.time()),
                         math.random(0, 99999), options.host, options.port)
end


return _M
