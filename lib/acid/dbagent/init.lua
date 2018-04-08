local model_util = require('acid.dbagent.model_util')
local upstream_util = require('acid.dbagent.upstream_util')
local ngx_timer = require('acid.ngx_timer')

local _M = {}


function _M.init()
    local _, err, errmsg = model_util.setup_models()
    if err ~= nil then
        ngx.log(ngx.ERR, string.format(
                'failed to setup models: %s, %s', err, errmsg))
    end

    local _, err, errmsg = ngx_timer.at(
            0, upstream_util.init_upstream_config)
    if err ~= nil then
        ngx.log(ngx.ERR, string.format(
                'conf ##: failed to init ngx timer: %s, %s', err, errmsg))
    end
end


return _M
