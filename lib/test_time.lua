local time = require("acid.time")

local dd = test.dd


function test.parse(t)

    for _, fmtkey, date, expected, err_code, desc in t:case_iter(4, {
        {'isobase',        '20170726T061317Z',              1501049597, nil           },
        {'iso',            '2017-07-26T06:13:17.000Z',      1501049597, nil           },
        {'utc',            'Wed, 26 Jul 2017 06:13:17 UTC', 1501049597, nil           },
        {'std',            '2017-07-26 14:13:17',           1501049597, nil           },
        {'nginxaccesslog', '26/Jul/2017:14:13:17',          1501049597, nil           },
        {'nginxerrorlog',  '2017/07/26 14:13:17',           1501049597, nil           },
        {'utc',            'Wes, 26 Jul 2017 06:13:17 UTC', nil,        'FormatError' },
        {'utc',            'wed, 26 Jul 2017 06:13:17 UTC', nil,        'FormatError' },
        {'utc',            ' 26 Jul 2017 06:13:17 UTC',     nil,        'FormatError' },
        {'utc',            'Wed, 26 Jux 2017 06:13:17 UTC', nil,        'FormatError' },
        {'utc',            'Wed, 26 2017 06:13:17 UTC',     nil,        'FormatError' },
        {'utc',            'Wed, 26 Jul 2017 06:13:17',     nil,        'FormatError' },
        {'std',            '2017-07-26 14:u:17',            nil,        'FormatError' },
        {'std',            '2017-07-26 14:13:',             nil,        'FormatError' },
        {'nginxaccesslog', '26/Jux/2017:14:13:17',          nil,        'FormatError' },
        {'nginxaccesslog', '26//2017:14:13:17',             nil,        'FormatError' },
    }) do

        local res, err, err_msg = time.parse(date, fmtkey)
        dd(date, expected)

        t:eq(expected, res, desc)
        t:eq(err_code, err, err_msg)
    end
end


function test.format(t)

    for _, fmtkey, ts, expected, err_code, desc in t:case_iter(4, {
        {'iso',            1501049597, '2017-07-26T06:13:17.000Z',      nil             },
        {'utc',            1501049597, 'Wed, 26 Jul 2017 06:13:17 UTC', nil             },
        {'std',            1501049597, '2017-07-26 14:13:17',           nil             },
        {'nginxaccesslog', 1501049597, '26/Jul/2017:14:13:17',          nil             },
        {'nginxerrorlog',  1501049597, '2017/07/26 14:13:17',           nil             },
        {'std',            nil,        nil,                             'ArgumentError' },
        {'std',            {},         nil,                             'ArgumentError' },
        {'std',            ':',        nil,                             'ArgumentError' },
        {'std',            'XxX',      nil,                             'ArgumentError' },
    }) do

        local res, err, err_msg = time.format(ts, fmtkey)
        dd(ts, expected)

        t:eq(expected, res, desc)
        t:eq(err_code, err, err_msg)
    end
end


function test.timezone(t)
    local local_time = os.time()
    local utc_time = os.time(os.date("!*t", local_time))

    local timezone = time.timezone

    t:eq(utc_time, local_time+timezone, 'timezone is wrong, timezone:' .. timezone)
end


function test.to_sec(t)

    for _, ts, expected, err_code, desc in t:case_iter(3, {
        {'1499850242',                            1499850242, nil             },
        {'1499850242' .. '000',                   1499850242, nil             },
        {'1499850242' .. '000' .. '000',          1499850242, nil             },
        {'1499850242' .. '000' .. '000' .. '000', 1499850242, nil             },
        {'abc1499850242',                         nil,        'ArgumentError' },
        {'1499850242abc',                         nil,        'ArgumentError' },
        {'-1499850242',                           nil,        'ArgumentError' },
        {'1e10',                                  nil,        'ArgumentError' },
        {'1499850242.1',                          nil,        'ArgumentError' },
        {string.sub('1499850242', 1, -2),         nil,        'ArgumentError' },
        {'1499850242' .. '1',                     nil,        'ArgumentError' },
        {1499850242,                              1499850242, nil             },
        {1000000000,                              1000000000, nil             },
        {1000000000 + 1,                          1000000001, nil             },
        {1000000000 - 1,                          nil,        'ArgumentError' },
        {9999999999,                              9999999999, nil             },
        {9999999999 + 1,                          nil,        'ArgumentError' },
        {9999999999 - 1,                          9999999998, nil             },
        {1499850242 * 1000,                       1499850242, nil             },
        {1000000000 * 1000,                       1000000000, nil             },
        {1000000000 * 1000 + 1,                   1000000000, nil             },
        {1000000000 * 1000 - 1,                   nil,        'ArgumentError' },
        {9999999999 * 1000 + 999,                 9999999999, nil             },
        {9999999999 * 1000 + 999 + 1,             nil,        'ArgumentError' },
        {9999999999 * 1000 + 999 - 1,             9999999999, nil             },
        {1499850242 * 1000 * 1000,                nil,        'ArgumentError' },
        {1499850242 * 1000 * 1000 * 1000,         nil,        'ArgumentError' },
        {1e15,                                    nil,        'ArgumentError' },
        {-1499850242,                             nil,        'ArgumentError' },
        {1499850242.123,                          nil,        'ArgumentError' },
        {nil,                                     nil,        'ArgumentError' },
        {true,                                    nil,        'ArgumentError' },
    }) do

        local res, err, err_msg = time.to_sec(ts)
        dd(ts, expected)

        t:eq(expected, res, desc)
        t:eq(err_code, err, err_msg)
    end
end
