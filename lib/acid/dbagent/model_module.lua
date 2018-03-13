local arg_util = require('acid.dbagent.arg_util')
local fsutil = require('acid.fsutil')
local sql_util = require('acid.dbagent.sql_util')
local strutil = require('acid.strutil')


local _M = {}

_M.models = nil


local function get_model_names(model_module_dir)
    local dir = model_module_dir .. '/models'
    local file_names, err, errmsg = fsutil.read_dir(dir)
    if err ~= nil then
        return nil, err, errmsg
    end

    local model_names = {}
    for _, file_name in ipairs(file_names) do
        if strutil.endswith(file_name, '.lua') then
            table.insert(model_names, string.sub(file_name, 1, -5))
        end
    end

    return model_names, nil, nil
end


local function setup_field(fields)
    for field_name, field in pairs(fields) do
        local backticked_name = string.format('`%s`', field_name)
        field.backticked_name = backticked_name

        sql_util.build_field_as_str(field_name, field)
        arg_util.build_field_schema(field)
    end

    return true, nil, nil
end


local function setup_models(models)
    for _, subject_model in pairs(models) do
        local _, err, errmsg = setup_field(subject_model.fields)
        if err ~= nil then
            return nil, err, errmsg
        end
    end

    return true, nil, nil
end


function _M.load_model_module(model_module_dir)
    if _M.models ~= nil then
        return _M.models
    end

    local models = {}
    local model_names, err, errmsg = get_model_names(model_module_dir)
    if err ~= nil then
        return nil, err, errmsg
    end

    for _, name in ipairs(model_names) do
        local ok, mod = pcall(require, 'acid.dbagent.models.' .. name)
        if not ok then
            return nil, 'LoadModuleError', string.format(
                    'failed to load module: %s, %s', name, mod)
        end

        models[name] = mod
    end

    local _, err, errmsg = setup_models(models)
    if err ~= nil then
        return nil, err, errmsg
    end

    _M.models = models

    return _M.models, nil, nil
end


function _M.pick_model(api_ctx)
    local models = _M.models
    if models == nil then
        return nil, 'ModelNotLoadedError', 'models not loaded'
    end

    local subject_model = models[api_ctx.subject]
    if subject_model == nil then
        return nil, 'InvalidArgument', string.format(
                'invalid subject: %s, not supported', api_ctx.subject)
    end
    api_ctx.subject_model = subject_model

    local action_model = subject_model['actions'][api_ctx.action]
    if action_model == nil then
        return nil, 'InvalidArgument', string.format(
                'subject: %s does not have action: %s',
                api_ctx.subject, api_ctx.action)
    end
    api_ctx.action_model = action_model

    return true, nil, nil
end


return _M
