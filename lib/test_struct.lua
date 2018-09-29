local struct = require("acid.struct")
local strutil = require("acid.strutil")

local char = string.char
local to_str = strutil.to_str


function test.pack_and_unpack_int32(t)
    local cases = {
        {0x01,          char(0x00) .. char(0x00) .. char(0x00) .. char(0x01)},
        {0x10,          char(0x00) .. char(0x00) .. char(0x00) .. char(0x10)},
        {0x0100,        char(0x00) .. char(0x00) .. char(0x01) .. char(0x00)},
        {0x0101,        char(0x00) .. char(0x00) .. char(0x01) .. char(0x01)},
        {0x010000,      char(0x00) .. char(0x01) .. char(0x00) .. char(0x00)},
        {0x010100,      char(0x00) .. char(0x01) .. char(0x01) .. char(0x00)},
        {0x010101,      char(0x00) .. char(0x01) .. char(0x01) .. char(0x01)},
        {0x01000000,    char(0x01) .. char(0x00) .. char(0x00) .. char(0x00)},
        {0x01010000,    char(0x01) .. char(0x01) .. char(0x00) .. char(0x00)},
        {0x01010100,    char(0x01) .. char(0x01) .. char(0x01) .. char(0x00)},
        {0x01010101,    char(0x01) .. char(0x01) .. char(0x01) .. char(0x01)},
    }
    local num, str, pack_str, unpack_num
    for _, case in ipairs(cases) do
        num, str = case[1], case[2]

        pack_str = struct.pack_int32(num)
        t:eq(str, pack_str)

        pack_str = struct.pack_int32(num, true)
        t:eq(string.reverse(str), pack_str)

        unpack_num = struct.unpack_int32({stream=str, offset=1}, false, false)
        t:eq(num, unpack_num)

        unpack_num = struct.unpack_int32({stream=string.reverse(str), offset=1}, true, false)
        t:eq(num, unpack_num)
    end

    cases = {
        {-1,                                char(0xff) .. char(0xff) .. char(0xff) .. char(0xff)},
        {-(2 ^ 4),                          char(0xff) .. char(0xff) .. char(0xff) .. char(0xf0)},
        {-(2 ^ 8),                          char(0xff) .. char(0xff) .. char(0xff) .. char(0x00)},
        {-(2 ^ 8 + 1),                      char(0xff) .. char(0xff) .. char(0xfe) .. char(0xff)},
        {-(2 ^ 16),                         char(0xff) .. char(0xff) .. char(0x00) .. char(0x00)},
        {-(2 ^ 16 + 2 ^ 8),                 char(0xff) .. char(0xfe) .. char(0xff) .. char(0x00)},
        {-(2 ^ 16 + 2 ^ 8 + 1),             char(0xff) .. char(0xfe) .. char(0xfe) .. char(0xff)},
        {-(2 ^ 24),                         char(0xff) .. char(0x00) .. char(0x00) .. char(0x00)},
        {-(2 ^ 24 + 2 ^ 16),                char(0xfe) .. char(0xff) .. char(0x00) .. char(0x00)},
        {-(2 ^ 24 + 2 ^ 16 + 2 ^ 8),        char(0xfe) .. char(0xfe) .. char(0xff) .. char(0x00)},
        {-(2 ^ 24 + 2 ^ 16 + 2 ^ 8 + 1),    char(0xfe) .. char(0xfe) .. char(0xfe) .. char(0xff)},
    }
    local num, str, pack_str, unpack_num
    for _, case in ipairs(cases) do
        num, str = case[1], case[2]

        pack_str = struct.pack_int32(num)
        t:eq(str, pack_str)

        pack_str = struct.pack_int32(num, true)
        t:eq(string.reverse(str), pack_str)

        unpack_num = struct.unpack_int32({stream=str, offset=1}, false, true)
        t:eq(num, unpack_num)

        unpack_num = struct.unpack_int32({stream=string.reverse(str), offset=1}, true, true)
        t:eq(num, unpack_num)
    end

    local err_cases = {
        {'abc', 'TypeError', 'input must be a number'},
        {-2 ^ 31 - 1, 'ValueError', 'input requires -2 ^ 31 <= val <= 2 ^ 32 - 1'},
        {2 ^ 32, 'ValueError', 'input requires -2 ^ 31 <= val <= 2 ^ 32 - 1'},
    }

    for _, c in ipairs(err_cases) do
        local _, err, errmsg = struct.pack_int32(c[1])
        t:eq(c[2], err)
        t:eq(c[3], errmsg)
    end

    local _, err, errmsg = struct.unpack_int32({stream=char(22), offset=1})
    t:eq('ValueError', err)
    t:eq('expected:4 chars got:1 chars', errmsg)
end


function test.pack_and_unpack_string(t)
    local cases = {
        '',
        '123',
        '#j()',
        'abc',
        'abc&23',
    }

    for _, c in ipairs(cases) do
        local s = struct.pack_string(c)

        t:eq(struct.pack_int32(#c) .. c, s)
        t:eq(c, struct.unpack_string({stream=s, offset=1}))
    end

    t:eq('', struct.unpack_string({stream=struct.pack_int32(0), offset=1}))

    local _, err, errmsg = struct.unpack_string({stream=struct.pack_int32(-1), offset=1})
    t:eq('ValueError', err)
    t:eq('expected: length >= 0 got:-1', errmsg)

    local _, err, errmsg = struct.unpack_string({stream=char(22), offset=1})
    t:eq('ValueError', err)
end


function test.pack_and_unpack(t)
    local cases = {
        {'i', {1}, struct.pack_int32(1), 'i'},
        {'>i', {2}, struct.pack_int32(2), '>i'},
        {'<i', {3}, struct.pack_int32(3, true), '<i'},
        {'I', {4}, struct.pack_int32(4), 'I'},
        {'>I', {5}, struct.pack_int32(5), '>I'},
        {'<I', {6}, struct.pack_int32(6, true), '<I'},
        {'s', {'foo'}, 'foo', '3s'},
        {'ss', {'foo', 'bar'}, 'foobar', '3s3s'},
        {'sss', {'foo', 'foo', 'foo'}, 'foofoofoo', '3s3s3s'},
        {'S', {'bar'}, struct.pack_string('bar'), 'S'},
        {'iIsS', {12, 123, 'foo', 'bar'}, struct.pack_int32(12) .. struct.pack_int32(123) .. 'foo' .. struct.pack_string('bar'), 'iI3sS'},
        {'>iIsS', {12, 123, 'foo', 'bar'}, struct.pack_int32(12) .. struct.pack_int32(123) .. 'foo' .. struct.pack_string('bar'), '>iI3sS'},
        {'<iIsS', {12, 123, 'foo', 'bar'}, struct.pack_int32(12, true) .. struct.pack_int32(123, true) .. 'foo' .. struct.pack_string('bar'), '<iI3sS'},
    }

    for _, c in ipairs(cases) do
        local r = struct.pack(c[1], unpack(c[2]))
        t:eq(c[3], r)

        r = struct.unpack(c[4], {stream=c[3], offset=1})
        t:eq(to_str(c[2]), to_str(r))
    end

    local _, err, errmsg = struct.pack('&')
    t:eq('UnsupportFormat', err)

    local _, err, errmsg = struct.unpack('z')
    t:eq('UnsupportFormat', err)

    local _, err, errmsg = struct.unpack('3s', {stream='f', offset=1})
    t:eq('ValueError', err)

    local _, err, errmsg = struct.unpack('s', {stream='f', offset=1})
    t:eq('ValueError', err)
end
