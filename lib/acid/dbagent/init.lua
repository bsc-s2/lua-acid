local conf_util = require('acid.dbagent.conf_util')
local model_module = require('acid.dbagent.model_module')

local _M = {}


function _M.init(opts)
    if opts == nil then
        opts = {}
    end

    local model_module_dir = opts.model_module_dir or 'lib/acid/dbagent'
    local get_conf = opts.get_conf

    local _, err, errmsg = model_module.load_model_module(model_module_dir)
    if err ~= nil then
        ngx.log(ngx.ERR, string.format(
                'failed to load model module from: %s, %s, %s',
                model_module_dir, err, errmsg))
    end
    conf_util.init_conf_update(get_conf)
end


return _M
