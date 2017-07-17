local time = require("acid.time")

function test.iso(t)
    local p = time.parse_iso
    local f = time.format_iso

    local date = '2015-04-06T21:26:32.000Z'
    local ts = 1428355592

    t:eq( ts, p(date), 'timezone 0: ' .. (ts - p(date)) )
    t:eq( date, f(p(date)), 'timezone 0: ' .. date .. ' ' .. f(p(date)) )
end

function test.parse(t)
    local cases = {
        -- func, args, res, err, errmes
        {
            func=time.parse_isobase,
            args='20170414T105302Z',
            res=1492167182
        },
        {
            func=time.parse_iso,
            args='2015-06-21T04:33:42.000Z',
            res=1434861222
        },
        {
            func=time.parse_utc,
            args='Sun, 21 Jun 2015 04:33:42 UTC',
            res=1434861222
        },
        {
            func=time.parse_std,
            args='2015-06-21 12:33:42',
            res=1434861222
        },
        {
            func=time.parse_ngxaccesslog,
            args='21/Jun/2015:12:33:42',
            res=1434861222
        },
        {
            func=time.parse_ngxerrorlog,
            args='2015/06/21 12:33:42',
            res=1434861222
        },

        {
            func=time.parse_utc,
            args='Tun, 21 Jun 2015 04:33:42 UTC',
            res=nil,
            err='FormatError',
            errmes='Tun, 21 Jun 2015 04:33:42 UTC date format error'
        },
        {
            func=time.parse_utc,
            args='un, 21 Jun 2015 04:33:42 UTC',
            res=nil,
            err='FormatError',
            errmes='un, 21 Jun 2015 04:33:42 UTC date format error'
        },
        {
            func=time.parse_utc,
            args=' 21 Jun 2015 04:33:42 UTC',
            res=nil,
            err='FormatError',
            errmes=' 21 Jun 2015 04:33:42 UTC date format error'
        },
        {
            func=time.parse_utc,
            args='Sun, 21 Jux 2015 04:33:42 UTC',
            res=nil,
            err='FormatError',
            errmes='Sun, 21 Jux 2015 04:33:42 UTC date format error'
        },
        {
            func=time.parse_utc,
            args='Sun, 21 Jun 2015 04:33:42',
            res=nil,
            err='FormatError',
            errmes='Sun, 21 Jun 2015 04:33:42 date format error'
        },

        {
            func=time.parse_std,
            args='2015-06-21 12:u:42',
            res=nil,
            err='FormatError',
            errmes='2015-06-21 12:u:42 date format error'
        },
        {
            func=time.parse_std,
            args='2015-06-21 12:33:',
            res=nil,
            err='FormatError',
            errmes='2015-06-21 12:33: date format error'
        },
        {
            func=time.parse_std,
            args=nil,
            res=nil,
            err='FormatError',
            errmes='type: nil date format error'
        },
        {
            func=time.parse_std,
            args={},
            res=nil,
            err='FormatError',
            errmes='type: table date format error'
        },
        {
            func=time.parse_std,
            args=true,
            res=nil,
            err='FormatError',
            errmes='type: boolean date format error'
        },
        {
            func=time.parse_std,
            args=10,
            res=nil,
            err='FormatError',
            errmes='type: number date format error'
        },

    }

    for i, case in ipairs( cases ) do
        local res, err, errmes = case.func(case.args)

        t:eq( case.res, res )

        if(err ~= nil) then
            t:eq( case.err, err )
            t:eq( case.errmes, errmes )
        end
    end
end

function test.format(t)
    local cases={
        {
            func=time.format_iso,
            args=1434861222,
            res='2015-06-21T04:33:42.000Z'
        },
        {
            func=time.format_utc,
            args=1434861222,
            res='Sun, 21 Jun 2015 04:33:42 UTC'
        },
        {
            func=time.format_std,
            args=1434861222,
            res='2015-06-21 12:33:42'
        },
        {
            func=time.format_ngxaccesslog,
            args=1434861222,
            res='21/Jun/2015:12:33:42'
        },
        {
            func=time.format_ngxerrorlog,
            args=1434861222,
            res='2015/06/21 12:33:42'
        },

        {
            func=time.format_std,
            args=nil,
            res=nil,
            err='ArgumentError',
            errmes='timestamp cannot tonumber'
        },
        {
            func=time.format_std,
            args={},
            res=nil,
            err='ArgumentError',
            errmes='timestamp cannot tonumber'
        },
        {
            func=time.format_std,
            args=':',
            res=nil,
            err='ArgumentError',
            errmes='timestamp cannot tonumber'
        },
        {
            func=time.format_std,
            args='XxX',
            res=nil,
            err='ArgumentError',
            errmes='timestamp cannot tonumber'
        },
    }

    for i, case in ipairs( cases ) do
        local res, err, errmes = case.func(case.args)

        t:eq( case.res, res )

        if(err ~= nil) then
            t:eq( case.err, err )
            t:eq( case.errmes, errmes )
        end
    end
end

function test.timezone(t)
    local local_time = os.time()
    local utc_time = os.time(os.date("!*t", local_time))

    local timezone = time.timezone

    t:eq( utc_time, local_time+timezone, 'timezone is wrong, timezone:' .. timezone )
end

function test.to_sec(t)
    local cases = {
        {
            args='1499850242',
            res=1499850242
        },
        {
            args='1499850242000',
            res=1499850242
        },
        {
            args='1499850242000000',
            res=1499850242
        },
        {
            args='1499850242000000000',
            res=1499850242
        },
        {
            args='abc1499850242',
            res=nil,
            err='ArgumentError',
            errmes='timestamp cannot be converted to number or less than 0, ts:abc1499850242'
        },
        {
            args='1499850242abc',
            res=nil,
            err='ArgumentError',
            errmes='timestamp cannot be converted to number or less than 0, ts:1499850242abc'
        },
        {
            args='-1499850242',
            res=nil,
            err='ArgumentError',
            errmes='timestamp cannot be converted to number or less than 0, ts:-1499850242'
        },
        {
            args='1e10',
            res=nil,
            err='ArgumentError',
            errmes='timestamp cannot be scientific notation or decimal, ts:1e10'
        },
        {
            args='1499850242.1',
            res=nil,
            err='ArgumentError',
            errmes='timestamp cannot be scientific notation or decimal, ts:1499850242.1'
        },
        {
            args='12345',
            res=nil,
            err='ArgumentError',
            errmes='invalid time length, not 10, 13, 16 or 19, ts:12345'
        },

        {
            args=1499850242,
            res=1499850242
        },
        {
            args=1499850242001,
            res=1499850242
        },
        {
            args=1499850242001002,
            res=nil,
            err='ArgumentError',
            errmes='timestamp cannot be scientific notation or decimal, ts:1.499850242001e+15'
        },
        {
            args=1499850242001002003,
            res=nil,
            err='ArgumentError',
            errmes='timestamp cannot be scientific notation or decimal, ts:1.499850242001e+18'
        },
        {
            args=1e15,
            res=nil,
            err='ArgumentError',
            errmes='timestamp cannot be scientific notation or decimal, ts:1e+15'
        },
        {
            args=-1499850242,
            res=nil,
            err='ArgumentError',
            errmes='timestamp cannot be converted to number or less than 0, ts:-1499850242'
        },
        {
            args=1499850242.123,
            res=nil,
            err='ArgumentError',
            errmes='timestamp cannot be scientific notation or decimal, ts:1499850242.123'
        },

        {
            args=nil,
            res=nil,
            err='ArgumentError',
            errmes='timestamp cannot be converted to number or less than 0, ts:nil'
        },
        {
            args=true,
            res=nil,
            err='ArgumentError',
            errmes='timestamp cannot be converted to number or less than 0, ts:true'
        },
    }

    for i, case in pairs(cases) do
        local ts, err, errmes = time.to_sec(case.args)

        t:eq( case.res, ts)

        if err ~= nil then
            t:eq( case.err, err )
            t:eq( case.errmes, errmes )
        end
    end
end
