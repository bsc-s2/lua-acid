local strutil = require('acid.strutil')
local ffi = require("ffi")

local _M = { _VERSION = '1.0' }

ffi.cdef[[
    typedef struct timeval{
        long int tv_sec;
        long int tv_usec;
    }timeval;

    int gettimeofday(struct timeval *tv, void *tz);
]]

local str_time = {
    isobase="(%d%d%d%d)(%d%d)(%d%d)T(%d%d)(%d%d)(%d%d)Z",
    iso="(%d+)%-(%d+)%-(%d+)T(%d+):(%d+):(%d+)%.(%d+)Z",
    utc="(%u%l%l)%,% (%d+)% (%u%l%l)% (%d+)% (%d+):(%d+):(%d+)% UTC",
    std="(%d+)%-(%d+)%-(%d+)% (%d+):(%d+):(%d+)",
    nginxaccesslog="(%d+)%/(%u%l%l)%/(%d+)%:(%d+):(%d+):(%d+)",
    nginxerrorlog ="(%d+)%/(%d+)%/(%d+)% (%d+):(%d+):(%d+)",
}

local time_str = {
    iso='%Y-%m-%dT%H:%M:%S.000Z',
    utc='%a, %d %b %Y %H:%M:%S UTC',
    std='%Y-%m-%d %H:%M:%S',
    nginxaccesslog='%d/%b/%Y:%H:%M:%S',
    nginxerrorlog ='%Y/%m/%d %H:%M:%S',
}

local month_num= {
    Jan='01', Feb='02', Mar='03', Apr='04', May='05', Jun='06',
    Jul='07', Aug='08', Sep='09', Oct='10', Nov='11', Dec='12',
}

local week_num= {
    Sun='0', Mon='1', Tue='2', Wed='3', Thu='4', Fri='5', Sat='6',
}

local time_withzone={
    isobase=true,
    iso=true,
    utc=true,
    std=false,
    nginxaccesslog=false,
    nginxerrorlog=false,
}

local ts_len_to_unit = {
    [10]='s',
    [13]='ms',
    [16]='us',
    [19]='ns',
}


-- local_time + timezone = utc_time
--Daylight Saving Time(DST)
--
--"!*t" convert time stamp to UTS time string.
--os.date() returns a time table with field isdst = false
--Thus this function returns the offset to timezone 0 without DST info
local function get_timezone()

    local local_time = os.time()
    local utc_time = os.time(os.date("!*t", local_time))
    return os.difftime(utc_time, local_time)
end
local timezone = get_timezone()


_M.timezone = timezone


local function _parse(dt, fmtkey, withzone)

    local ptn = str_time[fmtkey]

    local yy
    local mm
    local dd
    local h
    local m
    local s

    assert(type(dt) == 'string', 'date is not a string, type: ' .. type(dt))

    if fmtkey == 'utc' then
        local wk
        wk, dd, mm, yy, h, m, s = string.match(dt, ptn)
        if mm == nil or month_num[mm] == nil then
            return nil, 'FormatError',
                'date does not include month or month is wrong, ' .. dt
        else
            mm = month_num[mm]
        end

        if wk == nil or week_num[wk] == nil then
            return nil, 'FormatError',
                'date does not include week or week is wrong, ' .. dt
        end

    elseif fmtkey == 'nginxaccesslog' then
        dd, mm, yy, h, m, s = string.match(dt, ptn)
        if mm == nil or month_num[mm] == nil then
            return nil, 'FormatError',
                'date does not include month or month is wrong, ' .. dt
        else
            mm = month_num[mm]
        end
    else
        yy, mm, dd, h, m, s = string.match(dt, ptn)
    end

    if yy == nil then
        return nil, 'FormatError',
            'date format is wrong, ' .. dt
    end

    -- os.time convert local time to timestamp
    --timezone does not include DST info, thus we must not convert it as a DST time
    local ts = os.time({ year=yy, month=mm, day=dd, hour=h, min=m, sec=s, isdst=false })
    if withzone then
        ts = ts - timezone
    end

    return ts, nil, nil
end


local function _format(ts, fmtkey, withzone)

    local fmt = time_str[fmtkey]

    ts = tonumber(ts)
    if ts == nil then
        return nil, 'ArgumentError', 'timestamp cannot be converted to numbers'
    end

    if withzone then
        ts = ts + timezone
    end
    return os.date(fmt, ts), nil, nil
end


function _M.parse(dt, fmtkey, withzone)
    if fmtkey == nil or time_withzone[fmtkey] == nil then
        return nil, 'FormatKeyError', 'date cannot be formated into a timestamp'

    else
        return _parse( dt, fmtkey, withzone or time_withzone[fmtkey] )
    end
end


function _M.format(ts, fmtkey, withzone)
    if fmtkey == nil or time_withzone[fmtkey] == nil then
        return nil, 'FormatKeyError', 'timestamp cannot be converted to a date'

    else
        return _format( ts, fmtkey, withzone or time_withzone[fmtkey] )
    end
end


local function get_timestamp(ts)

    --if 'number' is greater than 1 * 10^15, 'number' will be scientific notation
    --timestamp can only be a string of numbers or a non scientific notation of numbers

    local num_ts = tonumber(ts)

    if num_ts == nil then
        return nil, 'NotNumber',
            'timestamp can not be converted to number, ts:' .. tostring(ts)
    end

    if num_ts < 0 then
        return nil, 'NotPositive',
            'timestamp can not be a negative number. ts:' .. tostring(ts)
    end

    local str_ts = tostring(ts)

    if string.find(str_ts, '[e]') ~= nil then
        return nil, 'ScientificNotationNotAllowed',
            'timestamp cannot be scientific notation, ts:' .. tostring(ts)
    end

    local tsparts = strutil.split(str_ts, '[.]')
    local intger = tsparts[1]
    local float = tsparts[2] or ''

    if ts_len_to_unit[#intger] then
        return intger .. float
    else
        return nil, 'InvalidLength',
            'invalid time length, not 10, 13, 16 or 19, ts:' .. tostring(ts)
    end
end


local function ts_conversion(ts, len)

    local origin_ts, err, errmsg = get_timestamp(ts)
    if not origin_ts then
        return nil, err, errmsg
    end

    local extended_ts = strutil.ljust(origin_ts, len, '0')
    return string.sub(extended_ts, 1, len)
end


function _M.to_sec(ts)

    --Convert millisecond, microsecond or nanosecond to second
    local ts_sec, err, errmsg = ts_conversion(ts, 10)
    if err ~= nil then
        return nil, err, errmsg
    end
    return tonumber(ts_sec)
end


function _M.to_ms(ts)

    --Convert a timestamp to millisecond
    local ts_ms, err, errmsg = ts_conversion(ts, 13)
    if err ~= nil then
        return nil, err, errmsg
    end
    return tonumber(ts_ms)
end


function _M.to_str_us(ts)

    --Convert a timestamp to microsecond
    return ts_conversion(ts, 16)
end


function _M.to_str_ns(ts)

    --Convert a timestamp to nanosecond
    return ts_conversion(ts, 19)
end


function _M.get_time()
    local tv = ffi.new("timeval")
    ffi.C.gettimeofday(tv, ffi.NULL)

    local s = tonumber(tv.tv_sec)
    local us = tonumber(tv.tv_usec)
    local ms = math.floor(us / 1000)

    return { seconds      = s,
             milliseconds = ms,
             microseconds = us }
end


function _M.get_sec()
    local time = _M.get_time()
    return time.seconds
end


function _M.get_ms()
    local time = _M.get_time()
    return time.seconds * 1000 + time.milliseconds
end


function _M.get_str_us()
    local time = _M.get_time()
    return string.format("%10d%06d", time.seconds, time.microseconds)
end

return _M
