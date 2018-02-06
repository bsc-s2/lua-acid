local ffi = require('ffi')
local C = ffi.C
local string_match = string.match
local tableutil = require('acid.tableutil')

local _M = { _VERSION = '1.0' }

ffi.cdef [[
long int strtol(const char *str, char **endptr, int base);
unsigned long int strtoul(const char *nptr, char **endptr, int base);
]]

function _M.str_to_clong(str, mode)

    if type(str) ~= 'string' then
        return nil, 'InvalidArgument', string.format('not a string, but a %s', type(str))
    end

    if string_match(str, '^%-?%d+$') == nil then
        return nil, 'InvalidArgument', string.format('%s was not a valid number string', str)
    end

    local clong

    ffi.errno(0)

    if mode == 'u' then
        clong = C.strtoul(str, nil, 10)
    else
        clong = C.strtol(str, nil, 10)
    end

    local errno = ffi.errno(0)

    if errno ~= 0 then
        return nil, 'OutOfRange', string.format('%s was out of range', str)
    end

    return clong, nil, nil
end

function _M.clong_to_str(clong)
    local literal = tostring(clong)
    return string_match(literal, '%-?%d+'), nil, nil
end

function _M.carray_to_tbl(carray, len, converter)

    local tbl = {}

    for i = 0, len - 1 do

        if converter ~= nil then

            local rst, err, errmsg = converter(carray[i])

            if err ~= nil then
                return nil, err, string.format('index:%s, error:%s', i, errmsg)
            end

            tbl[i + 1] = rst
        else
            tbl[i + 1] = carray[i]
        end
    end

    return tbl, nil, nil
end

function _M.tbl_to_carray(ctype, tbl, converter)
    local new_tbl = tableutil.dup(tbl, true)
    if converter ~= nil then
        for i = 1, #new_tbl do
            local rst, err, errmsg = converter(new_tbl[i])
            if err ~= nil then
                return nil, err, string.format('index:%s, error:%s', i, errmsg)
            end
            new_tbl[i] = rst
        end
    end
    return ffi.new(ctype, new_tbl), nil, nil
end

function _M.cdata_to_tbl(cdata, schema)

    local tbl = {}

    for k, v in pairs(schema) do

        local index = k

        if type(k) == 'number' then
            index = k - 1
        end

        if type(v) == 'table' then

            local rst, err, errmsg = _M.cdata_to_tbl(cdata[index], v)
            if err ~= nil then
                return nil, err, string.format('%s.%s', k, errmsg)
            end
            tbl[k] = rst

        elseif type(v) == 'function' then

            local rst, err, errmsg = v(cdata[index])
            if err ~= nil then
                return nil, err, string.format('%s error:%s', k, errmsg)
            end
            tbl[k] = rst

        elseif type(v) == 'number' or type(v) == 'boolean' or type(v) == 'string' then
            tbl[k] = v
        end
    end

    return tbl, nil, nil
end

local function _translate_tbl(tbl, schema)

    local new_tbl = tableutil.dup(tbl, true)

    for k, v in pairs(schema) do
        if type(v) == 'table' then
            local rst, err, errmsg = _translate_tbl(new_tbl[k], v)
            if err ~= nil then
                return nil, err, string.format('%s.%s', k, errmsg)
            end
            new_tbl[k] = rst
        elseif type(v) == 'function' then
            local rst, err, errmsg = v(new_tbl[k])
            if err ~= nil then
                return nil, err, string.format('%s error:%s', k, errmsg)
            end
            new_tbl[k] = rst
        elseif type(v) == 'number' or type(v) == 'boolean' or type(v) == 'string' then
            new_tbl[k] = v
        else
            new_tbl[k] = new_tbl[k]
        end
    end

    return new_tbl, nil, nil
end

function _M.tbl_to_cdata(ctype, tbl, schema)
    local translated_tbl, err, errmsg = _translate_tbl(tbl, schema)
    if err ~= nil then
        return nil, err, errmsg
    end
    return ffi.new(ctype, translated_tbl), nil, nil
end

return _M