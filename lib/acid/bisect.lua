local tableutil = require('acid.tableutil')


local _M = {}


function _M.search(array, key, opts)

    -- Return boolean `found` and int `index` so that:
    --
    --      array[index] <= key < array[index + 1]

    opts = opts or {}
    local cmp = opts.cmp or tableutil.cmp_list

    local l = 0
    local r = #array + 1
    local mid
    local found

    while l < r - 1 do
        mid = l + r
        mid = (mid - mid % 2) / 2

        local rst = cmp(key, array[mid])
        if rst == 0 then
            return true, mid
        elseif rst > 0 then
            l = mid
        elseif rst < 0 then
            r = mid
        end
    end

    return false, l
end


return _M
