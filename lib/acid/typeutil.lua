local _M = {}

local INF = math.huge


function _M.check_number_range(val, min, max, left_closed, right_closed)
    min = min or -INF
    max = max or INF

    if left_closed == nil then
        left_closed = true
    end

    if right_closed == nil then
        right_closed = true
    end

    if type(val) ~= 'number' then
        return false
    end

    if val < min or (val == min and not left_closed) then
        return false
    end

    if val > max or (val == max and not right_closed) then
        return false
    end

    return true
end


function _M.check_number_string_range(val, min, max, left_closed, right_closed)
    val = tonumber(val)
    if val == nil then
        return false
    end

    return _M.check_number_range(val, min, max, left_closed, right_closed)
end


function _M.is_int(val)
    if type(val) ~= 'number' or val % 1 ~= 0 then
        return false
    end

    return true
end


function _M.check_int_range(val, min, max)
    if _M.is_int(val) and _M.check_number_range(val, min, max, true, true) then
        return true
    end

    return false
end

return _M
