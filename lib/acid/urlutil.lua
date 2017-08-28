-- base on https://github.com/bikong0411/lua_url.git
local strutil = require('acid.strutil')

local _M = {}


function _M.url_escape(str, safe)
    safe = safe or '/'

    local pattern = "^A-Za-z0-9%-%._" .. safe

    str = str:gsub("[" .. pattern .. "]", function(c)
        return string.format("%%%02X", string.byte(c)) end)

    return str
end


function _M.url_escape_plus(str,safe)
    local s

    safe = safe or ''

    if str:find(' ') ~= nil then
        s = _M.url_escape(str, safe .. ' ')
        s = s:gsub(' ', '+')
        return s
    end

    return _M.url_escape(str, safe)
end


function _M.url_unescape(str)
   str = str:gsub("%%(%x%x)",function(x) return string.char(tonumber(x,16)) end)
   return str
end


function _M.url_unescape_plus(str)
    str = str:gsub( '+', ' ' )
    return _M.url_unescape( str )
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


function _M.build_query(tb)
   assert(type(tb)=="table","tb must be a table")
   local t = {}
   for k, v in pairs(tb) do
       table.insert(t, _M.url_escape(tostring(k)) ..
                    "=" .. _M.url_escape(tostring(v)))
   end
   return table.concat(t,'&')
end


return _M
