local json = require('acid.json')


local _M = {}


local function general_json_decode(data, opts)
    if opts == nil then
        opts = {}
    end

    if data == ngx.null then
        return opts.null_to
    end

    if data == '' then
        return opts.empty_to
    end

    local value, err = json.dec(data)
    if err ~= nil then
        return nil, 'JsonDecodeError', string.format(
                'failed to json decode: %s, %s', tostring(data), err)
    end

    return value, nil, nil
end


local function null_to_null_json_decode(data)
    return general_json_decode(data, {null_to=ngx.null})
end


local function null_to_table_json_decode(data)
    return general_json_decode(data, {null_to={}})
end


local function null_or_empty_to_null_json_decode(data)
    return general_json_decode(data, {null_to=ngx.null, empty_to=ngx.null})
end


local function null_or_empty_to_table_json_decode(data)
    return general_json_decode(data, {null_to={}, empty_to={}})
end


local function acl_json_encode(acl)
    if type(acl) ~= 'table' then
        return nil, 'InvalidAcl', string.format(
                'acl: %s, is not a table, is type: %s',
                tostring(acl), type(acl))
    end

    for _, perms in pairs(acl) do
        if type(perms) ~= 'table' then
            return nil, 'InvalidAclPermissions', string.format(
                    'permissions: %s, is not a table, is type: %s',
                    tostring(perms), type(perms))
        end
        setmetatable(perms, json.empty_array_mt)
    end

    return json.enc(acl)
end


local function acl_json_decode(acl_text)
    if acl_text == ngx.null then
        return ngx.null, nil, nil
    end

    local acl, err = json.dec(acl_text)
    if err ~= nil then
        return nil, 'JsonDecodeError', string.format(
                'failed to json decode acl text: %s, %s',
                acl_text, err)
    end

    for _, perms in pairs(acl) do
        if #perms == 0 then
            setmetatable(perms, json.empty_array_mt)
        end
    end

    return acl, nil, nil
end


local convert_methods = {
    json_general = {
        encode = json.enc,
        decode = general_json_decode,
    },
    json_null_to_null= {
        encode = json.enc,
        decode = null_to_null_json_decode,
    },
    json_null_to_table = {
        encode = json.enc,
        decode = null_to_table_json_decode,
    },
    json_null_or_empty_to_null = {
        encode = json.enc,
        decode = null_or_empty_to_null_json_decode,
    },
    json_null_or_empty_to_table = {
        encode = json.enc,
        decode = null_or_empty_to_table_json_decode,
    },
    json_acl = {
        encode = acl_json_encode,
        decode = acl_json_decode,
    },
}


function _M.convert_arg(api_ctx)
    local args = api_ctx.args
    local fields = api_ctx.subject_model.fields

    for arg_name, arg_value in pairs(args) do
        local convert_method = (fields[arg_name] or {}).convert_method

        if convert_method ~= nil then
            local convert_model = convert_methods[convert_method].encode
            if convert_model == nil then
                return nil, 'InvalidConvertMethod', string.format(
                        'convert method: %s is not supported', convert_method)
            end
            local converted_value, err, errmsg = convert_model.encode(arg_value)
            if err ~= nil then
                return nil, err, errmsg
            end
            args[arg_name] = converted_value
        end
    end

    return true, nil, nil
end


local function decode_all_record(records, field_name, decode_func)
    for _, record in ipairs(records) do
        local origin_value = record[field_name]

        local decoded_value, err, errmsg = decode_func(origin_value)
        if err ~= nil then
            return nil, 'ConvertResultError', string.format(
                    'failed to decode field: %s, with value: %s, %s, %s',
                    field_name, tostring(origin_value), err, errmsg)
        end
        record[field_name] = decoded_value
    end

    return true, nil, nil
end


function _M.convert_result(api_ctx)
    local query_result = api_ctx.query_result
    local fields = api_ctx.subject_model.fields
    local select_column = api_ctx.action_model.select_column

    if select_column == nil then
        return true, nil, nil
    end

    for _, field_name in ipairs(select_column) do
        local convert_method = fields[field_name].convert_method
        if convert_method ~= nil then
            local convert_model = convert_methods[convert_method]
            if convert_model == nil then
                return nil, 'InvalidConvertMethod', string.format(
                        'convert method: %s is not supported', convert_method)
            end

            local _, err, errmsg = decode_all_record(
                    query_result, field_name, convert_model.decode)
            if err ~= nil then
                return nil, err, errmsg
            end
        end
    end

    return true, nil, nil
end


return _M
