local repr = require( "acid.repr" )
local strutil = require('acid.strutil')


local _M = { _VERSION = '0.1' }

_M.repr = repr.repr
_M.str = repr.str

math.randomseed(os.time() * 1000)

-- TODO add doc
function _M.nkeys(tbl)
    return #_M.keys(tbl)
end


-- TODO add doc
function _M.keys(tbl)
    local ks = {}
    for k, _ in pairs(tbl) do
        table.insert( ks, k )
    end
    return ks
end


-- TODO add doc
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


-- TODO add doc
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


-- TODO add doc
function _M.eq(a, b)
    return _M.contains(a, b) and _M.contains(b, a)
end


-- TODO add doc
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


-- TODO add doc
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


-- TODO add doc
function _M.union(tables, val)
    local t = {}

    for _, tbl in ipairs(tables) do
        for k, v in pairs(tbl) do
            t[ k ] = val or v
        end
    end
    return t
end


-- TODO add doc
function _M.merge(tbl, ...)
    for _, src in ipairs({...}) do
        for k, v in pairs(src) do
            tbl[ k ] = v
        end
    end
    return tbl
end


-- TODO add doc
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


-- TODO add doc
function _M.deep_iter(tbl)

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


-- TODO add doc
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


-- TODO add doc
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


-- TODO add doc
function _M.remove_all(tbl, value)

    local removed = 0
    while _M.remove_value(tbl, value) ~= nil do
        removed = removed + 1
    end

    return removed
end


-- TODO add doc
function _M.get_len(tbl)
    local len = 0
    for _, _ in pairs(tbl) do
        len = len + 1
    end

    return len
end


-- TODO add doc
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


-- TODO add doc
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


-- TODO add doc
function _M.is_empty(tbl)
    if type(tbl) == 'table' and next(tbl) == nil then
        return true
    else
        return false
    end
end


-- TODO add doc
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


-- TODO add doc
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


return _M
