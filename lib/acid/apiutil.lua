local _M = {}

local ngx = ngx

function _M.output(code, headers, body)

    ngx.status = code

    for k, v in pairs(headers) do
        ngx.header[k] = v
    end

    ngx.print(body)
    ngx.eof()

    ngx.exit(ngx.HTTP_OK)
end

return _M
