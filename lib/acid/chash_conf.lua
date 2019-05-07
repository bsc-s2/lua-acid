local acid_chash = require("acid.chash")
local ngx_timer = require("acid.ngx_timer")
local semaphore = require("ngx.semaphore")

local _M = { _VERSION = "0.1" }
local mt = { __index = _M }

local servers_expires_seconds = 600
local servers_updates_seconds = 300

function _M.update_chash(self)
    local conf = self.conf

    local _, err = conf.semaphore:wait(3)
    if err then
        ngx.log(ngx.INFO, err, " other timer is updating servers")
        return
    end

    local now = ngx.time()
    if now < conf.updates then
        ngx.log(ngx.INFO, "servers were updated by other timer")
        conf.semaphore:post(1)
        return
    end

    local servers = conf.get_servers()
    if servers == nil then
        conf.semaphore:post(1)
        return
    end

    local now = ngx.time()
    if conf.chash == nil then
       conf.chash = acid_chash.new(servers)
    else
        conf.chash:update_server(servers)
    end

    conf.expires = now + conf.servers_expires_seconds
    conf.updates = now + conf.servers_updates_seconds

    ngx.log(ngx.INFO, "consistent hash built")
    conf.semaphore:post(1)
end

function _M.get_chash(self)
    local conf = self.conf
    local now = ngx.time()

    if now >= conf.updates then
        if conf.updates == 0 or now >= conf.expires then
            self:update_chash()
        else
            ngx_timer.at(0.01, self.update_chash, self)
        end
    end

    if now < conf.expires then
        return conf.chash
    else
        ngx.log(ngx.ERR, "consistent servers was expired")
    end

    return nil
end

function _M.new(conf)
    if conf.servers_expires_seconds == nil then
        conf.servers_expires_seconds = servers_expires_seconds
    end

    if conf.servers_updates_seconds == nil then
        conf.servers_updates_seconds = servers_updates_seconds
    end

    conf.semaphore = semaphore.new(1)
    conf.expires = 0
    conf.updates = 0

    return setmetatable({
        conf=conf,
    },mt)
end

return _M
