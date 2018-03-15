local ngx_timer = require('ngx_timer')

local _M = {}

local _mt = {__index = _M}


function _M.fetch_conf_safe(self)
    local curr_version = (self.conf or {}).version

    ngx.log(ngx.INFO, string.format(
            'conf ##: worker %d start to get conf with current version: %s',
            ngx.worker.id(), tostring(curr_version)))

    local curr_conf = self.conf
    local ok, err_or_conf, err, errmsg = pcall(self.fetch_conf, curr_conf)
    if not ok then
        ngx.log(ngx.ERR, string.format(
                'conf ##: failed to run fetch_conf: %s', err_or_conf))
        return nil, 'FetchConfError', 'failed to run fetch_conf'
    end

    if err ~= nil then
        ngx.log(ngx.ERR, string.format(
                'conf ##: fetch_conf return error: %s, %s', err, errmsg))
        return nil, 'FetchConfError', 'fetch_conf return error'
    end

    ngx.log(ngx.INFO, string.format(
            'conf ##: worker %d current conf version: %s',
            ngx.worker.id(), tostring(err_or_conf.version)))

    self.conf = err_or_conf

    return self.conf, nil, nil
end


function new(fetch_conf)
    local self = {
        fetch_conf = fetch_conf,
        conf = nil,
    }

    setmetatable(self, _mt)

    local _, err, errmsg = self:fetch_conf_safe()
    if err ~= nil then
        return nil, err, errmsg
    end

    local _, err, errmsg = ngx_timer.loop_work(
            0.5, self.fetch_conf_safe, self)
    if err ~= nil then
        ngx.log(ngx.ERR, 'conf ##: failed to init ngx timer')
        return nil, err, errmsg
    end

    return self, nil, nil
end


return _M
