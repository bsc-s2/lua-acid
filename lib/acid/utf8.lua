local bit = require('bit')
local strutil = require('acid.strutil')

local _M = {}

local LIMITS = {0x80, 0x800, 0x10000}

local MAX_UNICODE = 0x10FFFF

local LEAD_BITS = {
    [1] = 0xC0, --110x xxxx
    [2] = 0xE0, --1110 xxxx
    [3] = 0xF0, --1111 0xxx
}


local function decode_one_character(utf8_str, index)
    local lead_char = string.sub(utf8_str, index, index)
    local lead_byte = string.byte(lead_char)

    if lead_byte < 0x80 then
        return {code_point=lead_byte, bytes_n=1}, nil, nil
    end

    local continue_n = 0
    local res = 0

    local log_str = strutil.tohex(string.sub(utf8_str, index, index + 7))

    while true do
        if bit.band(lead_byte, 0x40) == 0 then
            break
        end
        continue_n = continue_n + 1

        local continue_char = string.sub(utf8_str, index + continue_n,
                                         index + continue_n)
        if continue_char == '' then
            return nil, 'InvalidUTF8', string.format(
                    'missing continuing byte: %s at index: %d',
                    log_str, index)
        end

        local continue_byte = string.byte(continue_char)

        if bit.band(continue_byte, 0xC0) ~= 0x80 then
            return nil, 'InvalidUTF8', string.format(
                    'invalid continuing byte: %s at index: %d',
                    log_str, index)
        end

        res = bit.lshift(res, 6)
        res = bit.bor(res, bit.band(continue_byte, 0x3F))

        lead_byte = bit.lshift(lead_byte, 1)
    end

    if continue_n > 3 or continue_n < 1 then
        return nil, 'InvalidUTF8', string.format(
                'invalid number of continuing bytes: %d, %s',
                continue_n, log_str)
    end

    lead_byte = bit.band(lead_byte, 0x7F)
    -- here is 5 because the lead_byte had left shifed continue_n bits
    res = bit.bor(res, bit.lshift(lead_byte, continue_n * 5))

    if res > MAX_UNICODE then
        return nil, 'InvalidUTF8', string.format(
                'code point: %d is bigger than max unicode: %d',
                res, MAX_UNICODE)
    end

    if res < LIMITS[continue_n] then
        return nil, 'InvalidUTF8', string.format(
                'code point: %d is smaller than: %d, but consist %s bytes',
                res, LIMITS[continue_n], continue_n + 1)
    end

    return {code_point=res, bytes_n=continue_n+1}, nil, nil
end


function _M.code_point(utf8_str)
    local str_len = #utf8_str

    if str_len == 0 then
        return {}, nil, nil
    end

    local points = {}
    local index = 1

    while true do
        local character, err, errmsg = decode_one_character(utf8_str, index)
        if err ~= nil then
            return nil, err, errmsg
        end

        table.insert(points, character.code_point)
        index = index + character.bytes_n

        if index > str_len then
            break
        end
    end

    return points, nil, nil
end


local function encode_one_point(code_point)
    if code_point > MAX_UNICODE or code_point < 0 then
        return nil, 'InvalidCodePoint', string.format(
                'code point: %d, is not between 0 and max unicode: %d',
                code_point, MAX_UNICODE)
    end

    local continue_n = 0
    for i, limit in ipairs(LIMITS) do
        if code_point >= limit then
            continue_n = i
        end
    end

    if continue_n == 0 then
        return string.char(code_point), nil, nil
    end

    local first_bits = bit.rshift(code_point, continue_n * 6)
    local first_byte = bit.bor(LEAD_BITS[continue_n], first_bits)
    local sequence = string.char(first_byte)

    for i = 1, continue_n do
        local continue_byte = bit.rshift(code_point, (continue_n - i) * 6)
        continue_byte = bit.band(continue_byte, 0x3F)
        continue_byte = continue_byte + 0x80
        sequence = sequence .. string.char(continue_byte)
    end

    return sequence, nil, nil
end


function _M.char(code_points)
    local utf8_sequeces = {}
    for _, code_point in ipairs(code_points) do
        local sequence, err, errmsg = encode_one_point(code_point)
        if err ~= nil then
            return nil, err, errmsg
        end

        table.insert(utf8_sequeces, sequence)
    end

    return table.concat(utf8_sequeces), nil, nil
end


return _M
