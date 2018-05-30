local cjson = require( "cjson" )

local _M = {}

_M.null = cjson.null
_M.empty_array = cjson.empty_array
_M.empty_array_mt = cjson.empty_array_mt

-- it's a function, will set the module ccjson config.
_M.encode_empty_table_as_object = cjson.encode_empty_table_as_object

local function convert_nil(o)
    if o == nil or o == cjson.null then
        return nil
    end

    if type(o) ~= 'table' then
        return o
    end

    for k, v in pairs(o) do
        if v == nil or v == cjson.null then
            o[k] = nil
        elseif type(v) == 'table' then
            o[k] = convert_nil(v)
        end
    end
    return o
end

function _M.enc( j, opt )

    opt = opt or {}

    if opt.is_array ~= nil then
        if type(j) == 'table' then
            setmetatable(j, _M.empty_array_mt)
        end
    end

    return cjson.encode( j )
end

function _M.dec( j, opt )

    opt = opt or {}

    if opt.use_nil == nil then
        opt.use_nil = true
    end

    if j == nil then
        return nil
    else
        local rc, data = pcall( cjson.decode, j )

        if rc then
            -- cjson string might be encoded multiple times.
            if type(data) == 'string' then
                return data, nil
            end

            if opt.use_nil then
                data = convert_nil(data)
            end

            return data, nil
        else
            local err = data
            return nil, err
        end
    end
end
return _M
