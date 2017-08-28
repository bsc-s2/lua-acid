local strutil = require("acid.strutil")

local _M = {}

local ipairs = ipairs
local math_pow = math.pow
local string_byte = string.byte
local string_char = string.char
local string_format = string.format
local string_gsub = string.gsub
local table_concat = table.concat
local table_insert = table.insert

_M.__index = _M


local utf8_leading = {
    -- 0x00, 0x80    1     --  0xxxxxxx
    -- 0x80, 0xc0    nil   --  10xxxxxx
    { 0xc0, 0xe0, 1   },   --  110xxxxx 10xxxxxx
    { 0xe0, 0xf0, 2   },   --  1110xxxx 10xxxxxx*2
    { 0xf0, 0xf8, 3   },   --  11110xxx 10xxxxxx*3
    { 0xf8, 0xfc, 4   },   --  111110xx 10xxxxxx*4
    { 0xfc, 0xfe, 5   },   --  1111110x 10xxxxxx*5
    { 0xfe, 0xff, nil },   --  11111110 10xxxxxx*6
}


local xml_conv = {
    ['&'] = '&amp;',
    ['<'] = '&lt;',
    ['>'] = '&gt;',
    ['"'] = '&quot;',
    ["'"] = '&apos;',
}


local un_xml_conv = {
    ['&amp;'] = '&',
    ['&#38;'] = '&',
    ['&lt;'] = '<',
    ['&#60;'] = '<',
    ['&gt;'] = '>',
    ['&#62;'] = '>',
    ['&quot;'] = '"',
    ['&#34;'] = '"',
    ['&apos;'] = "'",
    ['&#39;'] = "'",
}


function _M.from_utf8(ss)
    -- ss should be utf8 string

    local rst = {}

    local i = 0
    while i < #ss do
        i = i + 1

        local chr = ss:sub(i, i)
        local byte = string_byte(chr)

        if byte < 0x80 then
            table_insert(rst, byte)

        elseif byte < 0xc0 then
            return nil, 'IllegalChar', 'at ' .. i .. ' char:' .. strutil.tohex(chr)

        else

            for _, x in ipairs(utf8_leading) do

                local frm, to, n_following = x[1], x[2], x[3]
                if n_following == nil then
                    return nil, 'IllegalChar', 'at ' .. i .. ' char:'..strutil.tohex(chr)
                end

                if byte < to then
                    -- 6 effective bits per following byte
                    local r = (byte % frm) * math_pow(2, 6*(n_following))
                    for j = 1, n_following do
                        local c = string_byte(ss, i+j)
                        if c == nil then
                            return nil, 'IllegalChar', 'need more char at ' .. (i+j)
                        end
                        c = c % 0x80
                        r = r + c * math_pow(2, 6*(n_following-j))
                    end

                    table_insert(rst, r)

                    i = i + n_following
                    break
                end
            end
        end
    end

    setmetatable(rst, _M)
    return rst
end


function _M:xml_enc()
    local seq = self
    local r = {}
    for _, b in ipairs(seq) do
        if b < 0x80 then

            local c = string_char(b)
            if xml_conv[c] ~= nil then
                c = xml_conv[c]
            end
            table_insert(r, c)

        else
            table_insert(r, '&#' .. b .. ';')
        end
    end
    return table_concat(r)
end


function _M:xml_dec()
    local seq = self

    -- TODO: decode character reference
    seq = string_gsub( seq, "&.-;", function (n)
        return un_xml_conv[n] or n
    end)

    return seq
end


local function character_reference(char)

    local byte = string_byte(char)

    -- space and DEL
    if byte >= 0x20 and byte < 0x7f then

        if xml_conv[char] ~= nil then
            return xml_conv[char]
        else
            return char
        end
    else

        return string_format("&#x%x;", byte)
    end
end


function _M.xml_enc_character_reference(str)

    -- document is here: https://www.w3.org/TR/REC-xml/#wf-Legalchar

    local rst = {}

    local i = 0
    while i < #str do
        i = i + 1

        local char = str:sub(i, i)

        table_insert(rst, character_reference(char))
    end

    return table_concat(rst)
end


return _M
