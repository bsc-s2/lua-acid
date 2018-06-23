local rangeset = require("acid.rangeset")


function test.new_rangedict(t)
    local cases = {
        {{{3, 4, "foo"}, {1, 2, "bar"}}, "ValueError", "range must be smaller than next one"},
        {{{1, nil, "foo"}, {10, 20, "bar"}}, "ValueError", "range must be smaller than next one"},
        {{{1, 2, "foo"}, {2, 3, "foo"}}, nil, nil},
        {{{1, 2, "foo"}, {4, 5, "foo"}}, nil, nil},
        {{{1, 2, "foo"}, {2, 3, "bar"}}, nil, nil},
        {{{1, 2, "foo"}, {7, 8, "bar"}}, nil, nil},
        {{{nil, 2, "foo"}, {7, 8, "bar"}}, nil, nil},

        {{{"3", "4", "foo"}, {"1", "2", "bar"}}, "ValueError", "range must be smaller than next one"},
        {{{"0", nil, "foo"}, {"1", "2", "bar"}}, "ValueError", "range must be smaller than next one"},
        {{{"1", "2", "foo"}, {"2", "3", "foo"}}, nil, nil},
        {{{"1", "2", "foo"}, {"4", "5", "foo"}}, nil, nil},
        {{{"1", "2", "foo"}, {"2", "3", "bar"}}, nil, nil},
        {{{"1", "2", "foo"}, {"7", "8", "bar"}}, nil, nil},
        {{{nil, "2", "foo"}, {"7", "8", "bar"}}, nil, nil},
    }

    for _, case in ipairs(cases) do
        local _, err, errmsg = rangeset.new_rangedict(case[1])
        t:eq(case[2], err)
        t:eq(case[3], errmsg)
    end
end


function test.get(t)
    local cases = {
        {{{1, 2, "foo"}, {2, 3, "foo"}}, 1, "foo", nil,},
        {{{1, 2, "foo"}, {2, 3, "foo"}}, 2, "foo", nil,},
        {{{1, 2, "foo"}, {2, 3, "foo"}}, 3, nil, "KeyError",},
        {{{1, 2, "foo"}, {2, 3, "foo"}}, 4, nil, "KeyError",},
        {{{1, 2, "foo"}, {2, 3, "foo"}}, 0, nil, "KeyError",},
        {{{1, 2, "foo"}, {2, 3, "foo"}}, -1, nil, "KeyError",},

        {{{1, 10, "foo"}, {20, 30, "foo"}}, -1, nil, "KeyError",},
        {{{1, 10, "foo"}, {20, 30, "foo"}}, 10, nil, "KeyError",},
        {{{1, 10, "foo"}, {20, 30, "foo"}}, 30, nil, "KeyError",},
        {{{1, 10, "foo"}, {20, 30, "foo"}}, 40, nil, "KeyError",},
        {{{1, 10, "foo"}, {20, 30, "foo"}}, 1, "foo", nil,},
        {{{1, 10, "foo"}, {20, 30, "foo"}}, 5, "foo", nil,},
        {{{1, 10, "foo"}, {20, 30, "foo"}}, 20, "foo", nil,},
        {{{1, 10, "foo"}, {20, 30, "foo"}}, 25, "foo", nil,},

        {{{1, 2, "foo"}, {2, 3, "bar"}}, 1, "foo", nil,},
        {{{1, 2, "foo"}, {2, 3, "bar"}}, 2, "bar", nil,},
        {{{1, 2, "foo"}, {2, 3, "bar"}}, 3, nil, "KeyError",},
        {{{1, 2, "foo"}, {2, 3, "bar"}}, 4, nil, "KeyError",},

        {{{1, 10, "foo"}, {20, 30, "bar"}}, -1, nil, "KeyError",},
        {{{1, 10, "foo"}, {20, 30, "bar"}}, 10, nil, "KeyError",},
        {{{1, 10, "foo"}, {20, 30, "bar"}}, 30, nil, "KeyError",},
        {{{1, 10, "foo"}, {20, 30, "bar"}}, 40, nil, "KeyError",},
        {{{1, 10, "foo"}, {20, 30, "bar"}}, 1, "foo", nil,},
        {{{1, 10, "foo"}, {20, 30, "bar"}}, 5, "foo", nil,},
        {{{1, 10, "foo"}, {20, 30, "bar"}}, 20, "bar", nil,},
        {{{1, 10, "foo"}, {20, 30, "bar"}}, 25, "bar", nil,},

        {{{10, nil, "foo"},}, -10, nil, "KeyError",},
        {{{10, nil, "foo"},}, 4, nil, "KeyError",},
        {{{10, nil, "foo"},}, 10, "foo", nil,},
        {{{10, nil, "foo"},}, 20, "foo", nil,},
        {{{10, nil, "foo"},}, 1000, "foo", nil,},

        {{{nil, 100, "foo"},}, -10, "foo", nil,},
        {{{nil, 100, "foo"},}, 10, "foo", nil,},
        {{{nil, 100, "foo"},}, 99, "foo", nil,},
        {{{nil, 100, "foo"},}, 100, nil, "KeyError",},
        {{{nil, 100, "foo"},}, 101, nil, "KeyError",},
        {{{nil, 100, "foo"},}, 200, nil, "KeyError",},

        {{{"10", nil, "foo"},}, "10", "foo", nil,},
        {{{"10", nil, "foo"},}, "20", "foo", nil,},
        {{{"10", nil, "foo"},}, "200", "foo", nil,},
        {{{"10", nil, "foo"},}, "00", nil, "KeyError",},
        {{{"10", nil, "foo"},}, "09", nil, "KeyError",},

        {{{nil, "100", "foo"},}, "000", "foo", nil,},
        {{{nil, "100", "foo"},}, "099", "foo", nil,},
        {{{nil, "100", "foo"},}, "100", nil, "KeyError",},
        {{{nil, "100", "foo"},}, "200", nil, "KeyError",},

        {{{"1", "2", "foo"}, {"2", "3", "foo"}}, "1", "foo", nil,},
        {{{"1", "2", "foo"}, {"2", "3", "foo"}}, "2", "foo", nil,},
        {{{"1", "2", "foo"}, {"2", "3", "foo"}}, "3", nil, "KeyError",},
        {{{"1", "2", "foo"}, {"2", "3", "foo"}}, "4", nil, "KeyError",},
        {{{"1", "2", "foo"}, {"2", "3", "foo"}}, "0", nil, "KeyError",},

        {{{"1", "2", "foo"}, {"2", "3", "bar"}}, "1", "foo", nil,},
        {{{"1", "2", "foo"}, {"2", "3", "bar"}}, "2", "bar", nil,},
        {{{"1", "2", "foo"}, {"2", "3", "bar"}}, "3", nil, "KeyError",},
        {{{"1", "2", "foo"}, {"2", "3", "bar"}}, "4", nil, "KeyError",},

        {{{"1", "2"}, {"2", "3"}}, "1", nil, nil,},
        {{{"1", "2"}, {"2", "3"}}, "2", nil, nil,},

        {{{"1", "10", "foo"}, {"20", "30", "foo"}}, "0", nil, "KeyError",},
        {{{"1", "10", "foo"}, {"20", "30", "foo"}}, "10", nil, "KeyError",},
        {{{"1", "10", "foo"}, {"20", "30", "foo"}}, "30", nil, "KeyError",},
        {{{"1", "10", "foo"}, {"20", "30", "foo"}}, "40", nil, "KeyError",},
        {{{"1", "10", "foo"}, {"20", "30", "foo"}}, "1", "foo", nil,},
        {{{"1", "10", "foo"}, {"20", "30", "foo"}}, "20", "foo", nil,},
        {{{"1", "10", "foo"}, {"20", "30", "bar"}}, "25", "bar", nil,},

    }

    for _, case in ipairs(cases) do
        local ranges, err, errmsg = rangeset.new_rangedict(case[1])
        t:eq(nil, err)
        t:eq(nil, errmsg)

        local v, err, _ = ranges:get(case[2])
        t:eq(case[3], v)
        t:eq(case[4], err)
    end
end
