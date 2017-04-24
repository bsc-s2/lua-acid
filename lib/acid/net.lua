local strutil = require("acid.strutil")

local strutil_strip = strutil.strip
local strutil_split = strutil.split

local PUB = 'PUB'
local INN = 'INN'

local _intra_patterns = {
    '^172[.]1[6-9][.]',
    '^172[.]2[0-9][.]',
    '^172[.]3[0-1][.]',
    '^10[.]',
    '^192[.]168[.]',
}

local _M = { _VERSION = "0.1" }

_M.PUB = PUB
_M.INN = INN


function _M.is_ip4(ip)

    if type(ip) ~= 'string' then
        return false
    end

    local elts = strutil_split(ip, '.', true)

    local n
    for i, elt in ipairs(elts) do
        n = tonumber(elt)
        if n == nil or n < 0 or n > 255  then
            return false
        end
    end

    return #elts == 4
end


function _M.parse_ip_regexs(ip_regexs_str)

    ip_regexs_str = strutil_strip(ip_regexs_str)

    local regs = strutil_split(ip_regexs_str, ",")
    local rst = {}
    for _, r in ipairs(regs) do
        if strutil.startswith(r, '-') then
            r = {r:sub(2), false}
        else
            r = {r, true}
        end

        if r[1] == '' then
            error('invalid ip regex: ' .. ip_regexs_str)
        end

        if r[2] then
            r = r[1]
        end

        table.insert(rst, r)
    end

    return rst
end


function _M.choose_by_regex(ips, ip_regexs)

    --[[
    Choose ips that matches any of positive regex(without minus"-"), and does
    not match all of negative regex(with minus"-").

    eg.:
    -   '-127[.]'
        returns any non-localhost ip

    -   '192[.],10[.],-.*[.]1,-.*[.]3'
        returns intra net ip that starts with "192." or "10.", but not ends
        with ".1" or ".3.
    ]]

    local rst = {}

    for _, ip in ipairs(ips) do

        local all_negative = true
        local matched = false

        for _, ip_regex in ipairs(ip_regexs) do

            local reg, to_choose
            if type(ip_regex) == 'table' then
                reg = ip_regex[1]
                to_choose = ip_regex[2]
            else
                reg = ip_regex
                to_choose = true
            end

            all_negative = all_negative and not to_choose

            if string.match(ip, reg) then
                matched = true
                if to_choose then
                    table.insert(rst, ip)
                end
                break
            end
        end

        -- If there is not a positive regex, there is no chance for an ip to
        -- be added into `rst`.
        -- Thus we need to check if there are only negative regexs and add
        -- it.

        if not matched then
            if all_negative then
                table.insert(rst, ip)
            end
        end
    end

    return rst
end


return _M
