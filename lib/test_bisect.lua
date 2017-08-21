local bisect = require("acid.bisect")

local dd = test.dd

function test.search(t)

    for i, arr, key, expected_found, expected_l, desc in t:case_iter(4, {
        {{},      1, false, 0 },
        {{1},     0, false, 0 },
        {{1},     1, true,  1 },
        {{1},     2, false, 1 },
        {{1,3},   0, false, 0 },
        {{1,3},   1, true,  1 },
        {{1,3},   2, false, 1 },
        {{1,3},   3, true,  2 },
        {{1,3},   4, false, 2 },
        {{1,3,5}, 0, false, 0 },
        {{1,3,5}, 1, true,  1 },
        {{1,3,5}, 2, false, 1 },
        {{1,3,5}, 3, true,  2 },
        {{1,3,5}, 4, false, 2 },
        {{1,3,5}, 5, true,  3 },
        {{1,3,5}, 6, false, 3 },

        -- list compare

        {{{'a',1},{'a',3},{'b',0},{'d'}}, {},      false, 0 },
        {{{'a',1},{'a',3},{'b',0},{'d'}}, {'a'},   false, 0 },
        {{{'a',1},{'a',3},{'b',0},{'d'}}, {'a',1}, true,  1 },
        {{{'a',1},{'a',3},{'b',0},{'d'}}, {'a',2}, false, 1 },
        {{{'a',1},{'a',3},{'b',0},{'d'}}, {'a',3}, true,  2 },
        {{{'a',1},{'a',3},{'b',0},{'d'}}, {'a',4}, false, 2 },
        {{{'a',1},{'a',3},{'b',0},{'d'}}, {'b'},   false, 2 },
        {{{'a',1},{'a',3},{'b',0},{'d'}}, {'b',0}, true,  3 },
        {{{'a',1},{'a',3},{'b',0},{'d'}}, {'b',1}, false, 3 },
        {{{'a',1},{'a',3},{'b',0},{'d'}}, {'c'},   false, 3 },
        {{{'a',1},{'a',3},{'b',0},{'d'}}, {'c',1}, false, 3 },
        {{{'a',1},{'a',3},{'b',0},{'d'}}, {'d'},   true,  4 },
        {{{'a',1},{'a',3},{'b',0},{'d'}}, {'d',1}, false, 4 },
        {{{'a',1},{'a',3},{'b',0},{'d'}}, {'e'},   false, 4 },
        {{{'a',1},{'a',3},{'b',0},{'d'}}, {'e',3}, false, 4 },
    }) do

        local rst_found, rst_l = bisect.search(arr, key)
        dd('rst: found=', rst_found)
        dd('rst: l=', rst_l)

        t:eq(expected_found, rst_found, desc)
        t:eq(expected_l,     rst_l,     desc)
    end
end
