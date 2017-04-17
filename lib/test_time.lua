local time = require("acid.time")

function test.iso()
    local p = time.parse.iso
    local f = time.format.iso

    local t = '2015-04-06T21:26:32.000Z'
    local e = 1428355592

    assert(e == p(t), 'timezone 0: ' .. e - p(t))
    assert(t == f(p(t)), 'timezone 0: ' .. t .. ' ' .. f(p(t)))
end

function test()

    local _assert = function( func, input, aout, aerr, amsg )
        local out, err, msg = func( input )
        assert( out == aout )
        assert( err == aerr )
        if amsg ~= nil then
            assert( msg == amsg )
        end
    end

    local case = {
        -- func, input, aout, aerr, amsg
        { time.parse.isobase, '20170414T105302Z', 1492167182},
        { time.parse.iso, '2015-06-21T04:33:42.000Z', 1434861222 },
        { time.parse.utc, 'Sun, 21 Jun 2015 04:33:42 UTC', 1434861222 },
        { time.parse.std, '2015-06-21 12:33:42', 1434861222 },
        { time.parse.ngxaccesslog, '21/Jun/2015:12:33:42', 1434861222 },
        { time.parse.ngxerrorlog, '2015/06/21 12:33:42', 1434861222 },

        { time.parse.isobase, '0170414T105302Z', nil, 'FormatError'},
        { time.parse.isobase, nil, nil, 'FormatError', 'type: nil date format error'},
        { time.parse.isobase, {}, nil, 'FormatError', 'type: table date format error'},
        { time.parse.isobase, false, nil, 'FormatError'},
        { time.parse.isobase, 10, nil, 'FormatError', 'type: number date format error'},

        { time.parse.utc, 'Tun, 21 Jun 2015 04:33:42 UTC', nil, 'FormatError',
                            'Tun, 21 Jun 2015 04:33:42 UTC date format error' },
        { time.parse.utc, 'un, 21 Jun 2015 04:33:42 UTC', nil, 'FormatError' },
        { time.parse.utc, ' 21 Jun 2015 04:33:42 UTC', nil, 'FormatError' },
        { time.parse.utc, 'Sun, 21 Jux 2015 04:33:42 UTC', nil, 'FormatError' },
        { time.parse.utc, 'Sun, 21 Jun 2015 04:33:42', nil, 'FormatError' },

        { time.parse.std, '2015-06-21 12:u:42', nil, 'FormatError' },
        { time.parse.std, '2015-06-21 12:33:', nil, 'FormatError' },
        { time.parse.std, nil, nil, 'FormatError', 'type: nil date format error' },
        { time.parse.std, {}, nil, 'FormatError', 'type: table date format error' },
        { time.parse.std, true, nil, 'FormatError' },
        { time.parse.std, 10, nil, 'FormatError', 'type: number date format error' },

        { time.format.iso, 1434861222, '2015-06-21T04:33:42.000Z' },
        { time.format.utc, 1434861222, 'Sun, 21 Jun 2015 04:33:42 UTC' },
        { time.format.std, 1434861222, '2015-06-21 12:33:42' },
        { time.format.ngxaccesslog, 1434861222, '21/Jun/2015:12:33:42' },
        { time.format.ngxerrorlog, 1434861222, '2015/06/21 12:33:42' },

        { time.format.iso, nil, nil, 'ValueError', 'timestamp cannot tonumber' },
        { time.format.iso, {}, nil, 'ValueError', 'timestamp cannot tonumber' },
        { time.format.iso, ':', nil, 'ValueError', 'timestamp cannot tonumber' },
        { time.format.iso, true, nil, 'ValueError' },

        { time.format.std, nil, nil, 'ValueError', 'timestamp cannot tonumber' },
        { time.format.std, {}, nil, 'ValueError' },
        { time.format.std, ':', nil, 'ValueError', 'timestamp cannot tonumber' },
        { time.format.std, 'XxX', nil, 'ValueError' },
    }

    for _, cs in ipairs( case ) do
        _assert( cs[1], cs[2], cs[3], cs[4], cs[5] )
    end

end

function test.timezone()
    local zone = -3600 * 8
    local timezone = time.timezone

    assert(zone == timezone, 'timezone is wrong, timezone:'..timezone)
end

function test.ts_to_sec()
    local ts = '1492398063010001'
    local sec = 1492398063

    assert(sec == time.ts_to_sec(ts), 'ts_to_sec is wrong,ts:'..ts..'sec:'..sec)
end
