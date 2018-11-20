local math_random = math.random


local _M = {_VERSION = '1.0'}
local _mt = { __index = _M }


local default_probability = 0.01


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

    local rst, err, _ = self.storage:incr(
            key,
            1, -- incr by 1
            0, -- initial value
            self.timeout)

    if rst == nil then
        return nil, 'CounterIncrError', err
    end

    return rst, nil, nil
end


function _M:get(key)

    local rst = self.storage:get(key)

    if rst == nil then
        rst = 0
    end

    return rst
end


return _M
