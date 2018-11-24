local strutil = require('acid.strutil')


local math_random = math.random
local ngx = ngx


local _M = {_VERSION = '1.0'}
local _mt = { __index = _M }


local default_probability = 0.01
local avg_interval = 1.0 -- second


local function _probability(p)
    local r = math_random(1000*1000)
    return r < p * 1000 * 1000
end


function _M.new(_, storage, least_tps, probability)

    if probability == nil then
        probability = default_probability
    end

    -- to record events whose tps > least_tps
    -- for an event, the perceived tps = actual tps * probability
    -- to let this event persistent in storage, the timeout must:
    --      timeout >= 1 / perceived tps
    -- thus timeout = 1 / actual tps / probability
    local timeout = 1 / least_tps / probability

    local s = {
        storage=storage,
        probability=probability,
        least_tps=least_tps,
        timeout=timeout,
    }

    return setmetatable(s, _mt)
end


function _M:incr(key)

    if not _probability(self.probability) then
        return nil, nil, nil
    end

    local rst = self.storage:get(key)

    local now = ngx.now()
    local tps, tm

    if rst == nil then
        tps, tm = 0, now - avg_interval
    else
        rst = strutil.split(rst, ' ')
        tps, tm = tonumber(rst[1]), tonumber(rst[2])
    end

    local dtm = now - tm
    local tps_now = ((avg_interval - dtm) * tps + 1) / avg_interval

    if tps_now < 0 then
        tps_now = 0
    end
    local val = tostring(tps_now) .. ' ' .. tostring(now)

    local success, err, _ = self.storage:set(key, val, self.timeout)

    if not success then
        return nil, 'CounterIncrError', err
    end

    return tps_now / self.probability, nil, nil
end


function _M:get(key)

    local rst = self.storage:get(key)

    if rst == nil then
        return 0
    end
    rst = strutil.split(rst, ' ')
    return tonumber(rst[1]) / self.probability
end


return _M
