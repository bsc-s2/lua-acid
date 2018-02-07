local acid_json = require("acid.json")
local strutil = require("acid.strutil")
local fsutil = require("acid.fsutil")

local _M = {
    types = {}
}

local acid_path = fsutil.base_path(package.searchpath('acid.strutil', package.path))

local resource = acid_path .. "/thirdpart/mimes.json"

function _M.init()
    local cont, err, errmsg = fsutil.read(resource)

    if err ~= nil then
        return nil, err, errmsg
    end

    local x, err, errmsg = acid_json.dec(cont)
    if err ~= nil then
        return nil, err, errmsg
    end

    if x ~= nil then
        for k, v in pairs(x) do
            _M.types[k] = v
        end
    end

    return nil, nil, nil
end

function _M.by_fn(fn)
    local mime_type

    local s, _ = string.find(fn, '[.]')
    if s ~= nil then
        local suffix = strutil.rsplit(fn, '[.]', { maxsplit = 1 })[2]
        mime_type = _M.types[suffix]
    end

    return mime_type or 'application/octet-stream'
end

(function()
    local _, err, errmsg = _M.init()
    if err ~= nil then
        ngx.log(ngx.ERR, err, ' ', tostring(errmsg), ' while init mimetypes')
        error("error init mime, errmsg:" .. tostring(errmsg))
    end
end)()

return _M
