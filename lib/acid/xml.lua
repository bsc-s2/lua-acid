local strutil = require('acid.strutil')
local tableutil = require('acid.tableutil')
local utf8 = require('acid.utf8')

local _M = {}

local DECLARATION = '<?xml version="1.0" encoding="UTF-8"?>'
local ATTR = '__attr'
local KEY_ORDER = '__key_order'

local open_tag_ptn = '<[^<>]+/?>'

local char_to_entity = {
    ['&'] = '&amp;',
    ['<'] = '&lt;',
    ['>'] = '&gt;',
    ['"'] = '&quot;',
    ["'"] = '&apos;',
}

local entity_to_char = {
    ['&amp;'] = '&',
    ['&lt;'] = '<',
    ['&gt;'] = '>',
    ['&quot;'] = '"',
    ['&apos;'] = "'",
}


function _M.xml_escape(str)
    local char_to_entity_ref = function(c)
        if char_to_entity[c] ~= nil then
            return char_to_entity[c]
        end

        local byte = string.byte(c)
        if byte <= 0x20 then
            return string.format('&#x%02X;', byte)
        end

        return c
    end

    local escaped_str = string.gsub(str, '.', char_to_entity_ref)

    return escaped_str
end


function _M.xml_unescape(str)
    local entity_ref_to_str = function(entity_ref)
        if entity_to_char[entity_ref] ~= nil then
            return entity_to_char[entity_ref]
        end

        -- &#123; or &#x2F;
        local number_str = string.sub(entity_ref, 3, -2)
        local number
        if string.sub(number_str, 1, 1) == 'x' then
            number = tonumber(string.sub(number_str, 2), 16)
        else
            number = tonumber(number_str)
        end

        if number == nil then
            return nil
        end

        return utf8.char({number})
    end

    local unescaped = string.gsub(str, '&.-;', entity_ref_to_str)

    return unescaped
end


local function escape_by_char(str)
    local function escape_char(c)

        if char_to_entity[c] ~= nil then
            return char_to_entity[c]
        end

        local byte = string.byte(c)
        if byte > 0x20 and byte < 0x7F then
            return c
        end

        return string.format('&#x%02X;', byte)
    end

    local escaped_str = string.gsub(str, '.', escape_char)

    return escaped_str
end


function _M.xml_safe_encode(str)
    local _, err, _ = utf8.code_point(str)
    if err ~= nil then
        str = escape_by_char(str)
    else
        str = _M.xml_escape(str)
    end

    return str
end


local function build_tag(tag_name, tbl)
    local attr = {}
    for k, v in pairs(tbl[ATTR] or {}) do
        local escaped_k = _M.xml_safe_encode(tostring(k))
        local escaped_v = _M.xml_safe_encode(tostring(v))

        table.insert(attr, string.format(' %s="%s"', escaped_k, escaped_v))
    end

    local attr_str = table.concat(attr)

    local escaped_tag_name = _M.xml_safe_encode(tostring(tag_name))

    local open_tag = string.format('<%s%s>', escaped_tag_name, attr_str)
    local close_tag = string.format('</%s>', escaped_tag_name)

    return {open_tag=open_tag, close_tag=close_tag}
end


function _M.build_array_lines(lines, tag_name, tbl, indent_str, opts)
    for _, v in ipairs(tbl) do
        local copy_v = tableutil.dup(v, false)
        if type(copy_v) ~= 'table' then
            copy_v = {copy_v}
        end
        copy_v[ATTR] = tbl[ATTR]

        local _, err, errmsg = _M.build_lines(lines, tag_name, copy_v,
                                              indent_str, opts)
        if err ~= nil then
            return nil, err, errmsg
        end
    end
end


function _M.build_dict_lines(lines, tag_name, tbl, indent_str, opts)
    local next_indent_str = indent_str .. (opts.indent or '')

    local tag = build_tag(tag_name, tbl)
    table.insert(lines, indent_str .. tag.open_tag)

    local keys = {}
    for k, _ in pairs(tbl) do
        if k ~= ATTR and k ~= KEY_ORDER then
            table.insert(keys, k)
        end
    end

    if tbl[KEY_ORDER] ~= nil then
        keys = tbl[KEY_ORDER]
    end

    for _, k in ipairs(keys) do
        local _, err, errmsg = _M.build_lines(lines, k, tbl[k],
                                              next_indent_str, opts)
        if err ~= nil then
            return nil, err, errmsg
        end
    end

    table.insert(lines, indent_str .. tag.close_tag)
    return true, nil, nil
end


function _M.build_lines(lines, tag_name, tbl, indent_str, opts)
    local next_indent_str = indent_str .. (opts.indent or '')

    if type(tbl) ~= 'table' then
        tbl = {tbl}
    end

    if #tbl == 1 and type(tbl[1]) ~= 'table' then
        local tag = build_tag(tag_name, tbl)
        table.insert(lines, indent_str .. tag.open_tag)

        local text = tbl[1]

        local encoded_text = _M.xml_safe_encode(tostring(text))
        table.insert(lines, next_indent_str .. encoded_text)

        table.insert(lines, indent_str .. tag.close_tag)
        return true, nil, nil
    end

    if tbl[1] ~= nil then
        local _, err, errmsg = _M.build_array_lines(lines, tag_name, tbl,
                                                    indent_str, opts)
        if err ~= nil then
            return nil, err, errmsg
        end
    else
        local _, err, errmsg = _M.build_dict_lines(lines, tag_name, tbl,
                                                   indent_str, opts)
        if err ~= nil then
            return nil, err, errmsg
        end
    end

    return true, nil, nil
end


function _M.to_xml(root_name, tbl, opts)
    opts = opts or {}

    local lines = {}

    if opts.no_declaration ~= true then
        table.insert(lines, DECLARATION)
    end

    local _, err, errmsg = _M.build_lines(lines, root_name, tbl, '', opts)
    if err ~= nil then
        return nil, err, errmsg
    end

    local concatenator = ''
    if opts.indent ~= nil then
        concatenator = '\n'
    end

    local str = table.concat(lines, concatenator)

    return str, nil, nil
end


local function parse_tag_body(str, body_segment)
    if body_segment.start_i > body_segment.end_i then
        return {}
    end

    local _, open_tag_e = string.find(str, open_tag_ptn,
                                      body_segment.start_i)
    if open_tag_e ~= nil and open_tag_e <= body_segment.end_i then
        return nil
    end

    local body_str = string.sub(str, body_segment.start_i,
                                body_segment.end_i)
    return body_str
end


local function parse_attr(attr_str)
    local attrs_raw = {}
    string.gsub(attr_str, '([^%s]+)%s*=%s*([^%s]+)',
                function(name, value) attrs_raw[name] = value end)

    local attrs = {}
    for raw_name, raw_value in pairs(attrs_raw) do
        local name = _M.xml_unescape(raw_name)
        local value = strutil.strip(raw_value, '"\'')
        value = _M.xml_unescape(value)

        attrs[name] = value
    end

    if next(attrs) == nil then
        attrs = nil
    end

    return attrs
end


local function parse_open_tag(open_tag)
    local open_tag_info = {}
    local name_attr

    -- <foo /> or <foo a="b">
    if string.sub(open_tag, -2, -2) == '/' then
        open_tag_info.is_empty_tag = true
        name_attr = string.sub(open_tag, 2, -3)
    else
        open_tag_info.is_empty_tag = false
        name_attr = string.sub(open_tag, 2, -2)
    end

    local space_i, _ = string.find(name_attr, ' ')
    space_i = space_i or (#name_attr + 1)

    open_tag_info.tag_name_raw = string.sub(name_attr, 1, space_i - 1)
    if open_tag_info.tag_name_raw == '' then
        return nil, 'InvalidXML', string.format(
                'tag name is empty string in: %s', open_tag)
    end

    open_tag_info.tag_name = _M.xml_unescape(open_tag_info.tag_name_raw)

    local attr_str = string.sub(name_attr, space_i + 1, #name_attr)
    local attrs, err, errmsg = parse_attr(attr_str)
    if err ~= nil then
        return nil, err, errmsg
    end

    open_tag_info[ATTR] = attrs

    return open_tag_info, nil, nil
end


local function parse_one_element(str, segment)
    local to_parse = string.sub(str, segment.start_i, segment.end_i)
    if string.match(to_parse, '^%s*$') then
        return nil, nil, nil
    end

    local open_tag_s, open_tag_e = string.find(str, open_tag_ptn,
                                               segment.start_i)
    if open_tag_e == nil or open_tag_e > segment.end_i then
        return nil, 'InvalidXML', string.format(
                'can not find open tag at: %s... within: %d chars',
                string.sub(str, segment.start_i, segment.start_i + 100),
                segment.end_i - segment.start_i + 1)
    end

    local pre_open_tag = string.sub(str, segment.start_i, open_tag_s - 1)
    if not string.match(pre_open_tag, '^%s*$') then
        return nil, 'InvalidXML', string.format(
                'find extra string: %s... before open tag',
                string.sub(pre_open_tag, 1, 100))
    end

    local open_tag_info, err, errmsg = parse_open_tag(
            string.sub(str, open_tag_s, open_tag_e))
    if err ~= nil then
        return nil, err, errmsg
    end

    local element = {
        tag_name = open_tag_info.tag_name,
        [ATTR] = open_tag_info[ATTR],
    }

    if open_tag_info.is_empty_tag then
        element.value = {}
        segment.start_i = open_tag_e + 1
        return element, nil, nil
    end

    local close_tag = string.format('</%s>', open_tag_info.tag_name_raw)
    local close_tag_s, close_tag_e = string.find(str, close_tag,
                                                 open_tag_e + 1, true)
    if close_tag_e == nil or close_tag_e > segment.end_i then
        return nil, 'InvalidXML', string.format(
                'can not find close tag: %s at: %s...', close_tag,
                string.sub(str, open_tag_e + 1, open_tag_e + 101))
    end

    segment.start_i = close_tag_e + 1

    local body_segment = {
        start_i = open_tag_e + 1,
        end_i = close_tag_s - 1,
    }
    local tag_body = parse_tag_body(str, body_segment)
    if tag_body ~= nil then
        element.value = tag_body
        return element, nil, nil
    end

    element.value = {}
    local _, err, errmsg = _M.parse_xml(element.value, str, body_segment)
    if err ~= nil then
        return nil, err, errmsg
    end

    return element, nil, nil
end


function _M.parse_xml(tree, str, segment)
    while true do
        local element, err, errmsg = parse_one_element(str, segment)
        if err ~= nil then
            return nil, err, errmsg
        end

        if element == nil then
            break
        end

        local tag_name = element.tag_name
        if tree[tag_name] == nil then
            tree[tag_name] = {}
            tree[tag_name][ATTR] = element[ATTR]
        end

        table.insert(tree[tag_name], element.value)
    end

    return true, nil, nil
end


function _M.list_to_dict(tree)
    if type(tree) ~= 'table' then
        return true
    end

    for tag_name, tag_value in pairs(tree) do
        if type(tag_value) == 'table' and #tag_value == 1 then
            local v = tag_value[1]

            if tag_value[ATTR] ~= nil then
                if type(v) ~= 'table' then
                    v = { v }
                end
                v[ATTR] = tag_value[ATTR]
            end

            tree[tag_name] = v
            _M.list_to_dict(tree[tag_name])

        elseif type(tag_value) == 'table' then
            for _, e in ipairs(tag_value) do
                _M.list_to_dict(e)
            end
        end
    end

    return true
end


function _M.from_xml(str)
    str = string.gsub(str, '<!--(.-)-->', '')
    str = string.gsub(str, '<?(.-)?>', '')
    local segment = {
        start_i = 1,
        end_i = #str,
    }
    local tree = {}

    local _, err, errmsg = _M.parse_xml(tree, str, segment)
    if err ~= nil then
        return nil, err, errmsg
    end

    _M.list_to_dict(tree)

    return tree, nil, nil
end


return _M
