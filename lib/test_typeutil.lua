local typeutil = require("acid.typeutil")

local dd = test.dd


function test.check_number_range(t)

    for _, value, min, max, left_closed, right_closed, expected, desc in t:case_iter(6, {
        {0,              0,   1,   nil,   nil,   true,  'range = [0, 1]'      },
        {1,              0,   1,   nil,   nil,   true,  'range = [0, 1]'      },
        {0,              0,   1,   false, nil,   false, 'range = (0, 1]'      },
        {1,              0,   1,   false, nil,   true,  'range = (0, 1]'      },
        {0,              0,   1,   nil,   false, true,  'range = [0, 1)'      },
        {1,              0,   1,   nil,   false, false, 'range = [0, 1)'      },
        {0,              0,   1,   false, false, false, 'range = (0, 1)'      },
        {1,              0,   1,   false, false, false, 'range = (0, 1)'      },
        {0,              0,   nil, nil,   nil,   true,  'range = [0, inf]'    },
        {0,              0,   nil, false, nil,   false, 'range = (0, inf]'    },
        {0,              nil, 0,   nil,   nil,   true,  'range = [-inf, 0]'   },
        {0,              nil, 0,   nil,   false, false, 'range = [-inf, 0)'   },
        {0,              nil, nil, nil,   nil,   true,  'range = [-inf, inf]' },
        {0,              nil, nil, false, false, true,  'range = (-inf, inf)' },
        {'abc',          0,   1,   nil,   nil,   false, 'range = [0, 1]'      },
        {'0',            0,   1,   nil,   nil,   false, 'range = [0, 1]'      },
        {'1',            0,   1,   nil,   nil,   false, 'range = [0, 1]'      },
        {nil,            0,   1,   nil,   nil,   false, 'range = [0, 1]'      },
        {{1, 2, 3},      0,   1,   nil,   nil,   false, 'range = [0, 1]'      },
        {function() end, 0,   1,   nil,   nil,   false, 'range = [0, 1]'      },
        {true,           0,   1,   nil,   nil,   false, 'range = [0, 1]'      },
    }) do

        local res = typeutil.check_number_range(value, min, max, left_closed, right_closed)
        t:eq(expected, res, desc)
    end
end

function test.check_number_string_range(t)

    for _, value, min, max, left_closed, right_closed, expected, desc in t:case_iter(6, {
        {'0',            0,   1,   nil,   nil,   true,  'range = [0, 1]'      },
        {'1',            0,   1,   nil,   nil,   true,  'range = [0, 1]'      },
        {'0',            0,   1,   false, nil,   false, 'range = (0, 1]'      },
        {'1',            0,   1,   false, nil,   true,  'range = (0, 1]'      },
        {'0',            0,   1,   nil,   false, true,  'range = [0, 1)'      },
        {'1',            0,   1,   nil,   false, false, 'range = [0, 1)'      },
        {'0',            0,   1,   false, false, false, 'range = (0, 1)'      },
        {'1',            0,   1,   false, false, false, 'range = (0, 1)'      },
        {'0',            nil, 0,   nil,   nil,   true,  'range = [-inf, 0]'   },
        {'0',            nil, 0,   nil,   false, false, 'range = [-inf, 0)'   },
        {'0',            nil, nil, nil,   nil,   true,  'range = [-inf, inf]' },
        {'0',            nil, nil, false, false, true,  'range = (-inf, inf)' },
        {0,              0,   1,   nil,   nil,   true,  'range = [0, 1]'      },
        {1,              0,   1,   nil,   nil,   true,  'range = [0, 1]'      },
        {0,              0,   1,   false, nil,   false, 'range = (0, 1]'      },
        {1,              0,   1,   false, nil,   true,  'range = (0, 1]'      },
        {0,              0,   1,   nil,   false, true,  'range = [0, 1)'      },
        {1,              0,   1,   nil,   false, false, 'range = [0, 1)'      },
        {0,              0,   1,   false, false, false, 'range = (0, 1)'      },
        {1,              0,   1,   false, false, false, 'range = (0, 1)'      },
        {'abc',          0,   1,   nil,   nil,   false, 'range = [0, 1]'      },
        {nil,            0,   1,   nil,   nil,   false, 'range = [0, 1]'      },
        {{1, 2, 3},      0,   1,   nil,   nil,   false, 'range = [0, 1]'      },
        {function() end, 0,   1,   nil,   nil,   false, 'range = [0, 1]'      },
        {true,           0,   1,   nil,   nil,   false, 'range = [0, 1]'      },
    }) do

        local res = typeutil.check_number_string_range(
            value, min, max, left_closed, right_closed)
        t:eq(expected, res, desc)
    end
end

function test.is_int(t)

    for _, value, expected, desc in t:case_iter(2, {
        {0,     true  },
        {0.5,   false },
        {1,     true  },
        {'0',   false },
        {'1',   false },
        {nil,   false },
        {'abc', false },
    }) do

        local res = typeutil.is_int(value)

        dd(value, res)
        t:eq(expected, res)
    end
end

function test.check_int_range(t)

    for _, value, min, max, expected, desc in t:case_iter(4, {
        {0,     0, 1, true  },
        {0.5,   0, 1, false },
        {1,     0, 1, true  },
        {-1,    0, 1, false },
        {2,     0, 1, false },
        {'0',   0, 1, false },
        {'1',   0, 1, false },
        {nil,   0, 1, false },
        {'abc', 0, 1, false },
    }) do

        local res = typeutil.check_int_range(value, min, max)

        dd(value, min, max, res)
        t:eq(expected, res, value)
    end
end
