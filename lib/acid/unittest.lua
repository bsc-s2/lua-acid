local _M = { _VERSION='0.1' }

_M.debug = false

local function _keys(tbl)
    local ks = {}
    for k, _ in pairs(tbl) do
        table.insert( ks, k )
    end
    return ks
end


local function extend(lst, sublines)
    for _, sl in ipairs(sublines) do
        table.insert( lst, sl )
    end
    lst[ #lst ] = lst[ #lst ] .. ','
end


local function _repr_lines(t, ref_table)

    if t ~= nil then
        if ref_table[t] ~= nil then
            return {'...'}
        end

        ref_table[t] = true
    end

    local tp = type( t )

    if tp == 'string' then
        -- escape special chars
        local s = string.format('%q', t)
        s = s:sub( 2, -2 )
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
        local sublines = _repr_lines(t[i], ref_table)
        extend(lst, sublines)
        i = i + 1
    end

    for _, k in ipairs(keys) do

        if type(k) ~= 'number' or k > i then

            local sublines = _repr_lines(t[k], ref_table)
            sublines[ 1 ] = tostring(k) ..'='.. sublines[ 1 ]
            extend(lst, sublines)
        end
    end

    -- remove the last ','
    lst[ #lst ] = lst[ #lst ]:sub( 1, -2 )

    table.insert( lst, '}' )
    return lst
end


local function to_str(o)
    return table.concat(_repr_lines(o, {}))
end


_M.to_str = to_str


local function dd(...)
    if not _M.debug then
        return
    end
    local args = {...}
    local s = ''
    for _, mes in ipairs(args) do
        s = s .. _M.to_str(mes)
    end
    _M.output(s)
end


local function info(...)
    local args = {...}
    local s = ''
    for _, mes in ipairs(args) do
        s = s .. _M.to_str(mes)
    end
    _M.output(s)
end


_M.dd = dd


function _M.output(s)
    print(s)
end

local function is_test_file( fn )
    return fn:sub( 1, 5 ) == 'test_' and fn:sub( -4, -1 ) == '.lua'
end

local function scandir(directory)
    local t = {}
    for filename in io.popen('ls "'..directory..'"'):lines() do
        table.insert( t, filename )
    end
    return t
end

local function keys(tbl)
    local n = 0
    local ks = {}
    for k, _ in pairs( tbl ) do
        table.insert( ks, k )
        n = n + 1
    end
    table.sort( ks, function(a, b) return tostring(a)<tostring(b) end )
    return ks, n
end

local testfuncs = {

    ass= function (self, expr, expection, mes)
        mes = mes or ''

        local thisfile = debug.getinfo(1).short_src
        local info
        for i = 2, 10 do
            info = debug.getinfo(i)
            if info.short_src ~= thisfile then
                break
            end
        end

        local pos = 'Failure: \n'
        pos = pos .. '   in ' .. info.short_src .. '\n'
        pos = pos .. '   ' .. self._name .. '():' .. info.currentline .. '\n'

        assert( expr, pos .. '   expect ' .. expection .. ' (' .. mes .. ')' )
        self._suite.n_assert = self._suite.n_assert + 1
    end,

    eq= function( self, a, b, mes )
        self:ass( a==b, 'to be ' .. to_str(a) .. ' but is ' .. to_str(b), mes )
    end,

    neq= function( self, a, b, mes )
        self:ass( a~=b, 'not to be' .. to_str(a) .. ' but the same: ' .. to_str(b), mes )
    end,

    err= function ( self, func, mes )
        local ok, rst = pcall( func )
        self:eq( false, ok, mes )
    end,

    eqlist= function( self, a, b, mes )

        if a == b then
            return
        end

        self:neq( nil, a, "left list is not nil " .. (mes or '') )
        self:neq( nil, b, "right list is not nil " .. (mes or '') )

        for i, e in ipairs(a) do
            self:ass( e==b[i], i .. 'th elt to be ' .. to_str(e) .. ' but is ' .. to_str(b[i]), mes )
        end
        -- check if b has more elements
        for i, e in ipairs(b) do
            self:ass( nil~=a[i], i .. 'th elt to be nil but is ' .. to_str(e), mes )
        end
    end,

    eqdict= function( self, a, b, mes )
        mes = mes or ''

        if a == b then
            return
        end

        self:neq( nil, a, "left table is not nil " .. mes )
        self:neq( nil, b, "right table is not nil " .. mes )
        local akeys = keys( a )
        local bkeys = keys( b )

        for _, k in ipairs( akeys ) do
            self:ass( b[k] ~= nil, '["' .. k .. '"] in right but not. '.. mes )
        end
        for _, k in ipairs( bkeys ) do
            self:ass( a[k] ~= nil, '["' .. k .. '"] in left but not. '.. mes )
        end
        for _, k in ipairs( akeys ) do
            local av, bv = a[k], b[k]
            if type( av ) == 'table' and type( bv ) == 'table' then
                self:eqdict( av, bv, k .. '<' .. mes )
            else
                self:ass( a[k] == b[k],
                '["' .. k .. '"] to be ' .. to_str(a[k]) .. ' but is ' .. to_str(b[k]), mes )
            end
        end

    end,

    contain= function( self, a, b, mes )
        self:neq( nil, a, "left table is not nil" )
        self:neq( nil, b, "right table is not nil" )

        for k, e in pairs(a) do
            self:ass( e==b[k], '["' .. k .. '"] to be ' .. to_str(e) .. ' but is ' .. to_str(b[k]), mes )
        end
    end,

}


local _mt = { __index= testfuncs }


function _M.test_one( suite, name, func )

    info( "   * testing ", name, ' ...' )

    local tfuncs = {}
    setmetatable( tfuncs, _mt )
    tfuncs._name = name
    tfuncs._suite = suite

    local co = coroutine.create( func )
    local ok, rst = coroutine.resume( co, tfuncs )

    if not ok then
        info( rst )
        info( debug.traceback(co) )
        os.exit(1)
    end
    suite.n = suite.n + 1
end

function _M.test_all(test, suite)

    local names = {}

    for k, v in pairs(test) do
        if k ~= 'dd' then
            table.insert(names, {k, v})
        end
    end

    table.sort(names, function(x, y) return x[ 1 ]<y[ 1 ] end)

    for _, t in ipairs(names) do
        local funcname, func = t[ 1 ], t[ 2 ]
        _M.test_one( suite, funcname, func )
    end
end

function _M.testdir( dir )

    package.path = package.path .. ';'..dir..'/?.lua'

    local suite = { n=0, n_assert=0 }
    local fns = scandir( dir )

    for _, fn in ipairs(fns) do

        if is_test_file( fn ) then

            info( "---- ", fn, ' ----' )

            test = {dd=dd}
            require( fn:sub( 1, -5 ) )

            _M.test_all(test, suite)
        end
    end
    info( suite.n, ' tests all passed. nr of assert: ', suite.n_assert )
    return true
end

function _M.t()

    _M.debug = (os.getenv('LUA_UNITTEST_DEBUG') == '1')

    if arg == nil then
        -- lua -l unittest
        _M.testdir( '.' )
        os.exit()
    else
        -- require( "unittest" )
    end
end
_M.t()

return _M
