local bit = require('bit')
local strutil = require('acid.strutil')
local tableutil = require('acid.tableutil')

local string_match = string.match
local table_insert = table.insert

local strutil_split = strutil.split
local strutil_startswith = strutil.startswith
local strutil_strip = strutil.strip
local tableutil_extends = tableutil.extends

local PUB = 'PUB'
local INN = 'INN'

local _intra_patterns = {
    '^172[.]1[6-9][.]',
    '^172[.]2[0-9][.]',
    '^172[.]3[0-1][.]',
    '^10[.]',
    '^192[.]168[.]',
}

local binary_masks = {}
local reverse_binary_masks = {}

for i = 0, 32 do
    binary_masks[i] = bit.lshift(2 ^ i - 1, 32 - i)
    reverse_binary_masks[i] = bit.bnot(binary_masks[i])
end

local signed_range = 2 ^ 32

local _M = { _VERSION = "0.1" }

_M.PUB = PUB
_M.INN = INN


function _M.is_ip4(ip)

    if type(ip) ~= 'string' then
        return false
    end

    local elts = strutil_split(ip, '.', true)

    local n
    for _, elt in ipairs(elts) do
        n = tonumber(elt)
        if n == nil or n < 0 or n > 255  then
            return false
        end
    end

    return #elts == 4
end


function _M.is_ip4_loopback(ip)
    return _M.is_ip4(ip) and strutil_startswith(ip, '127.')
end


function _M.ip_class(ip)

    if _M.is_ip4_loopback(ip) then
        return INN
    end

    for _, ptn in ipairs(_intra_patterns) do

        if string_match(ip, ptn)then
            return INN
        end
    end

    return PUB
end


function _M.is_pub(ip)
    return _M.ip_class(ip) == PUB
end


function _M.is_inn(ip)
    return _M.ip_class(ip) == INN
end


function _M.choose(ips, clz)
    local rst = {}
    for _, ip in ipairs(ips) do
        if _M.ip_class(ip) == clz then
            table_insert(rst, ip)
        end
    end

    return rst
end


function _M.choose_pub(ips)
    return _M.choose(ips, PUB)
end


function _M.choose_inn(ips)
    return _M.choose(ips, INN)
end


function _M.ips_prefer(ips, clz)

    local pub_ips = _M.choose_pub(ips)
    local inn_ips = _M.choose_inn(ips)

    if clz == nil then
        clz = PUB
    end

    if clz == PUB then
        return tableutil_extends(pub_ips, inn_ips)
    else
        return tableutil_extends(inn_ips, pub_ips)
    end
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

local function unsign(binary)
    if binary < 0 then
        return signed_range + binary
    end
    return binary
end

function _M.ip_to_binary(ip)

    if _M.is_ip4(ip) == false then
        return nil
    end

    local elts = strutil.split(ip, '.', true)
    local ip_binary = 0

    for _, elt_str in ipairs(elts) do
        local elt = tonumber(elt_str)
        ip_binary = bit.bor(bit.lshift(ip_binary, 8), elt)
    end

    return unsign(ip_binary)
end

function _M.binary_to_ip(ip_binary)
    local ip = {}
    for i = 1, 4 do
        table.insert(ip, 1, tostring(bit.band(ip_binary, 255)))
        ip_binary = bit.rshift(ip_binary, 8)
    end
    return table.concat(ip, '.')
end

function _M.ip_in_cidr(ip, cidrs)

    for _, cidr in ipairs(cidrs) do

        local min, max = _M.parse_cidr(cidr)

        if min ~= nil then
            local binary_ip = _M.ip_to_binary(ip)
            if binary_ip ~= nil and binary_ip >= min and binary_ip <= max then
                return true
            end
        end
    end

    return false
end

function _M.parse_cidr(cidr)

    local net_mask = strutil.split(cidr, '/', 1)

    local net = net_mask[1]
    local mask = tonumber(net_mask[2]) or 32

    if _M.is_ip4(net) == false then
        return nil, 'invalid net', string.format('invalid net value: %s', net)
    end

    if mask > 32 or mask < 0 then
        return nil, 'invalid mask', string.format('invalid mask value: %s', mask)
    end

    local binary_mask = binary_masks[mask]
    local reverse_binary_mask = reverse_binary_masks[mask]
    local binary_net = _M.ip_to_binary(net)

    local min_binary_ip = unsign(bit.band(binary_net, binary_mask))
    local max_binary_ip = unsign(bit.bor(min_binary_ip, reverse_binary_mask))

    return min_binary_ip, max_binary_ip, unsign(binary_mask)
end

return _M
