local repr = require( "acid.repr" )

local math_floor = math.floor
local string_find = string.find
local string_sub = string.sub
local table_insert = table.insert

local repr_str = repr.str

local _M = { _VERSION = "0.1" }


local function normalize_split_opts(opts)

    if opts == nil then
        opts = {}
    end

    if type(opts) == 'boolean' then
        opts = {plain = opts}
    elseif type(opts) == 'number' then
        opts = {plain = true, maxsplit = opts}
    end

    return opts
end

function _M.split( str, pat, opts )

    opts = normalize_split_opts(opts)

    local plain = opts.plain
    local maxsplit = opts.maxsplit or -1
    local nsplit = 0
    local t = {}  -- NOTE: use {n = 0} in Lua-5.0

    if maxsplit == 0 then
        return {str}
    end

    if pat == '' then
        for i = 1, #str do
            table_insert(t, string_sub(str, i, i))

            nsplit = nsplit + 1
            if nsplit == maxsplit then
                break
            end
        end

        if nsplit < #str then
            table_insert(t, string_sub(str, nsplit + 1))
        end

        t[1] = t[1] or ''
        return t
    end

    local last_end, s, e = 1, 1, 0

    while s do
        s, e = string_find( str, pat, last_end, plain )
        if s then
            table_insert(t, string_sub(str, last_end, s-1))
            last_end = e + 1

            nsplit = nsplit + 1
            if nsplit == maxsplit then
                break
            end
        end
    end

    table_insert(t, string_sub(str, last_end))
    return t
end


local function right_n_split(str, pat, frm, plain, n)

    -- Returns two return value:
    -- -    the offset of the end of the first elt,
    -- -    and following n elts in a table in reversed order.
    --
    -- There is at most n elts in the table.
    --
    -- right_n_split('a/b/c/d', '/', 1, true, 2)
    -- -- 3, {'d', 'c'}

    local s, e
    s, e = string_find(str, pat, frm, plain)

    if s == nil then
        return #str, {}
    end

    local end_of_first, t = right_n_split(str, pat, e + 1, plain, n)

    if #t < n then
        table_insert(t, string_sub(str, e + 1, end_of_first))
        return s - 1, t
    else
        return end_of_first, t
    end
end


_M.right_n_split = right_n_split


function _M.rsplit(str, pat, opts)

    opts = normalize_split_opts(opts)

    local plain = opts.plain
    local maxsplit = opts.maxsplit or -1

    if maxsplit == 0 then
        return {str}
    end

    local t = {}

    if pat == '' then

        local first_len = #str - maxsplit

        if maxsplit == -1 then
            first_len = 1
        else
            if first_len < 1 then
                first_len = 1
            end
        end

        t[1] = string_sub(str, 1, first_len)

        for i = first_len + 1, #str do
            table_insert(t, string_sub(str, i, i))
        end

        return t
    end

    if maxsplit == -1 then
        maxsplit = #str
    end

    local end_of_first, last_n = right_n_split(str, pat, 1, plain, maxsplit)

    t[1] = string_sub(str, 1, end_of_first)

    for i = #last_n, 1, -1 do
        table_insert(t, last_n[i])
    end

    return t
end


function _M.join(sep, ...)
    return table.concat({...}, sep)
end


function _M.strip( s, ptn )

    if ptn == nil or ptn == "" then
        ptn = "%s"
    end

    local r = s:gsub( "^[" .. ptn .. "]+", '' ):gsub( "[" .. ptn .. "]+$", "" )
    return r
end


function _M.startswith( s, pref )
    return string_sub(s, 1, #pref) == pref
end


function _M.endswith( s, suf )
    if suf == '' then
        return true
    end
    return string_sub(s, -#suf, -1) == suf
end


function _M.to_str(...)

    local argsv = {...}
    local v

    for i = 1, select('#', ...) do
        v = argsv[i]
        argsv[i] = repr_str(v)
    end

    return table.concat(argsv)
end


function _M.placeholder(val, pholder)
    pholder = pholder or '-'

    if val == '' or val == nil then
        return pholder
    else
        return tostring(val)
    end
end


function _M.ljust(str, n, ch)
    return str .. string.rep(ch or ' ', n - string.len(str))
end


function _M.rjust(str, n, ch)
    return string.rep(ch or ' ', n - string.len(str)) .. str
end


function _M.replace(s, src, dst)
    return table.concat(_M.split(s, src), dst)
end


local function _parse_fnmatch_char(a1)
    if a1 == "*" then
        return ".*"
    elseif a1 == "?" then
        return "."
    elseif a1 == "." then
        return "[.]"
    else
        return a1
    end
end


function _M.fnmatch(s, ptn)
    local p = ptn
    local p = p:gsub('([\\]*)(.)', function(a0, a1)
        local l = #a0
        if l % 2 == 0 then
            return string.rep('[\\]', l/2).._parse_fnmatch_char(a1)
        else
            return string.rep('[\\]', (l-1)/2)..'['.. a1 ..']'
        end
    end)

    return s:match(p) == s
end


function _M.fromhex(str)
    return (str:gsub('..', function (cc)
        return string.char(tonumber(cc, 16))
    end))
end


function _M.tohex(str)
    return (str:gsub('.', function (c)
        return string.format('%02X', string.byte(c))
    end))
end


function _M.to_chunks(s, n)

    assert(n > 0, 'n must be a number and >= 1')

    if s == '' then
        return {''}
    end

    local rst = {}

    local i = 1
    local j
    while true do
        j = i + n - 1
        local ii = math_floor(i)
        local jj = math_floor(j)
        table_insert(rst, string_sub(s, ii, jj))

        i = j + 1
        if math_floor(i) > #s then
            break
        end
    end

    return rst
end


return _M
