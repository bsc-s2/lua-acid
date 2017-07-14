local _M = { _VERSION = '1.0' }

local str2time = {
    isobase="(%d%d%d%d)(%d%d)(%d%d)T(%d%d)(%d%d)(%d%d)Z",
    iso="(%d+)%-(%d+)%-(%d+)T(%d+):(%d+):(%d+)%.(%d+)Z",
    utc="(%u%l%l)%,% (%d+)% (%u%l%l)% (%d+)% (%d+):(%d+):(%d+)% UTC",
    std="(%d+)%-(%d+)%-(%d+)% (%d+):(%d+):(%d+)",
    ngxaccesslog="(%d+)%/(%u%l%l)%/(%d+)%:(%d+):(%d+):(%d+)",
    ngxerrorlog ="(%d+)%/(%d+)%/(%d+)% (%d+):(%d+):(%d+)",
}

local time2str = {
    iso='%Y-%m-%dT%H:%M:%S.000Z',
    utc='%a, %d %b %Y %H:%M:%S UTC',
    std='%Y-%m-%d %H:%M:%S',
    ngxaccesslog='%d/%b/%Y:%H:%M:%S',
    ngxerrorlog ='%Y/%m/%d %H:%M:%S',
}

local month2num= {
    Jan='01', Feb='02', Mar='03', Apr='04', May='05', Jun='06',
    Jul='07', Aug='08', Sep='09', Oct='10', Nov='11', Dec='12',
}

local week2num= {
    Sun='0', Mon='1', Tue='2', Wed='3', Thu='4', Fri='5', Sat='6',
}


-- local_time + timezone = utc_time
local function get_timezone()

    local local_time = os.time()
    local utc_time = os.time(os.date("!*t", local_time))
    return os.difftime(utc_time, local_time)
end
local timezone = get_timezone()


_M.timezone = timezone


local function _parse(dt, fmtkey, withzone)

    local ptn = str2time[fmtkey]

    local yy
    local mm
    local dd
    local h
    local m
    local s

    if type(dt) ~= 'string' then
        return nil, 'FormatError', 'type: ' .. type(dt) .. ' date format error'
    end

    if fmtkey == 'utc' then
        local wk
        wk, dd, mm, yy, h, m, s = string.match(dt, ptn)
        if mm == nil or month2num[mm] == nil then
            return nil, 'FormatError', dt .. ' date format error'
        else
            mm = month2num[mm]
        end

        if wk == nil or week2num[wk] == nil then
            return nil, 'FormatError', dt .. ' date format error'
        end

    elseif fmtkey == 'ngxaccesslog' then
        dd, mm, yy, h, m, s = string.match(dt, ptn)
        if mm == nil or month2num[mm] == nil then
            return nil, 'FormatError', dt .. ' date dormat error'
        else
            mm = month2num[mm]
        end
    else
        yy, mm, dd, h, m, s = string.match(dt, ptn)
    end

    if yy == nil then
        return nil, 'FormatError', dt .. ' date format error'
    end

    -- os.time convert local time to timestamp
    local ts = os.time({ year=yy, month=mm, day=dd, hour=h, min=m, sec=s })
    if withzone then
        ts = ts - timezone
    end

    return ts, nil, nil
end


local function _format(ts, fmtkey, withzone)

    local fmt = time2str[fmtkey]

    local ts = tonumber(ts)
    if ts == nil then
        return nil, 'ArgumentError', 'timestamp cannot tonumber'
    end

    if withzone then
        ts = ts + timezone
    end
    return os.date(fmt, ts), nil, nil
end


local function default_true(withzone)
    if withzone == nil then
        withzone = true
    end

    return withzone
end


local function default_false(withzone)
    if withzone == nil then
        withzone = false
    end

    return withzone
end


function _M.parse_isobase(dt, withzone)
    withzone = default_true(withzone)

    return _parse( dt, 'isobase', withzone )
end


function _M.parse_iso(dt, withzone)
    withzone = default_true(withzone)

    return _parse( dt, 'iso', withzone )
end


function _M.parse_utc(dt, withzone)
    withzone = default_true(withzone)

    return _parse( dt, 'utc', withzone )
end


function _M.parse_std(dt, withzone)
    withzone = default_false(withzone)

    return _parse( dt, 'std', withzone )
end


function _M.parse_ngxaccesslog(dt, withzone)
    withzone = default_false(withzone)

    return _parse( dt, 'ngxaccesslog', withzone )
end


function _M.parse_ngxerrorlog(dt, withzone)
    withzone = default_false(withzone)

    return _parse( dt, 'ngxerrorlog', withzone )
end


function _M.format_iso(ts, withzone)
    withzone = default_true(withzone)

    return _format( ts, 'iso', withzone )
end


function _M.format_utc(ts, withzone)
    withzone = default_true(withzone)

    return _format( ts, 'utc', withzone )
end


function _M.format_std(ts, withzone)
    withzone = default_false(withzone)

    return _format( ts, 'std', withzone )
end


function _M.format_ngxaccesslog(ts, withzone)
    withzone = default_false(withzone)

    return _format( ts, 'ngxaccesslog', withzone )
end


function _M.format_ngxerrorlog(ts, withzone)
    withzone = default_false(withzone)

    return _format( ts, 'ngxerrorlog', withzone )
end


function _M.to_sec(ts)

    --Convert millisecond, microsecond or nanosecond to second

    --if 'number' is greater than 1 * 10^15, 'number' will be scientific notation
    --timestamp can only be a string of numbers or not a scientific notation of numbers

    if tonumber(ts) == nil or tonumber(ts) < 0 then
        return nil, 'ArgumentError',
            'timestamp cannot be converted to number or less than 0, ts:' .. ts
    end

    ts = tostring(ts)

    if string.find(ts, '[e.]') ~= nil then
        return nil, 'ArgunmentError',
            'timestamp cannot be scientific notation or decimal, ts:' .. ts
    end

    if #ts == 10 then
        ts = ts
    elseif #ts == 13 then
        ts = ts:sub(1, -4)
    elseif #ts == 16 then
        ts = ts:sub(1, -7)
    elseif #ts == 19 then
        ts = ts:sub(1, -10)
    else
        return nil, 'ArgumentError',
            'invalid time length, not 10, 13, 16 or 19, ts:' .. ts
    end

    return tonumber(ts)
end


return _M
