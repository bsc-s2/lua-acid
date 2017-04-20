local time = require("acid.time")

function test.iso(t)
    local p = time.parse.iso
    local f = time.format.iso

    local date = '2015-04-06T21:26:32.000Z'
    local ts = 1428355592

    t:eq(ts, p(date), 'timezone 0: ' .. ts - p(date))
    t:eq(date, f(p(date)), 'timezone 0: ' .. date .. ' ' .. f(p(date)))
end

function test.parse(t)
    local cases = {
        -- func, input, out, err, msg
        {
            func=time.parse.isobase,
            input='20170414T105302Z',
            out=1492167182
        },
        {
            func=time.parse.iso,
            input='2015-06-21T04:33:42.000Z',
            out=1434861222
        },
        {
            func=time.parse.utc,
            input='Sun, 21 Jun 2015 04:33:42 UTC',
            out=1434861222
        },
        {
            func=time.parse.std,
            input='2015-06-21 12:33:42',
            out=1434861222
        },
        {
            func=time.parse.ngxaccesslog,
            input='21/Jun/2015:12:33:42',
            out=1434861222
        },
        {
            func=time.parse.ngxerrorlog,
            input='2015/06/21 12:33:42',
            out=1434861222
        },

        {
            func=time.parse.utc,
            input='Tun, 21 Jun 2015 04:33:42 UTC',
            out=nil,
            err='FormatError',
            msg='Tun, 21 Jun 2015 04:33:42 UTC date format error'
        },
        {
            func=time.parse.utc,
            input='un, 21 Jun 2015 04:33:42 UTC',
            out=nil,
            err='FormatError',
            msg='un, 21 Jun 2015 04:33:42 UTC date format error'
        },
        {
            func=time.parse.utc,
            input=' 21 Jun 2015 04:33:42 UTC',
            out=nil,
            err='FormatError',
            msg=' 21 Jun 2015 04:33:42 UTC date format error'
        },
        {
            func=time.parse.utc,
            input='Sun, 21 Jux 2015 04:33:42 UTC',
            out=nil,
            err='FormatError',
            msg='Sun, 21 Jux 2015 04:33:42 UTC date format error'
        },
        {
            func=time.parse.utc,
            input='Sun, 21 Jun 2015 04:33:42',
            out=nil,
            err='FormatError',
            msg='Sun, 21 Jun 2015 04:33:42 date format error'
        },

        {
            func=time.parse.std,
            input='2015-06-21 12:u:42',
            out=nil,
            err='FormatError',
            msg='2015-06-21 12:u:42 date format error'
        },
        {
            func=time.parse.std,
            input='2015-06-21 12:33:',
            out=nil,
            err='FormatError',
            msg='2015-06-21 12:33: date format error'
        },
        {
            func=time.parse.std,
            input=nil,
            out=nil,
            err='FormatError',
            msg='type: nil date format error'
        },
        {
            func=time.parse.std,
            input={},
            out=nil,
            err='FormatError',
            msg='type: table date format error'
        },
        {
            func=time.parse.std,
            input=true,
            out=nil,
            err='FormatError',
            msg='type: boolean date format error'
        },
        {
            func=time.parse.std,
            input=10,
            out=nil,
            err='FormatError',
            msg='type: number date format error'
        },

    }

    for i, case in ipairs( cases ) do
        local out, err, msg = case.func(case.input)

        t:eq(out, case.out)

        if(err ~= nil) then
            t:eq(err, case.err)
            t:eq(msg, case.msg)
        end
    end
end

function test.format(t)
    local cases={
        {
            func=time.format.iso,
            input=1434861222,
            out='2015-06-21T04:33:42.000Z'
        },
        {
            func=time.format.utc,
            input=1434861222,
            out='Sun, 21 Jun 2015 04:33:42 UTC'
        },
        {
            func=time.format.std,
            input=1434861222,
            out='2015-06-21 12:33:42'
        },
        {
            func=time.format.ngxaccesslog,
            input=1434861222,
            out='21/Jun/2015:12:33:42'
        },
        {
            func=time.format.ngxerrorlog,
            input=1434861222,
            out='2015/06/21 12:33:42'
        },

        {
            func=time.format.std,
            input=nil,
            out=nil,
            err='ValueError',
            msg='timestamp cannot tonumber'
        },
        {
            func=time.format.std,
            input={},
            out=nil,
            err='ValueError',
            msg='timestamp cannot tonumber'
        },
        {
            func=time.format.std,
            input=':',
            out=nil,
            err='ValueError',
            msg='timestamp cannot tonumber'
        },
        {
            func=time.format.std,
            input='XxX',
            out=nil,
            err='ValueError',
            msg='timestamp cannot tonumber'
        },
    }

    for i, case in ipairs( cases ) do
        local out, err, msg = case.func(case.input)

        t:eq(out, case.out)

        if(err ~= nil) then
            t:eq(err, case.err)
            t:eq(msg, case.msg)
        end
    end
end

function test.timezone(t)
    local local_time = os.time()
    local utc_time = os.time(os.date("!*t", local_time))

    local timezone = time.timezone

    t:eq(local_time+timezone, utc_time, 'timezone is wrong, timezone:'..timezone)
end

function test.ts_to_sec(t)
    local ts = '1492398063010001'
    local sec = 1492398063

    t:eq(sec, time.ts_to_sec(ts), 'ts_to_sec is wrong,ts:'..ts..'sec:'..sec)
end
