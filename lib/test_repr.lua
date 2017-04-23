local repr = require("acid.repr")

local dd = test.dd

local opt_sep_one_space = { sep=' ' }
local opt_sep_two_space = { sep='  ' }

function test.repr(t)

    local cases = {
        {1,               nil,                   '1'},
        {'1',             nil,                   '"1"'},
        {nil,             nil,                   'nil'},
        {{},              nil,                   '{}'},
        {{},              opt_sep_one_space,     '{}'},
        {{ 1 },           opt_sep_one_space,     '{ 1 }'},
        {{ 1, 2 },        opt_sep_one_space,     '{ 1, 2 }'},
        {{ a=1 },         opt_sep_one_space,     '{ a=1 }'},
        {{ 0, a=1, b=2 }, opt_sep_one_space,     '{ 0, a=1, b=2 }'},
        {{ 0, a=1, b=2 }, opt_sep_two_space,     '{  0,  a=1,  b=2  }'},

        {
            {
                1, 2, 3,
                { 1, 2, 3, 4 },
                a=1,
                c=100000,
                d=1,
                x={
                    1,
                    { 1, 2 },
                    y={
                        a=1,
                        b=2
                    }
                },
                ['fjklY*(']={
                    x=1,
                    b=3,
                },
                [100]=33333
            },
            {indent='    '},
            [[{
    1,
    2,
    3,
    {
        1,
        2,
        3,
        4
    },
    [100]=33333,
    a=1,
    c=100000,
    d=1,
    ["fjklY*("]={
        b=3,
        x=1
    },
    x={
        1,
        {
            1,
            2
        },
        y={
            a=1,
            b=2
        }
    }
}]]},
    }

    for ii, c in ipairs(cases) do

        local inp, opt, expected = t:unpack(c)
        local msg = 'case: ' .. tostring(ii) .. '-th '
        dd(msg, c)

        local rst = repr.repr(inp, opt)
        dd('rst: ', rst)

        t:eq(expected, rst, msg)
    end
end


function test.str(t)

    local cases = {
        {1,               nil,                   '1'},
        {'1',             nil,                   '1'},
        {nil,             nil,                   'nil'},
        {{},              nil,                   '{}'},
        {{},              opt_sep_one_space,     '{}'},
        {{ 1 },           opt_sep_one_space,     '{ 1 }'},
        {{ 1, 2 },        opt_sep_one_space,     '{ 1, 2 }'},
        {{ a=1 },         opt_sep_one_space,     '{ a=1 }'},
        {{ 0, a=1, b=2 }, opt_sep_one_space,     '{ 0, a=1, b=2 }'},
        {{ 0, a=1, b=2 }, opt_sep_two_space,     '{  0,  a=1,  b=2  }'},
        {{ 0, a=1, b=2 }, nil,                   '{0,a=1,b=2}'},

        {
            {
                1, 2, 3,
                { 1, 2, 3, 4 },
                a=1,
                c=100000,
                d=1,
                x={
                    1,
                    { 1, 2 },
                    y={
                        a=1,
                        b=2
                    }
                },
                ['fjklY*(']={
                    x=1,
                    b=3,
                },
                [100]=33333
            },
            {indent='    '},
            [[{
    1,
    2,
    3,
    {
        1,
        2,
        3,
        4
    },
    100=33333,
    a=1,
    c=100000,
    d=1,
    fjklY*(={
        b=3,
        x=1
    },
    x={
        1,
        {
            1,
            2
        },
        y={
            a=1,
            b=2
        }
    }
}]]},
    }

    for ii, c in ipairs(cases) do

        local inp, opt, expected = t:unpack(c)
        local msg = 'case: ' .. tostring(ii) .. '-th '
        dd(msg, c)

        local rst = repr.str(inp, opt)
        dd('rst: ', rst)

        t:eq(expected, rst, msg)
    end
end
