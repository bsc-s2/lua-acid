local repr = require( "acid.repr" )
local strutil = require('acid.strutil')


local _M = { _VERSION = '0.1' }


local comparable_types = {
    ['number'] = true,
    ['string'] = true,
    ['table'] = true,
}

local valid_setter_mode = {
    keep    = true,
    replace = true,
}


_M.repr = repr.repr
_M.str = repr.str


math.randomseed(os.time() * 1000)


local function _get_value_to_set(v, current_val)
    if type(v) == 'function' then
        return v(current_val)
    else
        return v
    end
end


function _M.nkeys(tbl)
    return #_M.keys(tbl)
end


function _M.keys(tbl)
    local ks = {}
    for k, _ in pairs(tbl) do
        table.insert( ks, k )
    end
    return ks
end


function _M.duplist(tbl, deep)
    local t = _M.dup( tbl, deep )
    local rst = {}

    local i = 0
    while true do
        i = i + 1
        if t[i] == nil then
            break
        end
        rst[i] = t[i]
    end
    return rst
end


function _M.dup(tbl, deep, ref_table)

    if type(tbl) ~= 'table' then
        return tbl
    end

    ref_table = ref_table or {}

    if ref_table[ tbl ] ~= nil then
        return ref_table[ tbl ]
    end

    local t = {}
    ref_table[tbl] = t

    for k, v in pairs( tbl ) do
        if deep then
            if type( v ) == 'table' then
                v = _M.dup(v, deep, ref_table)
            end
        end
        t[ k ] = v
    end
    return setmetatable(t, getmetatable(tbl))
end


local function _contains(a, b, compared)

    if type(a) ~= 'table' or type(b) ~= 'table' then
        return a == b
    end

    if a == b then
        return true
    end

    if compared[a] == nil then
        compared[a] = {}
    end

    if compared[a][b] ~= nil then
        -- If we see a pair of already compared node, it could be one of
        -- following situations:
        --
        -- *    a and b are both in a finished key path. Then all following key
        --      path must be the same.
        --
        -- *    Or they are both ancestors in current key path. In other word,
        --      a circle is found in both key path. Thus we can finish comparing
        --      these two key paths.
        return true
    end

    compared[a][b] = true

    for k, v in pairs(b) do
        local yes = _contains(a[k], v, compared)
        if not yes then
            return false
        end
    end
    return true
end


function _M.contains(a, b)
    return _contains(a, b, {})
end


function _M.eq(a, b)
    return _M.contains(a, b) and _M.contains(b, a)
end


-- TODO add doc
function _M.cmp_list(a, b)

    local ta = type(a)
    local tb = type(b)

    if ta ~= tb then
        error('can not compare different type: ' .. ta .. ' with ' .. tb)
    end

    if not comparable_types[ta] then
        error('can not compare two ' .. ta .. ' value')
    end

    if ta ~= 'table' then
        -- same type but primitive type.
        if a > b then
            return 1
        elseif a == b then
            return 0
        else
            return -1
        end
    end

    for i, va in ipairs(a) do
        local vb = b[i]
        if vb == nil then
            -- a has more element. thus a > b
            return 1
        end
        local rst = _M.cmp_list(va, vb)
        if rst ~= 0 then
            return rst
        end

        -- else: continue to compare next elt.
    end

    -- finished comparing all elts in a.

    if b[#a + 1] ~= nil then
        --  b has more elts.
        return -1
    else
        -- a and b has the same nr of elts.
        return 0
    end
end


function _M.sub(tbl, ks, list)
    ks = ks or {}
    local t = {}
    for _, k in ipairs(ks) do
        if list == 'list' then
            table.insert(t, tbl[k])
        else
            t[k] = tbl[k]
        end
    end
    return t
end


function _M.intersection(tables, val)

    local t = {}
    local n = 0

    for _, tbl in ipairs(tables) do
        n = n + 1
        for k, _ in pairs(tbl) do
            t[ k ] = ( t[ k ] or 0 ) + 1
        end
    end

    local rst = {}
    for k, v in pairs(t) do
        if v == n then
            rst[ k ] = val or tables[ 1 ][ k ]
        end
    end
    return rst
end


function _M.union(tables, val)
    local t = {}

    for _, tbl in ipairs(tables) do
        for k, v in pairs(tbl) do
            t[ k ] = val or v
        end
    end
    return t
end


function _M.merge(tbl, ...)
    for _, src in ipairs({...}) do
        for k, v in pairs(src) do
            tbl[ k ] = v
        end
    end
    return tbl
end


function _M.iter(tbl)

    local ks = _M.keys(tbl)
    local i = 0

    table.sort( ks, function( a, b ) return tostring(a)<tostring(b) end )

    return function()
        i = i + 1
        local k = ks[i]
        if k == nil then
            return
        end
        return ks[i], tbl[ks[i]]
    end
end


function _M.depth_iter(tbl)

    local ks = {}
    local iters = {_M.iter( tbl )}
    local tabletype = type({})

    return function()

        while #iters > 0 do

            local k, v = iters[#iters]()

            if k == nil then
                ks[#iters], iters[#iters] = nil, nil
            else
                ks[#iters] = k

                if type(v) == tabletype then
                    table.insert(iters, _M.iter(v))
                else
                    return ks, v
                end
            end
        end
    end
end


function _M.has(tbl, value)

    if value == nil then
        return true
    end

    for _, v in pairs(tbl) do
        if v == value then
            return true
        end
    end

    return false
end


function _M.remove_value(tbl, value)

    for k, v in pairs(tbl) do
        if v == value then
            -- int, shift
            if type(k) == 'number' and k % 1 == 0 then
                table.remove(tbl, k)
            else
                tbl[k] = nil
            end
            return v
        end
    end

    return nil
end


function _M.remove_all(tbl, value)

    local removed = 0
    while _M.remove_value(tbl, value) ~= nil do
        removed = removed + 1
    end

    return removed
end


function _M.get_len(tbl)
    local len = 0
    for _, _ in pairs(tbl) do
        len = len + 1
    end

    return len
end


function _M.random(tbl, n)
    local idx
    local rnd
    local tlen
    local elmts = {}

    if type(tbl) ~= 'table' then
        return tbl
    end

    tlen = #tbl
    if tlen == 0 then
        return {}
    end

    n = math.min(n or tlen, tlen)
    rnd = math.random(1, tlen)

    for i = 1, n, 1 do
        idx = (rnd+i) % tlen + 1
        table.insert(elmts, tbl[idx])
    end

    return elmts
end


function _M.reverse(tbl, opts)
    if opts == nil then
        opts = {}
    end

    local reversed = {}

    local array_len = #tbl

    for i = 1, array_len do
        local reversed_index = array_len - i + 1
        local elt = tbl[i]

        if type(elt) == 'table' and opts.recursive == true then
            elt = _M.reverse(elt, opts)
        end
        reversed[reversed_index] = elt
    end

    if opts.keep_hash_part ~= true then
        return reversed
    end

    for k, v in pairs(tbl) do
        if type(k) ~= 'number' or k > array_len then
            if type(v) == 'table' and opts.hash_immutable ~= true
                    and opts.recursive == true then
                v = _M.reverse(v, opts)
            end

            reversed[k] = v
        end
    end

    return reversed
end


function _M.extends(tbl, tvals)

    if type(tbl) ~= 'table' or tvals == nil then
        return tbl
    end

    -- Note: will be discarded after nil elements in tvals
    for _, v in ipairs(tvals) do
        table.insert(tbl, v)
    end

    return tbl
end


function _M.is_empty(tbl)
    if type(tbl) == 'table' and next(tbl) == nil then
        return true
    else
        return false
    end
end


function _M.get(tbl, keys)

    local node = tbl
    local prefix = ''

    local ks = strutil.split(keys, '[.]')

    for _, k in ipairs(ks) do

        if node == nil then
            return nil, 'NotFound', 'found nil field: ' .. prefix
        end

        if type(node) ~= 'table' then
            return nil, 'NotTable', 'found non-table field: ' .. prefix
        end
        node = node[k]
        prefix = prefix .. '.' .. k
    end

    return node, nil, nil
end


function _M.set(tbl, key_path, value, opts)
    if type(tbl) ~= 'table' then
        return nil, 'NotTable', 'tbl is not a table, is type: ' .. type(tbl)
    end

    if opts == nil then
        opts = {}
    end

    local node = tbl

    local prefix = ''

    local ks = strutil.split(key_path, '[.]')
    local ks_n = #ks

    for i = 1, ks_n do
        if i == ks_n then
            local last_k = ks[ks_n]

            if node[last_k] == nil or opts.override then
                node[last_k] = value
                return tbl, nil, nil
            else
                return nil, 'KeyPathExist', string.format(
                        'key path: %s.%s already exist', prefix, last_k)
            end
        end

        local k = ks[i]
        prefix = prefix .. '.' .. k

        if node[k] == nil then
            node[k] = {}
        end

        if type(node[k]) ~= 'table' then
            if opts.override then
                node[k] = {}
            else
                return nil, 'NotTable', 'found non-table field: ' .. prefix
            end
        end

        node = node[k]
    end

    return tbl, nil, nil
end


local function get_updated_v(tbl, k, v, opts, ref_table)
    if tbl[k] ~= nil and opts.force == false then
        return tbl[k]
    end

    if opts.recursive == false then
        return v
    end

    if type(v) ~= 'table' then
        return v
    end

    if ref_table[v] ~= nil then
        return ref_table[v]
    end

    if type(tbl[k]) ~= 'table' then
        tbl[k] = {}
    end

    ref_table[v] = tbl[k]

    return _M.update(tbl[k], v, opts, ref_table)
end


function _M.update(tbl, src, opts, ref_table)
    opts = opts or {}

    if ref_table == nil then
        ref_table = {}
    end

    for k, v in pairs(src) do
        tbl[k] = get_updated_v(tbl, k, v, opts, ref_table)
    end

    return tbl
end


function _M.make_setter(key, val, mode)

    local func

    if mode == nil then
        mode = 'replace'
    end

    assert(valid_setter_mode[mode], 'arg "mode" is not valid: ')

    if type(key) == 'table' then
        local tbl = key
        func = function(dst)
            for k, v in pairs(tbl) do
                if dst[k] == nil or mode == 'replace' then
                    dst[k] = _get_value_to_set(v, dst[k])
                end
            end
        end
    else
        func = function(dst)
            if dst[key] == nil or mode == 'replace' then
                dst[key] = _get_value_to_set(val, dst[key])
            end
        end
    end

    return func
end


function _M.default_setter(key, val)
    return _M.make_setter(key, val, 'keep')
end

local function _combine_internal(a, b, opts, copy_return, operator, exclude)

    local rst = a

    if copy_return then
        rst = _M.dup(a, true)
    end

    if opts == nil then
        opts = {}
    end

    if exclude == nil then
        exclude = {}
    end

    for k, v in pairs(b) do

        local sub_exclude = exclude[k]

        if sub_exclude ~= true then

            if type(v) == type(a[k]) then

                if type(v) == 'number' then
                    rst[k] = operator(a[k], v)
                end

                if type(v) == 'table' and opts.recursive == true then
                    rst[k] = _combine_internal(a[k], v, opts, copy_return, operator, sub_exclude)
                end
            else
                if a[k] == nil and opts.default ~= nil then
                    if type(v) == 'number' then
                        rst[k] = operator(opts.default, v)
                    end
                    if type(v) == 'table' and opts.recursive == true then
                        rst[k] = _combine_internal({}, v, opts, copy_return, operator, sub_exclude)
                    end
                end
            end
        end
    end

    return rst
end

function _M.combine(a, b, operator, opts)
    if opts == nil then
        opts = {}
    end

    return _combine_internal(a, b, opts, true, operator, opts.exclude)
end

function _M.combineto(a, b, operator, opts)
    if opts == nil then
        opts = {}
    end
    _combine_internal(a, b, opts, false, operator, opts.exclude)
end

local function _add_function(a, b)
    return a + b
end

function _M.add(a, b, opts)
    return _M.combine(a, b, _add_function, opts)
end

function _M.addto(a, b, opts)
    return _M.combineto(a, b, _add_function, opts)
end

return _M
