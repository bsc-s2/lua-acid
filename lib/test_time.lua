local time = require("acid.time")

local dd = test.dd


function test.parse(t)
    local cases = {
        -- fmtkey, args, expected, err, err_msg
        {
            fmtkey='isobase',
            args='20170414T105302Z',
            expected=1492167182
        },
        {
            fmtkey='iso',
            args='2015-06-21T04:33:42.000Z',
            expected=1434861222
        },
        {
            fmtkey='utc',
            args='Sun, 21 Jun 2015 04:33:42 UTC',
            expected=1434861222
        },
        {
            fmtkey='std',
            args='2015-06-21 12:33:42',
            expected=1434861222
        },
        {
            fmtkey='ngxaccesslog',
            args='21/Jun/2015:12:33:42',
            expected=1434861222
        },
        {
            fmtkey='ngxerrorlog',
            args='2015/06/21 12:33:42',
            expected=1434861222
        },

        {
            fmtkey='utc',
            args='Tun, 21 Jun 2015 04:33:42 UTC',
            expected=nil,
            err='FormatError',
            err_msg='Tun, 21 Jun 2015 04:33:42 UTC date format error'
        },
        {
            fmtkey='utc',
            args='un, 21 Jun 2015 04:33:42 UTC',
            expected=nil,
            err='FormatError',
            err_msg='un, 21 Jun 2015 04:33:42 UTC date format error'
        },
        {
            fmtkey='utc',
            args=' 21 Jun 2015 04:33:42 UTC',
            expected=nil,
            err='FormatError',
            err_msg=' 21 Jun 2015 04:33:42 UTC date format error'
        },
        {
            fmtkey='utc',
            args='Sun, 21 Jux 2015 04:33:42 UTC',
            expected=nil,
            err='FormatError',
            err_msg='Sun, 21 Jux 2015 04:33:42 UTC date format error'
        },
        {
            fmtkey='utc',
            args='Sun, 21 Jun 2015 04:33:42',
            expected=nil,
            err='FormatError',
            err_msg='Sun, 21 Jun 2015 04:33:42 date format error'
        },

        {
            fmtkey='std',
            args='2015-06-21 12:u:42',
            expected=nil,
            err='FormatError',
            err_msg='2015-06-21 12:u:42 date format error'
        },
        {
            fmtkey='std',
            args='2015-06-21 12:33:',
            expected=nil,
            err='FormatError',
            err_msg='2015-06-21 12:33: date format error'
        },

    }

    for i, case in ipairs( cases ) do
        local res, err, err_msg = time.parse( case.args, case.fmtkey )

        dd( case.args, case.expected )
        t:eq( case.expected, res )

        if(err ~= nil) then
            t:eq( case.err, err )
            t:eq( case.err_msg, err_msg )
        end
    end
end

function test.format(t)
    local cases={
        {
            fmtkey='iso',
            args=1434861222,
            expected='2015-06-21T04:33:42.000Z'
        },
        {
            fmtkey='utc',
            args=1434861222,
            expected='Sun, 21 Jun 2015 04:33:42 UTC'
        },
        {
            fmtkey='std',
            args=1434861222,
            expected='2015-06-21 12:33:42'
        },
        {
            fmtkey='ngxaccesslog',
            args=1434861222,
            expected='21/Jun/2015:12:33:42'
        },
        {
            fmtkey='ngxerrorlog',
            args=1434861222,
            expected='2015/06/21 12:33:42'
        },

        {
            fmtkey='std',
            args=nil,
            expected=nil,
            err='ArgumentError',
            err_msg='timestamp cannot tonumber'
        },
        {
            fmtkey='std',
            args={},
            expected=nil,
            err='ArgumentError',
            err_msg='timestamp cannot tonumber'
        },
        {
            fmtkey='std',
            args=':',
            expected=nil,
            err='ArgumentError',
            err_msg='timestamp cannot tonumber'
        },
        {
            fmtkey='std',
            args='XxX',
            expected=nil,
            err='ArgumentError',
            err_msg='timestamp cannot tonumber'
        },
    }

    for i, case in ipairs( cases ) do
        local res, err, err_msg = time.format( case.args, case.fmtkey )

        dd( case.args, case.expected )
        t:eq( case.expected, res )

        if(err ~= nil) then
            t:eq( case.err, err )
            t:eq( case.err_msg, err_msg )
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
            expected=1499850242
        },
        {
            args='1499850242' .. '000',
            expected=1499850242
        },
        {
            args='1499850242' .. '000' .. '000',
            expected=1499850242
        },
        {
            args='1499850242' .. '000' .. '000' .. '000',
            expected=1499850242
        },
        {
            args='abc1499850242',
            expected=nil,
            err='ArgumentError',
            err_msg='timestamp cannot be converted to number or less than 0, ts:abc1499850242'
        },
        {
            args='1499850242abc',
            expected=nil,
            err='ArgumentError',
            err_msg='timestamp cannot be converted to number or less than 0, ts:1499850242abc'
        },
        {
            args='-1499850242',
            expected=nil,
            err='ArgumentError',
            err_msg='timestamp cannot be converted to number or less than 0, ts:-1499850242'
        },
        {
            args='1e10',
            expected=nil,
            err='ArgumentError',
            err_msg='timestamp cannot be scientific notation or decimal, ts:1e10'
        },
        {
            args='1499850242.1',
            expected=nil,
            err='ArgumentError',
            err_msg='timestamp cannot be scientific notation or decimal, ts:1499850242.1'
        },
        {
            args=string.sub('1499850242', 1, -2),
            expected=nil,
            err='ArgumentError',
            err_msg='invalid time length, not 10, 13, 16 or 19, ts:149985024'
        },
        {
            args='1499850242' .. '1',
            expected=nil,
            err='ArgumentError',
            err_msg='invalid time length, not 10, 13, 16 or 19, ts:14998502421'
        },

        {
            args=1499850242,
            expected=1499850242
        },
        {
            args=1499850242 * 1000,
            expected=1499850242
        },
        {
            args=1499850242 * 1000 * 1000,
            expected=nil,
            err='ArgumentError',
            err_msg='timestamp cannot be scientific notation or decimal, ts:1.499850242e+15'
        },
        {
            args=1499850242 * 1000 * 1000 * 1000,
            expected=nil,
            err='ArgumentError',
            err_msg='timestamp cannot be scientific notation or decimal, ts:1.499850242e+18'
        },
        {
            args=1e15,
            expected=nil,
            err='ArgumentError',
            err_msg='timestamp cannot be scientific notation or decimal, ts:1e+15'
        },
        {
            args=-1499850242,
            expected=nil,
            err='ArgumentError',
            err_msg='timestamp cannot be converted to number or less than 0, ts:-1499850242'
        },
        {
            args=1499850242.123,
            expected=nil,
            err='ArgumentError',
            err_msg='timestamp cannot be scientific notation or decimal, ts:1499850242.123'
        },

        {
            args=nil,
            expected=nil,
            err='ArgumentError',
            err_msg='timestamp cannot be converted to number or less than 0, ts:nil'
        },
        {
            args=true,
            expected=nil,
            err='ArgumentError',
            err_msg='timestamp cannot be converted to number or less than 0, ts:true'
        },
    }

    for i, case in pairs(cases) do
        local ts, err, err_msg = time.to_sec(case.args)

        dd( case.args, case.expected )
        t:eq( case.expected, ts )

        if err ~= nil then
            t:eq( case.err, err )
            t:eq( case.err_msg, err_msg )
        end
    end
end
