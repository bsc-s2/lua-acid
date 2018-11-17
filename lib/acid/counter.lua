

local math_random = math.random


local _M = {_VERSION = '1.0'}


local _mt = {}


local function _probability(p)
    local r = math_random(1000*1000)
    return r < p
end


function _M:new(storage, probability, least_rps)
    local self = {
        storage=storage,
        probability=probability,
        least_rps=least_rps,
        timeout=1 / least_rps / probability * 1.2,
    }

    return setmetatable(self, _mt)
end


function _mt:incr(key)

    if not _probability(self.probability) then
        return nil, nil, nil
    end

    local timeout = 1 / self.least_rps / probability

    local rst, err, forcible = self.storage:incr(
            key,
            1, -- incr by 1
            0, -- initial value
            self.timeout)

    if rst == nil then
        return nil, 'CounterIncrError', err
    end

    return rst, nil, nil
end


function _mt:get(key)

    local rst = self.storage:get(key)

    if rst == nil then
        rst = 0
    end

    return rst
end
