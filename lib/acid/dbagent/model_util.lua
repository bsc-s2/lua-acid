local arg_util = require('acid.dbagent.arg_util')
local dbagent_conf = require('dbagent_conf')
local sql_util = require('acid.dbagent.sql_util')


local _M = {}


local function setup_models(models)
    for _, subject_model in pairs(models) do
        for field_name, field in pairs(subject_model.fields) do
            local backticked_name = string.format('`%s`', field_name)
            field.backticked_name = backticked_name

            sql_util.build_field_as_str(field_name, field)
            arg_util.build_field_schema(field)
        end
    end
end


setup_models(dbagent_conf.models)


function _M.pick_model(api_ctx)
    local models = dbagent_conf.models

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
