local ffiutil = require('acid.ffiutil')
local ffi = require('ffi')
local strutil = require('acid.strutil')

local dd  = test.dd

ffi.cdef[[
    struct foo { int x; int y; unsigned long z;int f[2];};

    typedef struct {
        int a;
        char b[10] ;
        double c;
        unsigned long d;

        struct foo e[1];
    }   SIMPLE_123;
]]


function test.str_to_clong(t)
    local cases = {
        { '-10000000000000000000000000000',         nil,            'nil','OutOfRange'      },
        { '',                                       nil,            'nil','InvalidArgument' },
        { '',                                       'u',            'nil','InvalidArgument' },
        { 'abcdffdd',                               nil,            'nil','InvalidArgument' },
        { 'abcdff',                                 'u',            'nil','InvalidArgument' },
        { 'abc123',                                 nil,            'nil','InvalidArgument' },
        { '122abc',                                 nil,            'nil','InvalidArgument' },
        { ' 123',                                   nil,            'nil','InvalidArgument' },
        { '123 ',                                   nil,            'nil','InvalidArgument' },
        { '10000000000000000000000000000',          nil,            'nil','OutOfRange'      },
        { '10000000000000000000000000000',          'u',            'nil','OutOfRange'      },
        { '0',                                      nil,            '0LL',nil               },
        { '0',                                      'u',            '0ULL',nil              },
        { '-10',                                    nil,            '-10LL',nil             },
        { '100',                                    nil,            '100LL',nil             },
        { '100',                                    'u',            '100ULL',nil            },
    }

    for _, case in pairs(cases) do
        local val, mode, rst_expected,err_expected = t:unpack(case)

        local rst, err, errmsg = ffiutil.str_to_clong(val, mode)

        t:eq(rst_expected,tostring(rst))
        t:eq(err_expected,err)
    end
end

function test.clong_to_str(t)
    local cases = {
        { 1,                                'u', 'unsigned long',                   '1' },
        { -1,                                nil, 'long',                           '-1' },
        { '18446744073709551615',            'u', 'unsigned long',                  '18446744073709551615' },
        { '0',                               'u', 'unsigned long',                  '0' },
        { 10000000000000000000000000000,     'u', 'unsigned long',                  '0' },
        { 10000000000000000000000000000,     nil, 'long',                           '-9223372036854775808' },
    }

    for _, case in pairs(cases) do
        local val, mode, new_mode, expected = t:unpack(case)
        if type(val) == 'string' then
            t:eq(expected, ffiutil.clong_to_str(ffiutil.str_to_clong(val, mode)))
        else
            t:eq(expected, ffiutil.clong_to_str(ffi.new(new_mode, val)))
        end
    end
end


function test.carray_to_tbl(t)
    local converter = function(val)
        return ffiutil.clong_to_str(val)
    end

    local bad_converter = function(val)
        return nil, 'Bad', 'Bad value'
    end

    local cases = {
    { ffi.new('unsigned long[2]',{1,2}),                                                        {'1','2'},},
    { ffi.new('unsigned long[2]',{1,ffiutil.str_to_clong('18446744073709551615','u')}),         {'1','18446744073709551615'},},
    }

    for _,case in pairs(cases) do
        local cdata_obj, expected =t:unpack(case)

        local rst, err, errmsg = ffiutil.carray_to_tbl(cdata_obj, 2, converter)

        t:eqdict(expected, rst  )
        t:eq(nil,err)
        t:eq(nil,errmsg)

        local rst, err, errmsg = ffiutil.carray_to_tbl(cdata_obj, 2, bad_converter)
        t:eq(nil,rst)
        t:eq('Bad',err)
        t:eq('index:0, error:Bad value',errmsg)

    end

end

function test.tbl_to_carray(t)
    local converter = function(val)
        return ffiutil.str_to_clong(val,'u')
    end


    local cases = {
        { { '18446744073709551615','1' },           { '18446744073709551615','1' },         nil,                nil },
        { { '18446744073709551a615','1' },          nil,                                    'InvalidArgument',  'index:1, error:18446744073709551a615 was not a valid number string' },
        { { '18446744073709551615','1a' },          nil,                                    'InvalidArgument',  'index:2, error:1a was not a valid number string' },

    }

    for _,case in pairs(cases) do

        local inp, rst_expected, err_expected, errmsg_expected = t:unpack(case)

        local rst, err, errmsg = ffiutil.tbl_to_carray('unsigned long[2]',inp, converter)
        if rst ~= nil then
            t:eqdict(rst_expected, ffiutil.carray_to_tbl(rst, 2, ffiutil.clong_to_str))
        else
            t:eq(rst_expected,rst)
        end
        t:eq(err_expected,err)
        t:eq(errmsg_expected,errmsg)
    end

end


local function serialize_sample(sample)

    local string_char = function(val)
        if val == 0 then
            return nil
        end
        return string.char(val)
    end

    local schema_cdata_to_tbl = {
        a = tonumber,
        b = function(val)
                return table.concat(ffiutil.carray_to_tbl(val, 10, string_char))
            end,
        c = function(val)
                local rst = tonumber(val)
                if rst > 100 then
                    return nil, 'OutOfRange', string.format('%s was out of range',rst)
                end
                return rst, nil, nil
            end,
        d = ffiutil.clong_to_str,
        e = {{
            x = tonumber,
            y = function(val)
                local rst = tonumber(val)
                if rst > 100 then
                    return nil, 'OutOfRange', string.format('%s was out of range',rst)
                end
                return rst, nil, nil
            end,
            z = ffiutil.clong_to_str,
            f = {
                tonumber,
                tonumber,
            },
        }}
    }

    return ffiutil.cdata_to_tbl(sample, schema_cdata_to_tbl)

end

function test.cdata_to_tbl(t)

    local cases = {
        {
            {
                a=1,
                b=ffi.new("char[10]",'adccccc'),
                c=1.5,
                d=ffiutil.str_to_clong('18446744073709551615', 'u'),
                e={{
                    x=10,
                    y=10,
                    z=ffiutil.str_to_clong('18446744073709551615','u'),
                    f=ffiutil.tbl_to_carray("int[2]",{1,2}),
                }}
            },
            {
                a=1,
                b='adccccc',
                c=1.5,
                d='18446744073709551615',
                e={{
                    x=10,
                    y=10,
                    z='18446744073709551615',
                    f={1,2},
                }}
            },
            nil,
            nil
        },

        {
            {
                a=1,
                b=ffi.new("char[10]",'adccccc'),
                c=101,
                d=ffiutil.str_to_clong('18446744073709551615', 'u'),
                e={{
                    x=10,
                    y=10,
                    z=ffiutil.str_to_clong('18446744073709551615','u'),
                    f=ffiutil.tbl_to_carray("int[2]",{1,2}),
                }}
            },
            nil,
            'OutOfRange',
            'c error:101 was out of range'
        },

        {
            {
                a=1,
                b=ffi.new("char[10]",'adccccc'),
                c=1,
                d=ffiutil.str_to_clong('18446744073709551615', 'u'),
                e={{
                    x=10,
                    y=101,
                    z=ffiutil.str_to_clong('18446744073709551615','u')
                }}
            },
            nil,
            'OutOfRange',
            'e.1.y error:101 was out of range'
        },
    }

    for _, case in pairs(cases) do

        local inp, rst_expected, err_expected, errmsg_expected = t:unpack(case)
        local cdata_obj = ffi.new('SIMPLE_123', inp)
        local rst, err, errmsg = serialize_sample(cdata_obj)
        if rst ~= nil then
            t:eqdict(rst_expected, rst)
        else
            t:eq(rst_expected, rst)
        end
        t:eq(err_expected, err)
        t:eq(errmsg_expected, errmsg)
    end

end


function test.tbl_to_cdata(t)


    local schema_tbl_to_cdata = {
        b = function(val) return ffiutil.tbl_to_carray('char[10]', strutil.split(val, ''), string.byte) end,
        d = function(val) return ffiutil.str_to_clong(val, 'u') end,
        e = {{ z = function(val) return ffiutil.str_to_clong(val, 'u') end }},
    }

    local cases = {
        {
            {
                a = 1,
                b = 'adccccc',
                c = 1.5,
                d = '18446744073709551615',
                e = {{ x = 10, y = 10, z='100', f={1,2} }}
            },
            {
                a = 1,
                b = 'adccccc',
                c = 1.5,
                d = '18446744073709551615',
                e = {{ x = 10, y = 10, z ='100', f={1,2} }}
            },
            nil,
            nil
        },

        {
            {
                a = 1,
                b = 'adccccc',
                c = 1.5,
                d = '184a46744073709551615',
                e = {{ x = 10, y = 10, z='100', f={1,2} }}
            },
            nil,
            'InvalidArgument',
            'd error:184a46744073709551615 was not a valid number string'
        },

        {
            {
                a = 1,
                b = 'adccccc',
                c = 1.5,
                d = '18446744073709551615',
                e = {{ x = 10, y = 10, z='1a00', f={1,2} }}
            },
            nil,
            'InvalidArgument',
            'e.1.z error:1a00 was not a valid number string'
        },

    }

    for _, case in pairs(cases) do

        local inp, rst_expected, err_expected, errmsg_expected = t:unpack(case)
        local rst, err, errmsg = ffiutil.tbl_to_cdata("SIMPLE_123", inp, schema_tbl_to_cdata)
        if rst ~=nil then
            t:eqdict(rst_expected,serialize_sample(rst))
        else
            t:eq(rst_expected,rst)
        end
        t:eq(err_expected,err)
        t:eq(errmsg_expected,errmsg)
    end

end
