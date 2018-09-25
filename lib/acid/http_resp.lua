local acid_json = require('acid.json')
local aws_errorcode = require('acid.aws.errorcode')

local _M = {}

function _M.set_status_headers(status, headers)
    ngx.status = status

    for h, v in pairs(headers) do
        ngx.header[h] = v
    end
end

function _M.send_body( body)
    ngx.print(body)
    ngx.eof()
    return ngx.exit(ngx.HTTP_OK)
end

function _M.response(status, headers, body)
    body = body or ''

    if headers['Content-Length'] == nil then
        headers['Content-Length'] = #body
    end

    _M.set_status_headers(status, headers)
    return _M.send_body(body)
end

function _M.set_range_status_headers(range, total_size)
    local status, headers = _M.get_range_status_headers(range, total_size)
    return _M.set_status_headers(status, headers)
end

function _M.get_range_status_headers(range, total_size)
    local status
    local headers = {
            ['Accept-Ranges'] = 'bytes',
        }

    range = range or {}

    if range.from == nil then
        status = 200

        if total_size ~= nil then
            headers['Content-Length'] = tostring(total_size)
        end
    else
        status = 206

        if total_size ~= nil then
            local cl = range['to'] - range['from'] + 1
            headers['Content-Length'] = tostring(cl)
        end

        headers['Content-Range'] = string.format(
            'bytes %d-%d/%s',
            range['from'],
            range['to'],
            tostring(total_size or '*')
        )
    end

    return status, headers
end

function _M.output(rst, err_code, err_msg, opts)
    local opts = opts or {}

    local code_status = opts.code_status or aws_errorcode

    local status, body, headers = 200, '', {}

    local request_id = ngx.var.requestid

    if err_code ~= nil then
        ngx.log( ngx.WARN, "requestid: ", request_id,
             " err_code: ", err_code, " err_msg: ", err_msg )

        if ngx.headers_sent then
            ngx.log(ngx.WARN, 'has sent response headers')
            return
        end

        status = code_status[err_code]
            or aws_errorcode[err_code]
            or ngx.HTTP_BAD_REQUEST

        headers["Content-Type"] = "application/json"

        local Error = {
                  Code      = err_code,
                  Message   = err_msg,
                  RequestId = request_id,
                }
        body = acid_json.enc( Error )
    else
        rst = rst or {}

        body = rst.value or ''
    end

    return _M.response(status, headers, body)
end

return _M
