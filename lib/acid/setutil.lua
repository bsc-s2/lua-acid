local _M = {}

function _M.check_set_range(from, to)
    local f = tonumber(from)
    local t = tonumber(to)

    if f == nil or t == nil then
        return false, 'InvalidRange', string.format(
            'from: %s or to: %s is not a number', tostring(from), tostring(to))
    end

    if f > t then
        return false, 'InvalidRange', string.format(
            'from: %s is greater than to: %s', f, t)
    end

    return true
end


function _M.intersect(f1, t1, f2, t2)
    local _, err, err_msg = _M.check_set_range(f1, t1)
    if err ~= nil then
        return nil, err, err_msg
    end

    local _, err, err_msg = _M.check_set_range(f2, t2)
    if err ~= nil then
        return nil, err, err_msg
    end

    local intersection = {}

    local f, t = math.max(f1, f2), math.min(t1, t2)
    if f > t then
        -- no intersect
        return intersection
    end

    intersection = {
        from = f,
        to = t
    }
    return intersection
end

return _M
