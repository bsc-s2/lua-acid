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

        local res = typeutil.check_number_range(value, min, max, { left_closed = left_closed, right_closed = right_closed })
        t:eq(expected, res, desc)
    end
end

function test.check_string_number_range(t)

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
        {0,              0,   1,   nil,   nil,   false, 'range = [0, 1]'      },
        {1,              0,   1,   nil,   nil,   false, 'range = [0, 1]'      },
        {0,              0,   1,   false, nil,   false, 'range = (0, 1]'      },
        {1,              0,   1,   false, nil,   false, 'range = (0, 1]'      },
        {0,              0,   1,   nil,   false, false, 'range = [0, 1)'      },
        {1,              0,   1,   nil,   false, false, 'range = [0, 1)'      },
        {0,              0,   1,   false, false, false, 'range = (0, 1)'      },
        {1,              0,   1,   false, false, false, 'range = (0, 1)'      },
        {'abc',          0,   1,   nil,   nil,   false, 'range = [0, 1]'      },
        {nil,            0,   1,   nil,   nil,   false, 'range = [0, 1]'      },
        {{1, 2, 3},      0,   1,   nil,   nil,   false, 'range = [0, 1]'      },
        {function() end, 0,   1,   nil,   nil,   false, 'range = [0, 1]'      },
        {true,           0,   1,   nil,   nil,   false, 'range = [0, 1]'      },
    }) do

        local res = typeutil.check_string_number_range(
            value, min, max, { left_closed = left_closed, right_closed = right_closed })
        t:eq(expected, res, desc)
    end
end

function test.is_integer(t)

    for _, value, expected, desc in t:case_iter(2, {
        {0,     true  },
        {0.5,   false },
        {1,     true  },
        {1.0,   true  },
        {'0',   false },
        {'1',   false },
        {nil,   false },
        {'abc', false },
    }) do

        local res = typeutil.is_integer(value)
        t:eq(expected, res)
    end
end

function test.is_string(t)
    for _, value, expected, desc in t:case_iter(2, {
        {1,     false },
        {'0',   true  },
        {nil,   false },
        {'abc', true  },
        {{a=1}, false },
    }) do

        local res = typeutil.is_string(value)
        t:eq(expected, res)
    end
end

function test.is_number(t)
    for _, value, expected, desc in t:case_iter(2, {
        {1,     true  },
        {1.1,   true  },
        {-1.1,   true },
        {nil,   false },
        {'abc', false },
        {{a=1}, false },
    }) do

        local res = typeutil.is_number(value)
        t:eq(expected, res)
    end
end

function test.is_boolean(t)
    for _, value, expected, desc in t:case_iter(2, {
        {true,  true  },
        {false, true  },
        {-1.1,  false },
        {nil,   false },
        {'abc', false },
        {{a=1}, false },
    }) do

        local res = typeutil.is_boolean(value)
        t:eq(expected, res)
    end
end

function test.is_string_number(t)
    for _, value, expected, desc in t:case_iter(2, {
        {false, false },
        {-1.1,  false },
        {nil,   false },
        {'abc', false },
        {{a=1}, false },
        { 1,    false },
        {'10.0',true  },
        {'1',   true  },
    }) do

        local res = typeutil.is_string_number(value)
        t:eq(expected, res)
    end
end

function test.is_array(t)
    for _, value, expected, desc in t:case_iter(2, {
        {false,                             false },
        {-1.1,                              false },
        {nil,                               false },
        {'abc',                             false },
        {{a=1},                             false },
        { 1,                                false },
        {'10.0',                            false },
        {{},                                true  },
        {{{}},                              true  },
        {{1,2,3},                           true  },
        {{[1]=1,2,3},                       true  },
        {{[1]=1,2,[100]=3},                 false },
        {{[1]=1,2,[9]=3},                   true  },
        {{1,2,3,4,5,6,7,8,9,[15]=11},       true  },
    }) do

        local res = typeutil.is_array(value)
        t:eq(expected, res)
    end
end

function test.is_dict(t)
    for _, value, expected, desc in t:case_iter(2, {
        {false,                             false },
        {-1.1,                              false },
        {nil,                               false },
        {'abc',                             false },
        { 1,                                false },
        {'10.0',                            false },
        {{a=1},                             true  },
        {{},                                true  },
        {{{}},                              false },
        {{1,2,3},                           false },
        {{[1]=1,2,3},                       false },
        {{[1]=1,2,[100]=3},                 true  },
        {{[1]=1,2,[9]=3},                   false },
        {{1,2,3,4,5,6,7,8,9,[15]=11},       false },
    }) do

        local res = typeutil.is_dict(value)
        t:eq(expected, res)
    end
end

function test.is_empty_table(t)
    for _, value, expected, desc in t:case_iter(2, {
        {false,                             false },
        {-1.1,                              false },
        {nil,                               false },
        {'abc',                             false },
        { 1,                                false },
        {'10.0',                            false },
        {{a=1},                             false },
        {{{}},                              false },
        {{},                                true  },
    }) do

        local res = typeutil.is_empty_table(value)
        t:eq(expected, res)
    end
end

function test.check_integer_range(t)

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

        local res = typeutil.check_integer_range(value, min, max)
        t:eq(expected, res)
    end
end

function test.check_length_range(t)
    for _, value, min, max, left_closed, right_closed, expected, desc in t:case_iter(6, {
        {'',              0,   1,    nil,   nil,   true,     'range = [0, 1]'      },
        {'1',             0,   1,    nil,   nil,   true,     'range = [0, 1]'      },
        {'',              0,   1,    false, nil,   false,    'range = (0, 1]'      },
        {'a',             0,   1,    false, nil,   true,     'range = (0, 1]'      },
        {'',              0,   1,    nil,   false, true,     'range = [0, 1)'      },
        {'a',             0,   1,    nil,   false, false,    'range = [0, 1)'      },
        {'',              0,   1,    false, false, false,    'range = (0, 1)'      },
        {'a',             0,   1,    false, false, false,    'range = (0, 1)'      },
        {'',              0,   nil,  nil,   nil,   true,     'range = [0, inf]'    },
        {'',              0,   nil,  false, nil,   false,    'range = (0, inf]'    },
        {'',              nil, 0,    nil,   nil,   true,     'range = [-inf, 0]'   },
        {'',              nil, 0,    nil,   false, false,    'range = [-inf, 0)'   },
        {'',              nil, nil,  nil,   nil,   true,     'range = [-inf, inf]' },
        {'',              nil, nil,  false, false, true,     'range = (-inf, inf)' },
        {'1',             0,   1,    false, false, false,    'range = (0, 1)'      },
        {{},              0,   1,    nil,   nil,   true,     'range = [0, 1]'      },
        {{1},             0,   1,    nil,   nil,   true,     'range = [0, 1]'      },
        {{1,[10]=1},      0,   1,    nil,   nil,   true,     'range = [0, 1]'      },
        {{1,2},           0,   1,    nil,   nil,   false,    'range = [0, 1]'      },

    }) do

        local res = typeutil.check_length_range(value, min, max, { left_closed = left_closed, right_closed = right_closed })
        t:eq(expected, res, desc)


    end
end

function test.check_fixed_length(t)

    for _, value, length, expected, desc in t:case_iter(3, {
        {'',            0,   true  },
        {'1a',          2,   true  },
        {'12',          1,   false },
        {{},            0,   true  },
        {{1,2},         2,   true  },
        {{1,[10]=1},    1,   true  },
    }) do

        local res = typeutil.check_fixed_length(value, length)
        t:eq(expected, res)
    end
end