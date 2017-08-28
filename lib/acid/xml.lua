local unicode = require("acid.unicode")

local _M = {}

local function xml_safe(s)
    if type(s) ~= 'string' then
        return tostring(s)
    end

    local u, err, _ = unicode.from_utf8(s)
    if err then
        return unicode.xml_enc_character_reference(s)
    end

    return u:xml_enc()
end

local function parseattrs( str )
  local attrs = {}

  string.gsub(str, "([%-:%w]+)=([\"'])(.-)%2", function (w, _, a)
    attrs[w] = a
  end)

  return attrs
end

function _M.to_xml( rootname, r )
    local lines = { '<?xml version="1.0" encoding="UTF-8"?>', }

    local cont_lines, err, errmes = _M.dict_to_xml_lines(rootname, r)
    if err then
        return nil, err, errmes
    end

    for _, l in ipairs(cont_lines) do
        table.insert(lines, l)
    end
    return table.concat(lines, '\n')
end

function _M.dict_to_xml_lines( name, r, indent_str )

    indent_str = indent_str or ''

    local err, errmes
    name, err, errmes = xml_safe( name )
    if err then
        return nil, err, errmes
    end

    local attr = ''
    -- dict
    if type(r) == 'table' and r.__attr then

        for k, v in pairs(r.__attr) do

            local kk, err, errmes = xml_safe(k)
            if err then
                return nil, err, errmes
            end

            local vv, err, errmes = xml_safe(v)
            if err then
                return nil, err, errmes
            end

            attr = attr .. ' ' .. kk .. '="' .. vv .. '"'
        end
    end

    local lines

    -- r = { "1", __attr={ c = 1 } }
    if type(r) == 'table' and r[1] ~= nil and r.__attr ~= nil then

        local x, err, errmes = xml_safe(r[1])
        if err then
            return nil, err, errmes
        end

        lines = { string.format('<%s%s>%s</%s>', name, attr, x, name ) }

    -- list: r = { { c = 1 }, 2 }
    elseif type(r) == 'table' and r[1] ~= nil and r.__attr == nil then

        lines = {}

        for _, elt in ipairs(r) do

            local sublines, err, errmes = _M.dict_to_xml_lines(name, elt, '')
            if err then
                return nil, err, errmes
            end
            for _, l in ipairs(sublines) do
                table.insert(lines, l)
            end
        end

    -- r = { b = 1, c = 3 }
    elseif type( r ) == 'table' and r[1] == nil then

        lines = { string.format('<%s%s>', name, attr ) }

        if type(r.__key_order) == 'table' then
            for _, k in ipairs(r.__key_order) do
                local sublines, err, errmes = _M.dict_to_xml_lines( k, r[k], '    ' )
                if err then
                    return nil, err, errmes
                end
                for _, l in ipairs(sublines) do
                    table.insert(lines, l)
                end
            end
        else
            for k, v in pairs(r) do
                if k ~= '__attr' then
                    local sublines, err, errmes = _M.dict_to_xml_lines( k, v, '    ' )
                    if err then
                        return nil, err, errmes
                    end
                    for _, l in ipairs(sublines) do
                        table.insert(lines, l)
                    end
                end
            end
        end

        table.insert(lines, string.format('</%s>', name))

    elseif type( r ) == type(true) then

        local tbl = {[true]= 'true', [false]= 'false'}
        lines = {string.format('<%s%s>%s</%s>', name, attr, tbl[r], name )}

    else

        local x, err, errmes = xml_safe(r)
        if err then
            return nil, err, errmes
        end

        lines = { string.format('<%s%s>%s</%s>', name, attr, x, name ) }
    end

    for i, l in ipairs(lines) do
        lines[i] = indent_str .. l
    end

    return lines
end


function _M.from_xml( str )
    local stack = {}
    local top = {}

    local idx_i, name, label, attr, empty
    local pos = 1
    local idx_j

    local ptn = '<(%/?)([%w:_-]+)(.-)(%/?)>'


    local comment_ptn = '<!--(.-)-->'
    str = string.gsub( str, comment_ptn, '' )

    table.insert( stack, top )

    while true do
        idx_i, idx_j, name, label, attr, empty = string.find( str, ptn, pos )
        if not idx_i then
            break
        end

        local text = string.sub( str, pos, idx_i-1 )
        if not string.find( text, "^%s*$" ) then
            table.insert( top, unicode.xml_dec(text) )
        end

        if empty == "/" then  -- empty element tag

            table.insert(top, {label=label, __attr=parseattrs(attr)})

        elseif name == "" then   -- start tag

            top = {label=label, __attr=parseattrs(attr)}

            table.insert(stack, top)   -- new level
        else  -- end tag

            local elt = table.remove(stack)  -- remove top
            top = stack[#stack]

            if #stack < 1 then
                return nil, 'InvalidXML', 'nothing to close with: ' .. label
            end

            if elt.label ~= label then
                return nil, 'InvalidXML', 'invalid close label: ' .. label
            end

            elt.label = nil

            if next(elt.__attr) == nil then
                elt.__attr = nil
            end

            if type(elt[1]) == 'string' and elt.__attr == nil then
                elt = elt[1]
            end

            -- b = nil
            if top[label] == nil then

                top[label] = elt

            -- b = 1
            elseif type(top[label]) == 'string' then

                top[label] = {top[label], elt}

            -- b = { c = 1 }
            -- b = { "1", __attr={c=1} }
            elseif type(top[label]) == 'table'
                and ( top[label][1] == nil or top[label]['__attr'] ~= nil ) then

                top[label] = {top[label], elt}
            -- b = {{ c = 1 },2,}
            else

                table.insert( top[label], elt )
            end
        end

        pos = idx_j + 1
    end

    local text = string.sub(str, pos)
    if not string.find(text, "^%s*$") then
        table.insert(stack[#stack], text)
    end

    if #stack > 1 then
        return nil, 'InvalidXML', 'unclose with: ' ..stack[#stack].label
    end

    return stack[1]
end

return _M
