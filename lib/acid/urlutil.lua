local strutil = require('acid.strutil')

local _M = {}


local function percent_encode(c)
    local s = string.format('%%%02X', string.byte(c))
    return s
end


function _M.url_escape(str, safe)
    safe = safe or '/'

    local pattern = '[^A-Za-z0-9%-%._' .. safe .. ']'

    local escaped_str = string.gsub(str, pattern, percent_encode)

    return escaped_str
end


function _M.url_escape_plus(str, safe)
    safe = safe or ''

    local escaped_str = _M.url_escape(str, safe .. ' ')

    local plus_str = string.gsub(escaped_str, ' ', '+')

    return plus_str
end


local function hex_to_char(hex_of_char)
    local c = string.char(tonumber(hex_of_char, 16))
    return c
end


function _M.url_unescape(str)
    local unescaped = string.gsub(str, '%%(%x%x)', hex_to_char)

    return unescaped
end


function _M.url_unescape_plus(str)
    local no_plus_str = string.gsub(str, '+' , ' ')
    local unescaped = _M.url_unescape(no_plus_str)

    return unescaped
end


-- <scheme>://<username>:<password>@<host>:<port>/<path>;<parameters>?<query>#<fragment>
function _M.url_parse(url)
    local r = {}
    local parts = strutil.split(url, ':', {maxsplit=1})
    r.scheme = parts[1]

    local remain = parts[2] or ''

    parts = strutil.split(remain, '?', {maxsplit=1})
    remain = parts[1]

    local query_frag = parts[2] or ''
    parts = strutil.split(query_frag, '#', {maxsplit=1})
    r.query = parts[1]
    r.fragment = parts[2] or ''

    if strutil.startswith(remain, '//') then
        remain = string.sub(remain, 3)
    end

    local slash_index = string.find(remain, '/') or #remain + 1
    local path_params = string.sub(remain, slash_index)
    remain = string.sub(remain, 1, slash_index - 1)

    parts = strutil.split(path_params, ';', {maxsplit=1})
    r.path = parts[1]
    r.params = parts[2] or ''

    parts = strutil.rsplit(remain, '@', {maxsplit=1})
    local host_port = parts[2] or parts[1]
    local user_password = parts[2] and parts[1] or ''

    parts = strutil.split(host_port, ':', {maxsplit=1})
    r.host = parts[1]
    r.port = parts[2] or ''

    parts = strutil.split(user_password, ':', {maxsplit=1})
    r.user = parts[1]
    r.password = parts[2] or ''

    return r, nil, nil
end


function _M.build_query(args)
    local args_str = {}
    for k, v in pairs(args) do
        local s = string.format('%s=%s', _M.url_escape(tostring(k)),
                                _M.url_escape(tostring(v)))
        table.insert(args_str, s)
    end

    local query_string = table.concat(args_str, '&')

    return query_string
end


return _M
