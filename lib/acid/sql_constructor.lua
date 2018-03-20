local strutil = require('acid.strutil')
local tableutil = require('acid.tableutil')

local to_str = strutil.to_str
local string_format = string.format
local table_concat = table.concat
local table_insert = table.insert
local set_quote_sql_str = ndk.set_var.set_quote_sql_str

local _M = {}

local _mt = {__index = _M}


local function quote_binary(value, field)
    if field.use_hex == false then
        return set_quote_sql_str(value)
    end

    return string_format('UNHEX("%s")', value)
end


local function quote_string(value)
    return set_quote_sql_str(value)
end


local function quote_number(value)
    return value
end


local function quote_bigint(value, field)
    if field.use_string == false then
        return value
    end

    return quote_string(value)
end


local function as_it_is(field_name)
    return string_format('`%s`', field_name)
end


local function as_hex(field_name, field)
    if field.use_hex == false then
        return as_it_is(field_name)
    end

    return string_format('LOWER(HEX(`%s`)) as `%s`',
                         field_name, field_name)
end


local function as_string(field_name)
    return string_format('CAST(`%s` AS CHAR) as `%s`',
                         field_name, field_name)
end


local function as_bigint(field_name, field)
    if field.use_string == false then
        return as_it_is(field_name)
    end

    return as_string(field_name)
end


local data_type_model = {
    binary = {
        quote = quote_binary,
        make_select_expr = as_hex,
    },
    varbinary = {
        quote = quote_binary,
        make_select_expr = as_hex,
    },
    varchar = {
        quote = quote_string,
        make_select_expr = as_it_is,
    },
    text = {
        quote = quote_string,
        make_select_expr = as_it_is,
    },
    tinyint = {
        quote = quote_number,
        make_select_expr = as_it_is,
    },
    int = {
        quote = quote_number,
        make_select_expr = as_it_is,
    },
    bigint = {
        quote = quote_bigint,
        make_select_expr = as_bigint,
    },
}


function _M.quote_value(field, value)
    local data_type = field.data_type

    local type_model = data_type_model[data_type]
    if type_model == nil then
        return nil, 'InvalidFieldType', string_format(
                'no field type model for: %s', tostring(data_type))
    end

    local quote_func = type_model.quote

    local ok, r_or_err = pcall(quote_func, value, field)
    if not ok then
        return nil, 'QuoteError', string_format(
                'failed to quote value: %s, of field: %s, %s',
                to_str(value), to_str(field), r_or_err)
    end

    return r_or_err, nil, nil
end


function _M.make_fields(raw_fields)
    local fields = tableutil.dup(raw_fields, true)

    for field_name, field in pairs(fields) do
        field.backticked_name = string_format('`%s`', field_name)

        local data_type = field.data_type
        local type_model = data_type_model[data_type]

        if type_model == nil then
            return nil, 'InvalidFieldType', string_format(
                    'no data type model for: %s', tostring(data_type))
        end

        local make_select_expr_func = type_model.make_select_expr

        field.select_expr = make_select_expr_func(field_name, field)
    end

    return fields, nil, nil
end


local function make_equal_sequence(fields, allowed_param, args, separator)
    if allowed_param == nil then
        return nil, nil, nil
    end

    separator = separator or ','
    local parts = {}

    for param_name, _ in pairs(allowed_param) do
        local field = fields[param_name]
        local value = args[param_name]
        if value ~= nil  then
            local quoted_value, err, errmsg = _M.quote_value(field, value)
            if err ~= nil then
                return nil, err, errmsg
            end
            table_insert(parts, string_format(
                    '%s=%s', field.backticked_name, quoted_value))
        end
    end

    local r = table_concat(parts, separator)
    if r == '' then
        r = nil
    end

    return r, nil, nil
end


local function make_assignment_list(fields, allowed_param, args)
    return make_equal_sequence(fields, allowed_param, args, ',')
end


local function make_incr_assignment_list(fields, allowed_param, args)
    if allowed_param == nil then
        return nil, nil, nil
    end

    local parts = {}
    for param_name, _ in pairs(allowed_param) do
        local field = fields[param_name]
        local value = args[param_name]
        if value ~= nil  then
            local quoted_value, err, errmsg = _M.quote_value(field, value)
            if err ~= nil then
                return nil, err, errmsg
            end
            table_insert(parts, string_format(
                    '%s=%s+%s', field.backticked_name,
                    quoted_value, field.backticked_name))
        end
    end

    local r = table_concat(parts, ',')
    if r == '' then
        r = nil
    end

    return r, nil, nil
end


local function make_range_condition(fields, range, args, opts)
    if range == nil then
        return nil, nil, nil
    end

    local parts = {}

    local greater_sign = '>='
    if tostring(opts.leftopen) == '1' then
        greater_sign = '>'
    end

    local less_sign = '<'
    if tostring(opts.rightopen) == '0' then
        less_sign = '<='
    end

    for param_name, _ in pairs(range) do
        local field = fields[param_name]
        local value = args[param_name]
        if value ~= nil  then
            if value[1] ~= nil then
                local quoted_value, err, errmsg = _M.quote_value(
                        field, value[1])
                if err ~= nil then
                    return nil, err, errmsg
                end
                table_insert(parts, string_format(
                        '%s%s%s', field.backticked_name,
                        greater_sign, quoted_value))
            end

            if value[2] ~= nil then
                local quoted_value, err, errmsg = _M.quote_value(
                        field, value[2])
                if err ~= nil then
                    return nil, err, errmsg
                end

                table_insert(parts, string_format(
                        '%s%s%s', field.backticked_name,
                        less_sign, quoted_value))
            end
        end
    end

    local r = table_concat(parts, ' AND ')
    if r == '' then
        r = nil
    end

    return r, nil, nil
end


local function make_match_condition(fields, opts)
    local to_match = opts.match
    if to_match == nil then
        return nil, nil, nil
    end

    local parts = {}

    for field_name, value in pairs(to_match) do
        local field = fields[field_name]
        if field == nil then
            return nil, 'InvalidArgument', string_format(
                    'invalid field name: %s in match',
                    tostring(field_name))
        end

        local quoted_value, err, errmsg = _M.quote_value(field, value)
        if err ~= nil then
            return nil, err, errmsg
        end
        table_insert(parts, string_format(
                '%s=%s', field.backticked_name, quoted_value))
    end

    local r = table_concat(parts, ' AND ')
    if r == '' then
        r = nil
    end

    return r, nil, nil
end


local function make_where_clause(fields, param, args, opts)
    local conditions = {}
    if opts.index_condition ~= nil then
        table_insert(conditions, opts.index_condition)
    end

    local range_condition, err, errmsg = make_range_condition(
            fields, param.range, args, opts)
    if err ~= nil then
        return nil, err, errmsg
    end
    table_insert(conditions, range_condition)

    local ident_condition, err, errmsg = make_equal_sequence(
            fields, param.ident, args, ' AND ')
    if err ~= nil then
        return nil, err, errmsg
    end
    table_insert(conditions, ident_condition)

    local match_condition, err, errmsg = make_match_condition(
            fields, opts)
    if err ~= nil then
        return nil, err, errmsg
    end
    table_insert(conditions, match_condition)

    local where_condition = table_concat(conditions, ' AND ')

    local where_clause
    if where_condition == '' then
        where_clause = ''
    else
        where_clause = ' WHERE ' .. where_condition
    end

    return where_clause, nil, nil
end


local function make_order_by_clause(fields, opts)
    -- opts['order_by'] = {{'age', ASC}, {'name'}, {'emil', DESC}}

    local order_by_fields = opts.order_by
    if order_by_fields == nil then
        return '', nil, nil
    end

    local order_by_parts = {}

    for _, order_by_field in ipairs(order_by_fields) do
        local field_name = order_by_field[1]
        local order_type = order_by_field[2] or ''

        local field = fields[field_name]
        if field == nil then
            return nil, 'InvalidOrderByArgValue', string_format(
                    'invalid order by field: %s, not exist',
                    to_str(order_by_field))
        end

        if not tableutil.has({'ASC', 'DESC', ''}, order_type) then
            return nil, 'InvalidOrderByArgValue', string_format(
                    'invalid order by field: %s, invalid order type',
                    to_str(order_by_field))
        end

        if order_type == '' then
            table_insert(order_by_parts, field.backticked_name)
        else
            table_insert(order_by_parts, field.backticked_name .. ' ' .. order_type)
        end
    end

    local order_by_clause
    if #order_by_parts > 0 then
        order_by_clause = ' ORDER BY ' .. table_concat(order_by_parts, ', ')
    else
        order_by_clause = ''
    end

    return order_by_clause, nil, nil
end


local function make_limit_clause(limit)
    if limit == nil then
        return ''
    end

    return ' LIMIT ' .. tostring(limit)
end


function _M.make_insert_sql(self, param, args)
    local names = {}
    local values = {}

    for field_name, _ in pairs(param.allowed_field) do
        if args[field_name] ~= nil then
            local field = self.fields[field_name]
            table_insert(names, field.backticked_name)

            local value = args[field_name]
            local quoted_value, err, errmsg = _M.quote_value(field, value)
            if err ~= nil then
                return nil, err, errmsg
            end
            table_insert(values, quoted_value)
        end
    end

    local names_str = table_concat(names, ',')
    local values_str = table_concat(values, ',')
    local sql = string_format('INSERT IGNORE INTO `%s` (%s) VALUES (%s)',
                              self.table_name, names_str, values_str)

    return sql, nil, nil
end


function _M.make_update_sql(self, param, args, opts)
    if opts == nil then
        opts = {}
    end

    local assigment_list, err, errmsg

    if opts.incremental == true then
        assigment_list, err, errmsg = make_incr_assignment_list(
                self.fields, param.allowed_field, args)
    else
        assigment_list, err, errmsg = make_assignment_list(
                self.fields, param.allowed_field, args)
    end

    if err ~= nil then
        return nil, err, errmsg
    end

    if assigment_list == '' then
        return nil, 'InvalidArgument', 'no field to set'
    end

    local set_clause = 'SET ' .. assigment_list

    local where_clause, err, errmsg = make_where_clause(
            self.fields, param, args, opts)
    if err ~= nil then
        return nil, err, errmsg
    end

    local limit_clause = make_limit_clause(opts.limit)

    local sql = string_format('UPDATE IGNORE `%s` %s%s%s',
                              self.table_name, set_clause, where_clause,
                              limit_clause)
    return sql, nil, nil
end


function _M.make_delete_sql(self, param, args, opts)
    if opts == nil then
        opts = {}
    end

    local where_clause, err, errmsg = make_where_clause(
            self.fields, param, args, opts)
    if err ~= nil then
        return nil, err, errmsg
    end

    local limit_clause = make_limit_clause(opts.limit)

    local sql = string_format('DELETE IGNORE FROM `%s`%s%s',
                              self.table_name, where_clause, limit_clause)

    return sql, nil, nil
end


local function make_select_expr_list(fields, select_field)
    local parts = {}

    for _, field_name in ipairs(select_field) do
        local field = fields[field_name]
        table_insert(parts, field.select_expr)
    end

    return table_concat(parts, ',')
end


function _M.make_select_sql(self, select_field, param, args, opts)
    if opts == nil then
        opts = {}
    end

    local select_expr_list = opts.select_expr_list
    if select_expr_list == nil then
        select_expr_list = make_select_expr_list(self.fields, select_field)
    end

    local where_clause, err, errmsg = make_where_clause(
            self.fields, param, args, opts)
    if err ~= nil then
        return nil, err, errmsg
    end

    local force_index_clause = opts.force_index_clause or ''

    local group_by_clause = opts.group_by_clause or ''

    local order_by_clause, err, errmsg = make_order_by_clause(
            self.fields, opts)
    if err ~= nil then
        return nil, err, errmsg
    end

    local limit_clause = make_limit_clause(opts.limit)

    local sql = string_format('SELECT %s FROM `%s`%s%s',
                              select_expr_list, self.table_name,
                              force_index_clause,
                              table_concat({where_clause, group_by_clause,
                                            order_by_clause, limit_clause},
                                           ''))
    return sql, nil, nil
end


function _M.new(table_name, fields)
    return setmetatable({
        table_name = table_name,
        fields = fields,
    }, _mt)
end


return _M
