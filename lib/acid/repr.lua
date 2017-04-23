local _M = { _VERSION = '0.1' }


local function _keys(tbl)
    local ks = {}
    for k, _ in pairs(tbl) do
        table.insert( ks, k )
    end
    return ks
end


local function _repr_opt(opt)
    opt = opt or {}
    opt.indent = opt.indent or ''
    opt.sep = opt.sep or ''
    return opt
end


local function _normkey(k, opt)

    if opt.mode == 'str' then
        return tostring(k)
    end

    local key
    if type(k) == 'string' and string.match( k, '^[%a_][%w_]*$' ) ~= nil then
        key = k
    else
        key = '['.._M.repr(k)..']'
    end
    return key
end


local function _extend(lst, sublines, opt)
    for _, sl in ipairs(sublines) do
        table.insert( lst, opt.indent .. sl )
    end
    lst[ #lst ] = lst[ #lst ] .. ','
end


local function _repr_lines(t, opt)

    local tp = type( t )

    if tp == 'string' then
        local s = string.format('%q', t)
        if opt.mode == 'str' then
            -- strip quotes
            s = s:sub( 2, -2 )
        end
        return { s }

    elseif tp ~= 'table' then
        return { tostring(t) }
    end

    -- table

    local keys = _keys(t)
    if #keys == 0 then
        return { '{}' }
    end

    table.sort( keys, function( a, b ) return tostring(a)<tostring(b) end )

    local lst = {'{'}

    local i = 1
    while t[i] ~= nil do
        local sublines = _repr_lines(t[i], opt)
        _extend(lst, sublines, opt)
        i = i+1
    end

    for _, k in ipairs(keys) do

        if type(k) ~= 'number' or k > i then

            local sublines = _repr_lines(t[k], opt)
            sublines[ 1 ] = _normkey(k, opt) ..'='.. sublines[ 1 ]
            _extend(lst, sublines, opt)
        end
    end

    -- remove the last ','
    lst[ #lst ] = lst[ #lst ]:sub( 1, -2 )

    table.insert( lst, '}' )
    return lst
end


local function _repr(t, opt)
    local lst = _repr_lines(t, opt)
    local sep = opt.sep
    if opt.indent ~= "" then
        sep = "\n"
    end
    return table.concat( lst, sep )
end


function _M.str(t, opt)
    opt = _repr_opt(opt)
    opt.mode = 'str'
    return _repr(t, opt)
end


function _M.repr(t, opt)
    opt = _repr_opt(opt)
    return _repr(t, opt)
end


return _M
