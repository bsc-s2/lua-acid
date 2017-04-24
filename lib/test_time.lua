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

    t:eq( utc_time, local_time+timezone, 'timezone is wrong, timezone:'..timezone )
end

function test.to_sec(t)
    local tosec = time.to_sec

    local sec = 1492398063
    local msg = 'ts_to_sec is wrong,sec:'..sec..'ts:'

    t:eq( sec, tosec('1492398063'), msg..'1492398063' )
    t:eq( sec, tosec('1492398063001'), msg..'1492398063001' )
    t:eq( sec, tosec('1492398063001010'), msg..'1492398063001010' )
    t:eq( sec, tosec('1492398063001010100'), msg..'1492398063001010100' )

    local ts, err, err_msg = tosec('149')
    t:eq( err, 'ArgumentError', err_msg )
end
