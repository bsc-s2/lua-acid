local _M = {}

local INF = math.huge

function _M.is_string(val)
    if type(val) ~= 'string' then
        return false
    end
    return true
end

function _M.is_number(val)
    if type(val) ~= 'number' then
        return false
    end
    return true
end

function _M.is_integer(val)
    if _M.is_number(val) ~= true then
        return false
    end
    if val % 1 ~= 0 then
        return false
    end
    return true
end

function _M.is_boolean(val)
    if type(val) ~= 'boolean' then
        return false
    end
    return true
end

function _M.is_string_number(val)
    if type(val) ~= 'string' then
        return false
    end
    if tonumber(val) == nil then
        return false
    end
    return true
end

-- CJSON array
function _M.is_array(val)
    if type(val) ~= 'table' then
        return false
    end

    if _M.is_empty_table(val) then
        return true
    end

    local ratio = 2
    local safe = 10

    local max = 0
    local count = 0

    for k, _ in pairs(val) do
        if type(k) == 'number' then
            if k > max then
                max = k
            end
            count = count + 1
        else
            return false
        end
    end

    -- This is a excessively sparse array.
    if max > safe and max > ratio * count then
        return false
    end

    return true
end

function _M.is_dict(val)
    if type(val) ~= 'table' then
        return false
    end

    if _M.is_empty_table(val) then
        return true
    end

    return _M.is_array(val) == false
end

function _M.is_empty_table(val)

    if type(val) ~= 'table' then
        return false
    end

    if next(val) == nil then
        return true
    end

    return false
end

function _M.check_number_range(val, min, max, opts)

    if _M.is_number(val) == false then
        return false
    end

    local min = min or -INF
    local max = max or INF

    if opts == nil then
        opts = {}
    end

    if val < min or (val == min and opts.left_closed == false) then
        return false
    end

    if val > max or (val == max and opts.right_closed == false) then
        return false
    end

    return true
end

function _M.check_string_number_range(val, min, max, opts)
    if _M.is_string_number(val) then
        return _M.check_number_range(tonumber(val), min, max, opts)
    end

    return false
end

function _M.check_integer_range(val, min, max, opts)
    if _M.is_integer(val) and _M.check_number_range(val, min, max, opts) then
        return true
    end

    return false
end

function _M.check_length_range(val, min, max, opts)
    return _M.check_number_range(#val, min, max, opts)
end

function _M.check_fixed_length(val, length)
    return #val == length
end

return _M
