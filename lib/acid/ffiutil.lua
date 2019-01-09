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

local function _idx_lua_to_c(ks)
    local cdata_ks = tableutil.dup(ks)
    for k, v in ipairs(ks) do
        if type(v) == 'number' then
            cdata_ks[k] = v - 1
        end
    end
    return cdata_ks
end

local function _cdata_get(cdata, ks)
    local node = cdata
    for _, v in ipairs(ks) do
        node = node[v]
    end
    return node
end

local function _cdata_to_tbl(cdata, schema)

    local tbl = {}

    for ks, v in tableutil.depth_iter(schema) do

        local cdata_ks = _idx_lua_to_c(ks)
        local cdata_v = _cdata_get(cdata, cdata_ks)

        local str_key_path = table.concat(ks, '.')

        if type(v) == 'number' or type(v) == 'boolean' or type(v) == 'string' then
            tableutil.set(tbl, ks, v)
        elseif type(v) == 'function' then
            local rst, err, errmsg = v(cdata_v)
            if err ~= nil then
                return nil, err, string.format('%s %s convert err, desc:%s', str_key_path, tostring(cdata_v), errmsg)
            end
            tableutil.set(tbl, ks, rst)
        else
            return nil, 'UnsupportedType', string.format('%s type %s is unsupported', str_key_path, type(v))
        end
    end

    return tbl, nil, nil
end

function _M.cdata_to_tbl(cdata, schema)

    local ok, err_or_rst, err, errmsg = pcall(_cdata_to_tbl, cdata, schema)

    if not ok then
        return nil, 'UnknownError', err_or_rst
    end

    return err_or_rst, err, errmsg
end

local function _translate_tbl(tbl, schema)

    local new_tbl = {}

    for ks, v in tableutil.depth_iter(schema) do
        local tbl_v = tableutil.get(tbl, ks)

        local str_key_path = table.concat(ks, '.')

        if tbl_v == nil then
            return nil, 'KeyError', string.format('schema required key:%s not in tbl', str_key_path)
        end

        if type(v) == 'function' then

            local rst, err, errmsg = v(tbl_v)
            if err ~= nil then
                return nil, err, string.format('%s %s convert err, desc:%s', str_key_path, tostring(tbl_v), errmsg)
            end
            tableutil.set(new_tbl, ks, rst)

        elseif type(v) == 'number' or type(v) == 'boolean' or type(v) == 'string' then
            tableutil.set(new_tbl, ks, v)
        else
            return nil, 'UnsupportedType', string.format('%s type %s is unsupported', str_key_path, type(v))
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
