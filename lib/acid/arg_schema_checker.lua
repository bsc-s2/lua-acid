-------------------------------------------------------------------------------
---- arg_schema_checker.lua
----
---- this module is used to check values according to schema.
-------------------------------------------------------------------------------
local strutil   = require('acid.strutil')
local tableutil = require('acid.tableutil')
local yaml      = require('yaml')


local INF                    = math.huge
local _M                     = { _VERSION = '1.0' }
local mt                     = { __index = _M }
local CHECKER_FUNCTION_TABLE = {}


local CHECKER_INFO = {
    any           = {
                        func  = 'check_any',
                        types = {
                                    boolean = true,
                                    number  = true,
                                    string  = true,
                                    table   = true
                                },
                    },
    array         = {
                        func  = 'check_array',
                        types = { table = true },
                    },
    bool          = {
                        func  = 'check_bool',
                        types = { boolean = true },
                    },
    dict          = {
                        func  = 'check_dict',
                        types = { table = true },
                    },
    float         = {
                        func  = 'check_float',
                        types = { number = true },
                    },
    integer       = {
                        func  = 'check_integer',
                        types = { number = true },
                    },
    string_number = {
                        func  = 'check_string_number',
                        types = { string = true },
                    },
    string        = {
                        func  = 'check_string',
                        types = { string = true },
                    },
}


-- Based on CJSON lib function is_array.
local function get_table_type(table)
    local max = 0
    local count = 0

    for k, _ in pairs(table) do
        if type(k) == "number" then
            if k > max then
                max = k
            end

            count = count + 1
        else
            return 'not an array'
        end
    end

    -- NOTE: This might return "not an array" for very sparse arrays.
    if max > count * 2 then
        return 'not an array'
    end

    if max == 0 then
        return 'empty'
    end

    return 'array'
end


local function is_array(table)
    if type(table) ~= 'table' then
        return false
    end

    return get_table_type(table) ~= 'not an array'
end


local function is_dict(table)
    if type(table) ~= 'table' then
        return false
    end

    return get_table_type(table) ~= 'array'
end


local function validate_schema(schema, value_t)
    local schema_t = schema['type']

    if schema_t == nil then
        return false, 'InvalidSchema', string.format('no type specified: %s',
                                                     strutil.to_str(schema))
    end

    local type_info = CHECKER_INFO[schema_t]
    if type_info == nil then
        return false, 'InvalidSchema', string.format('unsupported type: %s',
                                                     strutil.to_str(schema))
    end

    if type_info.types[value_t] == nil then
        return false, 'InvalidType',
               string.format('unsupported type to checker, %s, %s',
                             value_t, strutil.to_str(type_info.types))
    end

    return true, nil, nil
end


local function make_type_schemas(schemas, value)
    local value_t       = type(value)
    local failed_info   = {}
    local valid_schemas = {}

    for _, schema in ipairs(schemas or {}) do
        local valid, err, errmsg = validate_schema(schema, value_t)
        -- We don't ignore invalid schemas
        if err == 'InvalidSchema' then
            return nil, err, errmsg
        end

        if valid then
            table.insert(valid_schemas, schema)

            -- TODO: make a log module to remove the dependency on ngx
            ngx.log(ngx.DEBUG,
                    string.format('choosen schema: %s', strutil.to_str(schema)))
        else
            table.insert(failed_info,
                         { schema = schema, err = err, errmsg = errmsg })
        end
    end

    if #valid_schemas == 0 then
        local str_val = strutil.to_str(value)
        ngx.log(ngx.ERR,
                string.format('Invalid type for value: %s, detail:',
                              str_val, strutil.to_str(failed_info)))
        return nil, 'InvalidType', 'Invalid type for ' .. str_val
    end

    return valid_schemas, nil, nil
end


local function _format_schemas(value, schemas)
    if value == nil then
        return nil, 'InvalidArgument', 'value is nil'
    end

    if schemas == nil then
        return nil, 'InvalidArgument', 'schemas is nil'
    end

    if not is_array(schemas) then
        schemas = { schemas }
    end

    local valid_schemas, err, errmsg = make_type_schemas(schemas, value)
    if err ~= nil then
        return nil, err, errmsg
    end

    return valid_schemas, nil, nil
end


local function enums_checker(value, enums)
    if enums ~= nil and not tableutil.has(enums, value) then
        return false, 'NotInEnum', string.format('value %s not in enums %s',
                                                 value,
                                                 strutil.to_str(enums))
    end

    return true, nil, nil
end


local function invalid_values_checker(value, excludes)
    if excludes ~= nil and tableutil.has(excludes, value) then
        return false, 'InvalidValue', string.format('%s is among invalid values %s',
                                                    value,
                                                    strutil.to_str(excludes))
    end

    return true, nil, nil
end


local function regexp_checker(value, regex)
    if regex ~= nil then
        local m, err = ngx.re.match(value, regex)
        if err then
            return false,
                   'InvalidPattern',
                   string.format('invalid regex: %s', regex)
        end

        if not m then
            return false,
                   'PatternNotMatch',
                   string.format('%s not match pattern %s', value, regex)
        end
    end

    return true, nil, nil
end


local function number_range_checker(value, min, max)
    local min = min or -INF
    local max = max or INF

    value = tonumber(value)
    if value > max or value < min then
        return false,
               'OverRange',
               string.format('Expect range [%s, %s], got %s', min, max, value)
    end

    return true, nil, nil
end


local function fixed_length_checker(value, length)
    if length ~= nil and #value ~= length then
        return false,
               'InvalidLength',
               string.format('Expect length %s, got %s', length, #value)
    end

    return true, nil, nil
end


local function length_range_checker(value, min_len, max_len)
    if min_len ~= nil or max_len ~= nil then
        local ret, err, errmsg = number_range_checker(#value, min_len, max_len)

        if not ret then
            return false, 'InvalidLength', string.format('%s: %s', err, errmsg)
        end
    end

    return true, nil, nil
end


local function elements_checker(value, schema)
    if not is_array(value) then
        return false, 'InvalidType', 'value must be array'
    end

    if schema then
        for _, elt in ipairs(value) do
            local valid, err, errmsg = _M.do_check(elt, schema)
            if not valid then
                return false, err, errmsg
            end
        end
    end

    return true, nil, nil
end


local function k_v_checker(value, schema)
    if type(value) ~= 'table' then
        return false, 'InvalidType', 'value is not table'
    end

    local k_schema = schema.key_checker
    local v_schema = schema.value_checker

    if k_schema == nil and v_schema == nil then
        return true, nil, nil
    end

    for k, v in pairs(value) do
        local valid, err, errmsg

        if k_schema ~= nil then
            valid, err, errmsg = _M.do_check(k, k_schema)
            if not valid then
                return false, err, errmsg
            end
        end

        if v_schema ~= nil then
            valid, err, errmsg = _M.do_check(v, v_schema)
            if not valid then
                return false, err, errmsg
            end
        end
    end

    return true, nil, nil
end


local function sub_schema_checker(value, sub_schema)
    if sub_schema == nil or sub_schema == {} then
        return true, nil, nil
    end

    return _M.check_arguments(value, sub_schema)
end


function _M.check_bool(value, schema)
    local _ = schema

    if type(value) ~= 'boolean' then
        return false, 'InvalidType', 'value is not boolean'
    end

    return true, nil, nil
end


function _M.check_any(value, schema)
    local _, _ = value, schema

    return true, nil, nil
end


local function execute_check_table(check_tbl)
    for _, checker in ipairs(check_tbl) do
        local valid, err, errmsg = checker.func(table.unpack(checker.args))

        if not valid then
            return false, err, errmsg
        end
    end

    return true, nil, nil
end


function _M.check_string(value, schema)
    if type(value) ~= 'string' then
        return false, 'InvalidType', string.format('value is not a string: %s',
                                                   type(value))
    end

    if schema == nil then
        return false, 'InvalidArgument', 'schema is nil'
    end

    local check_tbl = {
        {
            ['func'] = fixed_length_checker,
            ['args'] = { value, schema.fixed_length }
        },
        {
            ['func'] = length_range_checker,
            ['args'] = {
                value,
                schema.min_length,
                schema.max_length
            },
        },
        {
            ['func'] = enums_checker,
            ['args'] = { value, schema.enum },
        },
        {
            ['func'] = invalid_values_checker,
            ['args'] = { value, schema['not'] },
        },
        {
            ['func'] = regexp_checker,
            ['args'] = { value, schema.regexp },
        },
    }

    return execute_check_table(check_tbl)
end


function _M.check_number(value, schema)
    if schema == nil then
        return false, 'InvalidArgument', 'schema is nil'
    end

    local check_tbl = {
        {
            ['func'] = number_range_checker,
            ['args'] = { value, schema.min, schema.max },
        },
        {
            ['func'] = enums_checker,
            ['args'] = { value, schema.enum },
        },
        {
            ['func'] = invalid_values_checker,
            ['args'] = { value, schema['not'] },
        },
    }

    return execute_check_table(check_tbl)
end


function _M.check_float(value, schema)
    if type(value) ~= 'number' then
        return false,
               'InvalidType',
               string.format('Expect float, got %s', type(value))
    end

    return _M.check_number(value, schema)
end


function _M.check_integer(value, schema)
    if type(value) ~= 'number' then
        return false,
               'InvalidType',
               string.format('Expect integer, got %s', type(value))
    end

    if value % 1 ~= 0 then
        return false,
               'InvalidType',
               string.format('Expect integer, got %s', value)
    end

    return _M.check_number(value, schema)
end


function _M.check_string_number(value, schema)
    if type(value) ~= 'string' then
        return false, 'InvalidType', string.format('value is not a string: %s',
                                                   type(value))
    end

    if tonumber(value) == nil then
        return false,
               'InvalidType',
               string.format('expect a string number, got %s', tostring(value))
    end

    return _M.check_number(value, schema)
end


function _M.check_array(value, schema)
    if not is_array(value) then
        return false,
               'InvalidType',
               string.format('Expected array, got dict %s', strutil.to_str(value))
    end

    local check_tbl = {
        {
            ['func'] = fixed_length_checker,
            ['args'] = { value, schema.fixed_length },
        },
        {
            ['func'] = length_range_checker,
            ['args'] = {
                value,
                schema.min_length,
                schema.max_length
            },
        },
        {
            ['func'] = elements_checker,
            ['args'] = { value, schema.element_checker },
        },
    }

    return execute_check_table(check_tbl)
end


function _M.check_dict(value, schema)
    if not is_dict(value) then
        return false, 'InvalidType', string.format('Expected dict, got array %s',
                                                   strutil.to_str(value))
    end

    local check_tbl = {
        {
            ['func'] = fixed_length_checker,
            ['args'] = { value, schema.fixed_length },
        },
        {
            ['func'] = length_range_checker,
            ['args'] = {
                value,
                schema.min_length,
                schema.max_length,
            },
        },
        {
            ['func'] = k_v_checker,
            ['args'] = { value, schema },
        },
        {
            ['func'] = sub_schema_checker,
            ['args'] = { value, schema.sub_schema },
        },
    }

    return execute_check_table(check_tbl)
end


local cached_schema_by_path = {}


function _M.read_schema_uncached(path)
    if path == nil or path == '' then
        return nil, 'InvalidArgument', string.format('path is invalid: [%s]', path)
    end

    local file, err = io.open(path)
    if err then
        return nil, 'SchemaNotFound', string.format('failed to open %s, %s', path, err)
    end

    local schema = file:read('*a')
    file:close()

    if schema == nil then
        return nil, 'SchemaReadError', string.format('failed to read %s', path)
    end

    return yaml.load(schema)
end


function _M.read_schema_cached(path)
    if cached_schema_by_path[path] ~= nil then
        return cached_schema_by_path[path], nil, nil
    end

    local schema, err, msg = _M.read_schema_uncached(path)
    if err ~= nil then
        return nil, err, msg
    end

    -- Cache the task_schema so we don't read disk next time.
    cached_schema_by_path[path] = schema
    return schema, nil, nil
end


local function make_default_checker_tbl()
    local checker_tbl = {}

    for _, checker_info in pairs(CHECKER_INFO) do
        checker_tbl[checker_info.func] = _M[checker_info.func]
    end

    return checker_tbl
end


function _M.new(_, argument_name, value, schemas)
    local err, errmsg

    argument_name = argument_name or ''

    schemas, err, errmsg = _format_schemas(value, schemas)
    if err then
        return nil, err, errmsg
    end

    local data = {
        value    = value,
        schemas  = schemas,
        arg_name = argument_name,
    }

    return setmetatable(data, mt), nil, nil
end


function _M.do_check(value, schemas, skip_schema_check, checker_tbl)
    checker_tbl       = checker_tbl or CHECKER_FUNCTION_TABLE
    skip_schema_check = skip_schema_check == false

    local err, errmsg
    if not skip_schema_check then
        schemas, err, errmsg = _format_schemas(value, schemas)
        if err then
            return false, err, errmsg
        end
    end

    local pass_check  = false
    local failed_info = {}

    for _, schema in ipairs(schemas) do
        local check_func_name = CHECKER_INFO[schema['type']].func
        local check_func      = checker_tbl[check_func_name]

        if check_func == nil then
            return false, 'ProgrammingError',
                   string.format('no check func for %s', strutil.to_str(schema))
        end

        local valid, err, errmsg = check_func(value, schema)
        if valid then
            ngx.log(ngx.DEBUG, string.format('%s pass check %s',
                                             strutil.to_str(value),
                                             strutil.to_str(schema)))
            pass_check = true
            break
        else
            table.insert(failed_info,
                         { schema = schema, err = err, errmsg = errmsg })
        end
    end

    if not pass_check then
        local str_val = strutil.to_str(value)
        ngx.log(ngx.INFO,
                string.format('all check failed for value: %s, detail: %s',
                              str_val, strutil.to_str(failed_info)))

        local err
        if #failed_info == 1 then
            err = failed_info[1].err
            errmsg = failed_info[1].errmsg
        else
            err = 'ArgumentCheckError'
            errmsg = 'Invalid Value: ' .. str_val
        end

        return false, err, errmsg
    end

    return true, nil, nil
end


function _M.check(self)
    local valid, err, errmsg = _M.do_check(self.value, self.schemas, true, self)
    if not valid then
        return false, err, string.format('Invalid argument %s: %s',
                                         self.arg_name, errmsg)
    end

    return true, nil, nil
end


function _M.check_arguments(args, schema)
    args = args or {}
    for arg, arg_schema in pairs(schema) do
        if arg_schema.required and args[arg] == nil then
            return false, 'LackArgument', 'Lack required argument: ' .. arg
        end
    end

    for arg, val in pairs(args) do
        if schema[arg] == nil then
            return false, 'ExtraArgument', 'Extra argument: ' .. arg
        end

        ngx.log(ngx.DEBUG, string.format('arg: %s, val: %s, schema: %s',
                                         arg,
                                         strutil.to_str(val),
                                         strutil.to_str(schema[arg].checker)))

        local valid, err, errmsg = _M.do_check(val, schema[arg].checker)
        if not valid then
            return false, err, string.format('Invalid argument %s: %s',
                                             arg, errmsg)
        end
    end

    return true, nil, nil
end


function _M.validate_args_by_schema_path(args, schema_path)
    local schema, err, errmsg = _M.read_schema_cached(schema_path)
    if err ~= nil then
        return false, err, errmsg
    end

    return _M.check_arguments(args, schema)
end


CHECKER_FUNCTION_TABLE = make_default_checker_tbl()


return _M
