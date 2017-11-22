local setutil = require("acid.setutil")

local INF = math.huge

function test.check_set_range(t)

    for _, from, to, expected, err_expected, desc in t:case_iter(4, {
        {1,              2,              true,  nil            },
        {1,              1,              true,  nil            },
        {2,              1,              false, 'InvalidRange' },
        {'1',            '2',            true,  nil            },
        {'1',            '1',            true,  nil            },
        {'2',            '1',            false, 'InvalidRange' },
        {-INF,           1,              true,  nil            },
        {1,              INF,            true,  nil            },
        {-INF,           INF,            true,  nil            },
        {nil,            nil,            false, 'InvalidRange' },
        {'abc',          'xyz',          false, 'InvalidRange' },
        {true,           true,           false, 'InvalidRange' },
        {function() end, function() end, false, 'InvalidRange' },
        {{1, 2, 3},      {1, 2, 3},      false, 'InvalidRange' },
    }) do

        local res, err, err_msg = setutil.check_set_range(from, to)

        t:eq(expected, res)
        t:eq(err_expected, err, err_msg)
    end
end


function test.intersect(t)

    for _, f1, t1, f2, t2, intersection, desc in t:case_iter(5, {
        {1,    2,   3,    4,    {nil, nil} },
        {1,    2,   2,    3,    {2, 2}     },
        {1,    3,   2,    4,    {2, 3}     },
        {1,    4,   1,    4,    {1, 4}     },
        {1,    4,   2,    3,    {2, 3}     },
        {-INF, 1,   -INF, 0,    {-INF, 0}  },
        {0,    INF, 1,    INF,  {1, INF}   },
        {-INF, 1,   0,    INF,  {0, 1}     },
        {-INF, INF, -INF, INF,  {-INF, INF}},
    }) do

        local res, err, err_msg = setutil.intersect(f1, t1, f2, t2)

        t:eq(intersection[1], res.from)
        t:eq(intersection[2], res.to)
    end
end
