local repr = require( "acid.repr" )

local tonumber = tonumber

local math_floor    = math.floor
local string_byte   = string.byte
local string_char   = string.char
local string_find   = string.find
local string_format = string.format
local string_gsub   = string.gsub
local string_sub    = string.sub
local table_concat  = table.concat
local table_insert  = table.insert

local repr_str = repr.str

local _M = { _VERSION = "0.1" }

local special_char = {
    ["^"] = "%^",
    ["$"] = "%$",
    ["("] = "%(",
    [")"] = "%)",
    ["%"] = "%%",
    ["."] = "%.",
    ["["] = "%[",
    ["]"] = "%]",
    ["*"] = "%*",
    ["+"] = "%+",
    ["-"] = "%-",
    ["?"] = "%?",
}

local fnmatch_wildcard_translate = {
    ['*'] = '.*',
    ['?'] = '.',
    ['.'] = '[.]',
}

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


function _M.strip(str, ptn)

    local pattern

    if ptn == nil or ptn == "" then
        pattern = "%s"
    else

        pattern = {}

        for i = 1, #ptn do
            local chr = string_sub(ptn, i, i)
            chr = special_char[chr] or chr
            table_insert(pattern, chr)
        end

        pattern = table_concat(pattern)
    end

    local r = str:gsub( "^[" .. pattern .. "]+", '' ):gsub( "[" .. pattern .. "]+$", "" )
    return r
end


function _M.startswith(str, prefix, start)
    start = start or 1

    if type(prefix) == 'table' then
        for ii, pref in ipairs(prefix) do
            if _M.startswith(str, pref, start) then
                return true
            end
        end
        return false
    else
        return string_sub(str, start, start - 1 + #prefix) == prefix
    end
end


function _M.endswith(str, suffix)
    if suffix == '' then
        return true
    end

    if type(suffix) == 'table' then
        for ii, pref in ipairs(suffix) do
            if _M.endswith(str, pref) then
                return true
            end
        end
        return false
    else
        return string_sub(str, -#suffix, -1) == suffix
    end
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


function _M.placeholder(val, pholder, float_fmt)
    pholder = pholder or '-'

    if val == '' or val == nil then
        return pholder
    end

    if float_fmt ~= nil
         and type(val) == 'number' and val % 1 ~= 0 then

        return string.format(float_fmt, val)
    end

    return tostring(val)
end


function _M.ljust(str, n, ch)
    return str .. string.rep(ch or ' ', n - string.len(str))
end


function _M.rjust(str, n, ch)
    return string.rep(ch or ' ', n - string.len(str)) .. str
end


function _M.replace(s, src, dst)
    -- TODO no one is using this.. remove it?
    -- TODO test
    return table.concat(_M.split(s, src), dst)
end


function _M.fnmatch(s, ptn)

    ptn = ptn:gsub('([\\]*)(.)', function(backslashes, chr)

        local l = #backslashes

        if l % 2 == 0 then
            -- even number of back slash: not an escape
            return string.rep('[\\]', l/2) .. (fnmatch_wildcard_translate[chr] or chr)
        else
            -- odd number of back slash: an escape of following char
            return string.rep('[\\]', (l-1)/2)..'['.. chr ..']'
        end
    end)

    return s:match(ptn) == s
end


local function _hex_to_char(cc)
    return string_char(tonumber(cc, 16))
end


function _M.fromhex(str)

    assert(type(str) == 'string', 'str must be string')
    assert(#str % 2 == 0, 'str length must be 2n')

    return string_gsub(str, '..', _hex_to_char)
end


local function _char_to_hex(c)
    return string_format('%02X', string_byte(c))
end


function _M.tohex(str)
    assert(type(str) == 'string', 'str must be string')
    return string_gsub(str, '.', _char_to_hex)
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
