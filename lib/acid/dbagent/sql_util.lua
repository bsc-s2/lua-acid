local sql_constructor = require('acid.sql_constructor')
local strutil = require('acid.strutil')
local tableutil = require('acid.tableutil')

local to_str = strutil.to_str
local string_format = string.format
local table_insert = table.insert
local table_concat = table.concat

local _M = {}


local function pick_opts_in_args(args)
    return tableutil.sub(args, {'match', 'leftopen', 'rightopen',
                                'limit', 'order_by'})
end


local function make_index_condition(fields, index_matched_fields, args)
    if #index_matched_fields == 0 then
        return nil, nil, nil
    end

    local parts = {}

    for i, field_name in ipairs(index_matched_fields) do
        local field = fields[field_name]
        local value = args[field_name]
        local quoted_value, err, errmsg = sql_constructor.quote_value(
                field, value)
        if err ~= nil then
            return nil, err, errmsg
        end

        if i < #index_matched_fields then
            table_insert(parts, string_format(
                    '%s=%s', field.backticked_name, quoted_value))
        else
            if tostring(args.leftopen) == '1' then
                table_insert(parts, string_format(
                        '%s>%s', field.backticked_name, quoted_value))
            else
                table_insert(parts, string_format(
                        '%s>=%s', field.backticked_name, quoted_value))
            end
        end
    end

    local r = table_concat(parts, ' AND '), nil, nil
    if r == '' then
        r = nil
    end

    return r, nil, nil
end


local function make_force_index(indexes, args)
    local index_to_use
    local longest_match_n = 0

    for index_name, index_columns in pairs(indexes) do
        local match_n = 0

        for _, column_name in ipairs(index_columns) do
            if args[column_name] ~= nil then
                match_n = match_n + 1
            else
                break
            end
        end

        if match_n >= longest_match_n then
            longest_match_n = match_n
            index_to_use = index_name
        end
    end

    if index_to_use == nil then
        return {force_index_clause = '', index_matched_fields={}}
    end

    local index_matched_fields = {
        unpack(indexes[index_to_use], 1, longest_match_n)
    }

    return {
        force_index_clause = string_format(' FORCE INDEX (%s)', index_to_use),
        index_matched_fields = index_matched_fields,
    }
end


function _M.make_add_sql(api_ctx)
    local sql, err, errmsg = api_ctx.sql_constructor:make_insert_sql(
            api_ctx.action_model.param, api_ctx.args)
    if err ~= nil then
        return nil, err, errmsg
    end

    api_ctx.sqls = {sql}

    return sql, nil, nil
end


function _M.make_set_sql(api_ctx)
    local opts = pick_opts_in_args(api_ctx.args)
    opts.limit = 1

    local sql, err, errmsg = api_ctx.sql_constructor:make_update_sql(
            api_ctx.action_model.param, api_ctx.args, opts)
    if err ~= nil then
        return nil, err, errmsg
    end

    api_ctx.sqls = {sql}

    return sql, nil, nil
end


function _M.make_increase_sql(api_ctx)
    local opts = pick_opts_in_args(api_ctx.args)
    opts.limit = 1
    opts.incremental = true

    local sql, err, errmsg = api_ctx.sql_constructor:make_update_sql(
            api_ctx.action_model.param, api_ctx.args, opts)
    if err ~= nil then
        return nil, err, errmsg
    end

    api_ctx.sqls = {sql}

    return sql, nil, nil
end


function _M.make_get_sql(api_ctx)
    local opts = pick_opts_in_args(api_ctx.args)
    opts.limit = 1

    local sql, err, errmsg = api_ctx.sql_constructor:make_select_sql(
            api_ctx.action_model.select_field,
            api_ctx.action_model.param,
            api_ctx.args,
            opts)
    if err ~= nil then
        return nil, err, errmsg
    end

    api_ctx.sqls = {sql}

    return sql, nil, nil
end


function _M.make_get_multi_sql(api_ctx)
    local opts = pick_opts_in_args(api_ctx.args)

    local sql, err, errmsg = api_ctx.sql_constructor:make_select_sql(
            api_ctx.action_model.select_field,
            api_ctx.action_model.param,
            api_ctx.args,
            opts)
    if err ~= nil then
        return nil, err, errmsg
    end

    api_ctx.sqls = {sql}

    return sql, nil, nil
end


function _M.make_indexed_ls_sql(api_ctx)
    local opts = pick_opts_in_args(api_ctx.args)
    opts.limit = opts.limit or 1

    local force_index = make_force_index(
            api_ctx.action_model.indexes, api_ctx.args)

    if force_index.force_index_clause ~= '' then
        local index_condition = make_index_condition(
                api_ctx.subject_model.fields,
                force_index.index_matched_fields,
                api_ctx.args)

        opts.force_index_clause = force_index.force_index_clause
        opts.index_condition = index_condition
    end

    local sql, err, errmsg = api_ctx.sql_constructor:make_select_sql(
            api_ctx.action_model.select_field,
            api_ctx.action_model.param,
            api_ctx.args,
            opts)
    if err ~= nil then
        return nil, err, errmsg
    end

    api_ctx.sqls = {sql}

    return sql, nil, nil
end


function _M.make_count_sql(api_ctx)
    local opts = pick_opts_in_args(api_ctx.args)
    opts.select_expr_list = string_format('COUNT(*) as `%s`',
                                          api_ctx.action_model.count_as)

    if api_ctx.action_model.index_to_use ~= nil then
        opts.force_index_clause = string_format(
                ' FORCE INDEX (%s)', api_ctx.action_model.index_to_use)
    end

    local sql, err, errmsg = api_ctx.sql_constructor:make_select_sql(
            {},
            api_ctx.action_model.param,
            api_ctx.args,
            opts)
    if err ~= nil then
        return nil, err, errmsg
    end

    api_ctx.sqls = {sql}

    return sql, nil, nil
end


function _M.make_group_count_sql(api_ctx)
    local fields = api_ctx.subject_model.fields
    local args = api_ctx.args

    local group_by_field = fields[args['group_by']]
    if group_by_field == nil then
        return nil, 'InvalidArgument', string_format(
                'the value of arg group_by: %s is not a field name',
                tostring(args['group_by']))
    end

    local opts = pick_opts_in_args(api_ctx.args)
    opts.select_expr_list = string_format('%s, COUNT(*) as `count`',
                                          group_by_field.select_expr)

    local group_by_clause = string_format(' GROUP BY %s',
                                          group_by_field.backticked_name)

    if args.group_by_desc ~= nil then
        group_by_clause = group_by_clause .. ' DESC'
    elseif args.group_by_asc ~= nil then
        group_by_clause = group_by_clause .. ' ASC'
    end

    opts.group_by_clause = group_by_clause

    local sql, err, errmsg = api_ctx.sql_constructor:make_select_sql(
            {},
            api_ctx.action_model.param,
            api_ctx.args,
            opts)
    if err ~= nil then
        return nil, err, errmsg
    end

    api_ctx.sqls = {sql}

    return sql, nil, nil
end


function _M.make_remove_sql(api_ctx)
    local opts = pick_opts_in_args(api_ctx.args)
    opts.limit = 1

    local sql, err, errmsg = api_ctx.sql_constructor:make_delete_sql(
            api_ctx.action_model.param,
            api_ctx.args,
            opts)
    if err ~= nil then
        return nil, err, errmsg
    end

    api_ctx.sqls = {sql}

    return sql, nil, nil
end


function _M.make_remove_multi_sql(api_ctx)
    local opts = pick_opts_in_args(api_ctx.args)

    local sql, err, errmsg = api_ctx.sql_constructor:make_delete_sql(
            api_ctx.action_model.param,
            api_ctx.args,
            opts)
    if err ~= nil then
        return nil, err, errmsg
    end

    api_ctx.sqls = {sql}

    return sql, nil, nil
end


function _M.make_replace_sql(api_ctx)
    local remove_sql, err, errmsg = _M.make_remove_sql(api_ctx)
    if err ~= nil then
        return nil, 'MakeReplaceSqlError', string_format(
                'failed to make remove sql: %s, %s', err, errmsg)
    end

    local add_sql, err, errmsg = _M.make_add_sql(api_ctx)
    if err ~= nil then
        return nil, 'MakeReplaceSqlError', string_format(
                'failed to make add sql: %s, %s', err, errmsg)
    end

    api_ctx.sqls = {remove_sql, add_sql}

    return {remove_sql, add_sql}, nil, nil
end


_M.sql_maker = {
    add = _M.make_add_sql,
    set = _M.make_set_sql,
    incr = _M.make_increase_sql,
    get = _M.make_get_sql,
    get_multi = _M.make_get_multi_sql,
    indexed_ls = _M.make_indexed_ls_sql,
    ls = _M.make_indexed_ls_sql,
    count = _M.make_count_sql,
    group_count = _M.make_group_count_sql,
    remove = _M.make_remove_sql,
    remove_multi = _M.make_remove_multi_sql,
    replace = _M.make_replace_sql,
}


function _M.make_sqls(api_ctx)
    api_ctx.sql_constructor = sql_constructor.new(
            api_ctx.upstream.table_name, api_ctx.subject_model.fields)

    local sql_type = api_ctx.action_model.sql_type

    local sql_maker_func = _M.sql_maker[sql_type]

    if sql_maker_func == nil then
        ngx.log(ngx.ERR, string_format(
                'no sql maker function for subject: %s, action: %s',
                api_ctx.subject, api_ctx.action))

        return nil, 'MakeSqlError', string_format(
                'no sql maker function for: %s', tostring(sql_type))
    end

    local _, err, errmsg = sql_maker_func(api_ctx)
    if err ~= nil then
        return nil, err, errmsg
    end

    ngx.log(ngx.INFO, string_format('made sqls for: %s %s, %s',
                                    api_ctx.subject, api_ctx.action,
                                    to_str(api_ctx.sqls)))
    return true, nil, nil
end


return _M
