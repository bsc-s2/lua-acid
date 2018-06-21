--example, how to use
--  local ranges, err, errmsg = rangeset.new({{1, 2, "foo"}, {4, 5, "bar"}})
--  local v, err, errmsg = ranges:get(1)
--
local bisect    = require('acid.bisect')
local strutil   = require('acid.strutil')
local tableutil = require('acid.tableutil')

local _M = { _VERSION = '1.0' }
local mt = { __index  = _M }


local function cmp_boundary(l, r)
    if l == nil then
        return -1
    end

    if r == nil then
        return -1
    end

    if l < r then
        return -1
    elseif l > r then
        return 1
    else
        return 0
    end

end


local function cmp(a, b)
    if cmp_boundary(a[1], b[2]) >= 0 then
        return 1
    end

    if cmp_boundary(b[1], a[2]) >= 0 then
        return -1
    end

    return 0
end


local function cmp_val(a, b, none_cmp_finite)
    if a == nil then
        if b == nil then
            return 0

        else
            return none_cmp_finite

        end

    else
         if b == nil then
             return -none_cmp_finite

         else
             if a < b then
                 return -1

             elseif a > b then
                 return 1

             else
                 return 0

             end
         end
     end
end


local function has(range, val)
     return (cmp_val(range[1], val, -1) <= 0
             and cmp_val(val, range[2], 1) < 0)
end



function _M.new(ranges)
    local rngs = tableutil.dup(ranges, true)
    for i = 1, #rngs - 1, 1 do
        local curr = rngs[i]
        local nxt = rngs[i + 1]

        if cmp(curr, nxt) ~= -1 then
            return nil, "ValueError", "range must be smaller than next one"
        end
    end

    return setmetatable(rngs, mt), nil, nil
end


function _M.get(self, pos)
    local rng = {pos, nil}
    local opts = {
        cmp = cmp
    }

    local ok, idx = bisect.search(self, rng, opts)
    if not ok or not has(self[idx], pos) then
        return nil, "KeyError", strutil.to_str(pos, " not in range")
    end

    return self[idx][3], nil, nil
end

return _M
