local strutil = require("acid.strutil")

local _M = { _VERSION = '1.0' }
local char = string.char
local byte = string.byte
local to_str = strutil.to_str


function _M.pack_int32(val, little_endian)
    if type(val) ~= 'number' then
        return nil, 'TypeError', 'input must be a number'
    end

    if val < -2 ^ 31 or val > 2 ^ 32 - 1 then
        return nil, 'ValueError', 'input requires -2 ^ 31 <= val <= 2 ^ 32 - 1'
    end

    local bytes = {}
    for _ = 0, 3 do
        table.insert(bytes, char(val % (2 ^ 8)))
        val = math.floor(val / (2 ^ 8))
    end

    if not little_endian then
        return string.reverse(table.concat(bytes))
    end

    return table.concat(bytes)
end


function _M.unpack_int32(buffer, little_endian, signed)
    local left_chars = #buffer.stream - buffer.offset + 1
    if left_chars < 4 then
        return nil, 'ValueError', to_str('expected:4 chars got:', left_chars , ' chars')
    end

    local val = 0
    if signed == nil then
        signed = true
    end

    for i = 0, 3 do
        local b = byte(buffer.stream:sub(buffer.offset, buffer.offset))

        if little_endian then
            val = val + b * (2 ^ (i * 8))
        else
            val = val + b * (2 ^ ((3 - i) * 8))
        end
        buffer.offset = buffer.offset + 1
    end

    if signed and val >= 2 ^ (4 * 8 - 1) then
        val = val - 2 ^ (4 * 8)
    end

    return val
end


function _M.pack_string(str)
    local len, err, errmsg = _M.pack_int32(#str)
    if err ~= nil then
        return nil, err, errmsg
    end

    return len .. str
end


function _M.unpack_string(buffer)
    local len, err, errmsg = _M.unpack_int32(buffer)
    if err ~= nil then
        return nil, err, errmsg
    end

    if len < 0 then
        return nil, 'ValueError', to_str('expected: length >= 0 got:', len)
    end

    if len == 0 then
        return ''
    end


    local left_chars = #buffer.stream - buffer.offset + 1
    if left_chars < len then
        return nil, 'ValueError', to_str('expected:', len, ' chars ', 'got:', left_chars, ' chars')
    end

    local offset = buffer.offset
    buffer.offset = buffer.offset + len
    return buffer.stream:sub(offset, offset + len - 1)
end


function _M.pack(format, ...)
    local args = {...}
    local idx = 1
    local rst = ''
    local little_endian = false

    for i = 1, #format do
        local c = format:sub(i, i)
        if c == '>' then
            little_endian = false
        elseif c == '<' then
            little_endian = true
        elseif c == 'i' or c == 'I' then
            local s, err, errmsg = _M.pack_int32(args[idx], little_endian)
            if err ~= nil then
                return nil, err, errmsg
            end
            rst = rst .. s
            idx = idx + 1
        elseif c == 'S' then
            local s, err, errmsg = _M.pack_string(args[idx])
            if err ~= nil then
                return nil, err, errmsg
            end
            rst = rst .. s
            idx = idx + 1
        elseif c == 's' then
            rst = rst .. args[idx]
            idx = idx + 1
        else
            return nil, 'UnsupportFormat', 'only support >, <, i, I, s, S'
        end
    end

    return rst
end


function _M.unpack(format, buffer)
    local rst = {}
    local little_endian = false
    local cnt = 0

    for i = 1, #format do
        local c = format:sub(i, i)
        if c == '>' then
            little_endian = false
        elseif c == '<' then
            little_endian = true
        elseif c == 'i' or c == 'I' then
            local n, err, errmsg = _M.unpack_int32(buffer, little_endian, c == 'i')
            if err ~= nil then
                return nil, err, errmsg
            end
            table.insert(rst, n)
        elseif c == 'S' then
            local s, err, errmsg = _M.unpack_string(buffer)
            if err ~= nil then
                return nil, err, errmsg
            end
            table.insert(rst, s)
        elseif c == 's' then
            local left_chars = #buffer.stream - buffer.offset + 1
            if left_chars < cnt then
                return nil, 'ValueError', to_str('expected:', cnt, ' chars ', 'got:', left_chars, ' chars')
            end
            if cnt <= 0 then
                return nil, 'ValueError', 'length not found'
            end
            local s = buffer.stream:sub(buffer.offset, buffer.offset + cnt - 1)
            table.insert(rst, s)
            buffer.offset = buffer.offset + cnt
            cnt = 0
        elseif byte(c) >= 0x30 and byte(c) <= 0x39 then
            cnt = cnt * 10 + tonumber(c)
        else
            return nil, 'UnsupportFormat', 'only support >, <, i, I, s, S, 0-9'
        end
    end

    return rst
end


return _M
