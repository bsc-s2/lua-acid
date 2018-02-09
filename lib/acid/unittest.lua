--[[

Usage:

$ cat test_empty.lua
> function test.foo(t)
>     t:eq( 0, 0, '0 is 0' )
> end
$ lua -l unittest test_empty.lua

-   Global variable `test`:

    is predefined container table for every `test_*.lua`.
    All functions defined in `test` will be run by `unittest.lua`.

-   Argument `t`:

    is a table that provides assertion function, like:

    -   t:unpack(table_value)                              unpack a table.
    -   t:case_iter(n_column, cases)                       loop over cases table. unpack each case.
    -   t:ass(bool_value, expection_desc, case_message)    general assert. You do not need this.
    -   t:eq(a, b, case_message)                           assert a==b
    -   t:neq(a, b, case_message)                          assert a~=b
    -   t:err(func, case_message)                          assert func() raise an error
    -   t:eqlist(a, b, case_message)                       assert int-index elements of a and b are the same. no recursive.
    -   t:eqdict(a, b, case_message)                       assert a and b are the same as dictionary. no recursive.
    -   t:contain(a, b, case_message)                      assert b contains a.
--]]

local ngx = ngx

local _M = { _VERSION = '0.1' }

_M.debug = false

local function _keys(tbl)
    local n = 0
    local ks = {}
    for k, _ in pairs( tbl ) do
        table.insert( ks, k )
        n = n + 1
    end
    table.sort( ks, function(a, b) return tostring(a)<tostring(b) end )
    return ks, n
end


local function extend(lst, sublines)
    for _, sl in ipairs(sublines) do
        table.insert( lst, sl )
    end
    lst[ #lst ] = lst[ #lst ] .. ','
end


local function _repr_lines(t, ref_table)

    local tp = type(t)

    if t ~= nil then
        if tp == 'table' or t == 'cdata' then
            if ref_table[t] ~= nil then
                return {'...'}
            end

            ref_table[t] = true
        end
    end


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


local function _is_fn_a_test( fn )
    return fn:sub( 1, 5 ) == 'test_' and fn:sub( -4, -1 ) == '.lua'
end


local function _scandir(directory)
    local t = {}
    for filename in io.popen('ls "'..directory..'"'):lines() do
        table.insert( t, filename )
    end
    return t
end


local testfuncs = {

    unpack = function(self, tbl)
        -- by default, in luajit unpack ignores all elements after a nil.
        -- table.maxn() is required.
        return unpack(tbl, 1, table.maxn(tbl))
    end,

    case_iter = function(self, n, cases)

        local i = 0

        return function()

            i = i + 1

            local case = cases[i]

            if case == nil then
                -- iteration complete
                return nil
            end

            local desc = 'case: ' .. tostring(i) .. '-th: ' .. _M.to_str(case)
            dd()
            dd(desc)

            -- if there is no desc for a case, add a default one
            if case[n + 1] == nil then
                case[n + 1] = desc
            else
                case[n + 1] = case[n + 1] .. ': ' .. desc
            end

            -- add index
            return i, unpack(case, 1, n + 1 + 1)
        end
    end,

    ass = function (self, expr, expection, mes)
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

        if ngx then
            if not expr then
                ngx.say(pos .. '   expect ' .. expection .. ' (' .. mes .. ')' )
                error('expect ' .. expection .. ' (' .. mes .. ')')
            end
        else
            assert( expr, pos .. '   expect ' .. expection .. ' (' .. mes .. ')' )
        end
        self._suite.n_assert = self._suite.n_assert + 1
    end,

    eq = function( self, a, b, mes )
        self:ass( a==b, 'to be ' .. to_str(a) .. ' but is ' .. to_str(b), mes )
    end,

    neq = function( self, a, b, mes )
        self:ass( a~=b, 'not to be' .. to_str(a) .. ' but the same: ' .. to_str(b), mes )
    end,

    err = function ( self, func, mes )
        local ok, rst = pcall( func )
        dd('ok: ', ok)
        dd('error msg: ', rst)
        self:eq( false, ok, mes )
    end,

    eqlist = function( self, a, b, mes )

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

    eqdict = function( self, a, b, mes )
        mes = mes or ''

        if a == b then
            return
        end

        self:neq( nil, a, "left table is not nil " .. mes )
        self:neq( nil, b, "right table is not nil " .. mes )
        local akeys = _keys( a )
        local bkeys = _keys( b )

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

    contain = function( self, a, b, mes )
        self:neq( nil, a, "left table is not nil" )
        self:neq( nil, b, "right table is not nil" )

        for k, e in pairs(a) do
            self:ass( e==b[k], '["' .. k .. '"] to be ' .. to_str(e) .. ' but is ' .. to_str(b[k]), mes )
        end
    end,
}
local t_metatable = { __index= testfuncs }


local function _run_one_test_func( suite, name, func )

    info( "   * testing ", name, ' ...' )

    local tfuncs = {}
    setmetatable( tfuncs, t_metatable )
    tfuncs._name = name
    tfuncs._suite = suite

    local co = coroutine.create( func )
    local ok, rst = coroutine.resume( co, tfuncs )

    if not ok then
        info( rst )
        info( debug.traceback(co) )
        error('fail')
    end
    suite.n = suite.n + 1
end


local function _run_one_test_module(suite, test)

    local names = {}

    for k, v in pairs(test) do
        if k ~= 'dd' then
            table.insert(names, {k, v})
        end
    end

    table.sort(names, function(x, y) return x[ 1 ]<y[ 1 ] end)

    for _, t in ipairs(names) do
        local funcname, func = t[ 1 ], t[ 2 ]
        _run_one_test_func( suite, funcname, func )
    end
end


local function _test_module(suite, module_name)

    -- a global var, to let test-case function to access dd()
    _G.test = {dd=dd}

    -- load test file
    require( module_name )

    _run_one_test_module(suite, _G.test)

    -- unload test file
    package.loaded[module_name] = nil
end


local function _test_modules(module_names)

    local suite = { n=0, n_assert=0 }

    for _, module_name in ipairs(module_names) do

        info( "---- ", module_name, ' ----' )

        _test_module(suite, module_name)
    end

    info( suite.n, ' tests all passed. nr of assert: ', suite.n_assert )
end


_M.to_str = to_str
_M.dd = dd


function _M.output(s)
    if ngx then
        ngx.say(s)
        print(s)
    else
        print(s)
    end
end


function _M.ngx_test_modules(module_names, opts)
    -- In nginx, do not raise error to interrupt lua execution.
    -- We check test output to see if it succeeded("** all tests passed")
    -- or failed.

    opts = opts or {}

    _M.debug = opts.debug or false

    local ok, err = pcall(_test_modules, module_names)
    if not ok then
        local errmsg = 'failed to run _test_modules: ' .. err
        _M.output(errmsg)
    end
end


function _M.cli_test_dir( dir )

    package.path = package.path .. ';'..dir..'/?.lua'

    local fns = _scandir( dir )
    local module_names = {}

    for _, fn in ipairs(fns) do

        if _is_fn_a_test( fn ) then
            local module_name = fn:sub(1, -5)
            table.insert(module_names, module_name)
        end
    end

    _test_modules(module_names)
end


function _M.cli_test_file(fn)

    local module_name = fn:sub(1, -5)
    local suite = { n=0, n_assert=0 }

    info( "---- ", fn, ' ----' )

    _test_module(suite, module_name)

    info( suite.n, ' tests all passed. nr of assert: ', suite.n_assert )
end


function _M.cli_main()

    _M.debug = (os.getenv('LUA_UNITTEST_DEBUG') == '1')

    if arg == nil then
        -- lua -l unittest
        _M.cli_test_dir( '.' )
        os.exit()
    else
        _M.cli_test_file(arg[1])
        -- require( "unittest" )
    end
end


if ngx then
    -- nginx lua: run by _M.test_modules()
else
    -- command line
    _M.cli_main()
end


return _M
