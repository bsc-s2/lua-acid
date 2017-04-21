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

local function _parse( dt, fmtkey, withzone )

    local ptn = str2time[ fmtkey ]

    local yy, mm, dd, h, m, s
    local err = 'FormatError'
    local msg

    if type( dt ) ~= 'string' then
        return nil, err, 'type: ' .. type( dt ) .. ' date format error'
    end

    local msg = dt .. ' date format error'

    if fmtkey == 'utc' then
        local wk
        wk, dd, mm, yy, h, m, s = string.match( dt, ptn )
        if mm == nil or month2num[ mm ] == nil then
            return nil, err, msg
        else
            mm = month2num[ mm ]
        end

        if wk == nil or week2num[ wk ] == nil then
            return nil, err, msg
        end

    elseif fmtkey == 'ngxaccesslog' then
        dd, mm, yy, h, m, s = string.match( dt, ptn )
        if mm == nil or month2num[ mm ] == nil then
            return nil, err, msg
        else
            mm = month2num[ mm ]
        end
    else
        yy, mm, dd, h, m, s = string.match( dt, ptn )
    end

    if yy == nil then
        return nil, err, msg
    end

    -- os.time convert local time to timestamp
    local ts = os.time({ year=yy, month=mm, day=dd, hour=h, min=m, sec=s })
    if withzone then
        ts = ts - timezone
    end

    return ts, nil, nil
end

local function _format( ts, fmtkey, withzone )

    local fmt = time2str[ fmtkey ]

    local ts = tonumber( ts )
    if ts == nil then
        return nil, 'ValueError', 'timestamp cannot tonumber'
    end

    if withzone then
        ts = ts + timezone
    end
    return os.date( fmt, ts ), nil, nil
end

function _M.parse_isobase( dt, withzone )
    return _parse( dt, 'isobase', withzone or true )
end

function _M.parse_iso( dt, withzone )
    return _parse( dt, 'iso', withzone or true )
end

function _M.parse_utc( dt, withzone )
    return _parse( dt, 'utc', withzone or true )
end

function _M.parse_std( dt, withzone )
    return _parse( dt, 'std', withzone or false )
end

function _M.parse_ngxaccesslog( dt, withzone )
    return _parse( dt, 'ngxaccesslog', withzone or false )
end

function _M.parse_ngxerrorlog( dt, withzone )
    return _parse( dt, 'ngxerrorlog', withzone or false )
end


function _M.format_iso( ts, withzone )
    return _format( ts, 'iso', withzone or true )
end

function _M.format_utc( ts, withzone )
    return _format( ts, 'utc', withzone or true )
end

function _M.format_std( ts, withzone )
    return _format(ts, 'std', withzone or false )
end

function _M.format_ngxaccesslog( ts, withzone )
    return _format( ts, 'ngxaccesslog', withzone or false )
end

function _M.format_ngxerrorlog( ts, withzone )
    return _format( ts, 'ngxerrorlog', withzone or false )
end


function _M.ts_to_sec(ts)

    --Convert millisecond, microsecond or nanosecond to second

    if #ts == 10 then
        ts = ts
    elseif #ts == 13 then
        ts = ts:sub(1, -3 - 1)
    elseif #ts == 16 then
        ts = ts:sub(1, -6 - 1)
    elseif #ts == 19 then
        ts = ts:sub(1, -9 - 1)
    else
        return nil, 'ValueError', 'invalid time length, not 10, 13, 16 or 19, ts:' .. ts
    end

    ts = tonumber(ts)
    if ts == nil then
        return nil, 'ValueError', 'timestamp cannot tonumber'
    end

    return ts
end

return _M
