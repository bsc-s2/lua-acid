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
        -- func, input, out, err, msg
        {
            func=time.parse_isobase,
            input='20170414T105302Z',
            out=1492167182
        },
        {
            func=time.parse_iso,
            input='2015-06-21T04:33:42.000Z',
            out=1434861222
        },
        {
            func=time.parse_utc,
            input='Sun, 21 Jun 2015 04:33:42 UTC',
            out=1434861222
        },
        {
            func=time.parse_std,
            input='2015-06-21 12:33:42',
            out=1434861222
        },
        {
            func=time.parse_ngxaccesslog,
            input='21/Jun/2015:12:33:42',
            out=1434861222
        },
        {
            func=time.parse_ngxerrorlog,
            input='2015/06/21 12:33:42',
            out=1434861222
        },

        {
            func=time.parse_utc,
            input='Tun, 21 Jun 2015 04:33:42 UTC',
            out=nil,
            err='FormatError',
            msg='Tun, 21 Jun 2015 04:33:42 UTC date format error'
        },
        {
            func=time.parse_utc,
            input='un, 21 Jun 2015 04:33:42 UTC',
            out=nil,
            err='FormatError',
            msg='un, 21 Jun 2015 04:33:42 UTC date format error'
        },
        {
            func=time.parse_utc,
            input=' 21 Jun 2015 04:33:42 UTC',
            out=nil,
            err='FormatError',
            msg=' 21 Jun 2015 04:33:42 UTC date format error'
        },
        {
            func=time.parse_utc,
            input='Sun, 21 Jux 2015 04:33:42 UTC',
            out=nil,
            err='FormatError',
            msg='Sun, 21 Jux 2015 04:33:42 UTC date format error'
        },
        {
            func=time.parse_utc,
            input='Sun, 21 Jun 2015 04:33:42',
            out=nil,
            err='FormatError',
            msg='Sun, 21 Jun 2015 04:33:42 date format error'
        },

        {
            func=time.parse_std,
            input='2015-06-21 12:u:42',
            out=nil,
            err='FormatError',
            msg='2015-06-21 12:u:42 date format error'
        },
        {
            func=time.parse_std,
            input='2015-06-21 12:33:',
            out=nil,
            err='FormatError',
            msg='2015-06-21 12:33: date format error'
        },
        {
            func=time.parse_std,
            input=nil,
            out=nil,
            err='FormatError',
            msg='type: nil date format error'
        },
        {
            func=time.parse_std,
            input={},
            out=nil,
            err='FormatError',
            msg='type: table date format error'
        },
        {
            func=time.parse_std,
            input=true,
            out=nil,
            err='FormatError',
            msg='type: boolean date format error'
        },
        {
            func=time.parse_std,
            input=10,
            out=nil,
            err='FormatError',
            msg='type: number date format error'
        },

    }

    for i, case in ipairs( cases ) do
        local out, err, msg = case.func(case.input)

        t:eq( case.out, out )

        if(err ~= nil) then
            t:eq( case.err, err )
            t:eq( case.msg, msg )
        end
    end
end

function test.format(t)
    local cases={
        {
            func=time.format_iso,
            input=1434861222,
            out='2015-06-21T04:33:42.000Z'
        },
        {
            func=time.format_utc,
            input=1434861222,
            out='Sun, 21 Jun 2015 04:33:42 UTC'
        },
        {
            func=time.format_std,
            input=1434861222,
            out='2015-06-21 12:33:42'
        },
        {
            func=time.format_ngxaccesslog,
            input=1434861222,
            out='21/Jun/2015:12:33:42'
        },
        {
            func=time.format_ngxerrorlog,
            input=1434861222,
            out='2015/06/21 12:33:42'
        },

        {
            func=time.format_std,
            input=nil,
            out=nil,
            err='ArgumentError',
            msg='timestamp cannot tonumber'
        },
        {
            func=time.format_std,
            input={},
            out=nil,
            err='ArgumentError',
            msg='timestamp cannot tonumber'
        },
        {
            func=time.format_std,
            input=':',
            out=nil,
            err='ArgumentError',
            msg='timestamp cannot tonumber'
        },
        {
            func=time.format_std,
            input='XxX',
            out=nil,
            err='ArgumentError',
            msg='timestamp cannot tonumber'
        },
    }

    for i, case in ipairs( cases ) do
        local out, err, msg = case.func(case.input)

        t:eq( case.out, out )

        if(err ~= nil) then
            t:eq( case.err, err )
            t:eq( case.msg, msg )
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
            input = '1492398063',
            out = 1492398063,
            err = nil
        },
        {
            input = '1492398063123',
            out = 1492398063,
            err = nil
        },
        {
            input = '1492398063123456',
            out = 1492398063,
            err = nil
        },
        {
            input = '1492398063123456789',
            out = 1492398063,
            err = nil
        },
        {
            input = '1492398063aaa',
            out = nil,
            err = 'ArgumentError'
        },
        {
            input = '-123456789',
            out = nil,
            err = 'ArgumentError'
        },
        {
            input = '123',
            out = nil,
            err = 'ArgumentError'
        },
        {
            input = '12345678901234567890',
            out = nil,
            err = 'ArgumentError'
        },

        {
            input = 1000000000,
            out = 1000000000,
            err = nil,
        },
        {
            input = 9999999997,
            out = 9999999997,
            err = nil
        },
        {
            input = 9999999999,
            out = 9999999999,
            err = nil,
        },
        {
            input = 1000000000000,
            out = 1000000000,
            err = nil,
        },
        {
            input = 9999999999998,
            out = 9999999999,
            err = nil,
        },
        {
            input = 9999999999999,
            out = 9999999999,
            err = nil,
        },
        {
            input = 1492398063,
            out = 1492398063,
            err = nil
        },
        {
            input = 1492398063123,
            out = 1492398063,
            err = nil
        },
        {
            input = -123456789,
            out = nil,
            err = 'ArgumentError'
        },
        {
            input = 1234,
            out = nil,
            err = 'ArgumentError'
        },
        {
            input = 1.1234e+15,
            out = nil,
            err = 'ArgumentError'
        },
        {
            input = 1492398063123456,
            out = nil,
            err = 'ArgumentError'
        },

        {
            input = {},
            out = nil,
            err = 'ArgumentError'
        },
        {
            input = true,
            out = nil,
            err = 'ArgumentError'
        },
        {
            input = nil,
            out = nil,
            err = 'ArgumentError'
        },
    }

    for i, case in pairs(cases) do
        local ts, err, err_msg = time.to_sec(case.input)

        t:eq( case.out, ts)
        t:eq( case.err, err, err_msg )
    end
end
