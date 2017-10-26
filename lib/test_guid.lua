local guid = require("acid.guid")

local dd = test.dd

function test.len_guid_parts(t)

    for _, len_ts, len_seq, len_mid, err_expected, desc in t:case_iter(4, {
        {13,  2,   4,   nil             },
        {12,  3,   4,   nil             },
        {11,  4,   4,   nil             },
        {10,  5,   4,   nil             },
        {9,   6,   4,   nil             },
        {12,  2,   5,   nil             },
        {11,  2,   6,   nil             },
        {10,  2,   7,   nil             },
        {13,  0,   0,   'InvalidLength' },
        {13,  -1,  -1,  'InvalidLength' },
        {nil, nil, nil, 'InvalidLength' },
        {13,  2.5, 3.5, 'InvalidLength' },
        {14,  2,   3,   'InvalidLength' },
    }) do

        local obj, err, err_msg = guid.new(
            'test_shared', 'shared_dict_lock', len_ts, len_seq, len_mid)

        t:eq(err_expected, err, err_msg)

        if err == nil then
            local res, err, err_msg = obj:generate(obj.max_mid)

            t:eq(nil, err, err_msg)
            t:eq(obj.len_guid, #res)
        end
    end
end

function test.generate(t)
    local obj, err, err_msg = guid.new('test_shared', 'shared_dict_lock', 13, 2, 4)

    for _, mid, max_wait_time, err_expected, desc in t:case_iter(3, {
        {0,               nil, nil               },
        {0,               0,   nil               },
        {0,               1,   nil               },
        {obj.max_mid,     nil, nil               },
        {obj.max_mid,     0,   nil               },
        {obj.max_mid,     1,   nil               },
        {nil,             nil, 'InvalidMachineId'},
        {0.123,           nil, 'InvalidMachineId'},
        {-1,              nil, 'InvalidMachineId'},
        {obj.max_mid + 1, nil, 'InvalidMachineId'},
    }) do

        local res, err, err_msg = obj:generate(mid, max_wait_time)

        if err == nil then
            t:eq(obj.len_guid, #res)
        else
            t:eq(err_expected, err, err_msg)
        end
    end
end

function test.unique_guid(t)
    local obj, err, err_msg = guid.new('test_shared', 'shared_dict_lock', 13, 2, 4)

    local tab = {}
    local count = 0
    local start = os.time()

    while os.difftime(os.time(), start) < 10 do
        local res, err, err_msg = obj:generate(obj.max_mid)

        t:eq(nil, tab[res], 'generate the same guid: ' .. res)

        tab[res] = 1
        count = count + 1
    end

    t:eq(true, count <= 10 * 1000 * 100)
end

function test.parse(t)
    local obj, err, err_msg = guid.new('test_shared', 'shared_dict_lock', 13, 2, 4)

    for _, guid_str, ts, seq, mid, err_expected, desc in t:case_iter(5, {
        {'1505375219371000000', 1505375219371, 0,   0,    nil         },
        {'1505375219371990000', 1505375219371, 99,  0,    nil         },
        {'1505375219371009999', 1505375219371, 0,   9999, nil         },
        {'1505375219371999999', 1505375219371, 99,  9999, nil         },
        {nil,                   nil,           nil, nil, 'NotString'  },
        {1505375219371000000,   nil,           nil, nil, 'NotString'  },
        {{1, 2, 3},             nil,           nil, nil, 'NotString'  },
        {function() end,        nil,           nil, nil, 'NotString'  },
        {true,                  nil,           nil, nil, 'NotString'  },
        {'abcdef',              nil,           nil, nil, 'InvalidGuid'},
        {string.rep('f', 19),   nil,           nil, nil, 'InvalidGuid'},
        {string.rep('1', 18),   nil,           nil, nil, 'InvalidGuid'},
        {string.rep('1', 20),   nil,           nil, nil, 'InvalidGuid'},
    }) do

        local res, err, err_msg = obj:parse(guid_str)

        dd(guid_str, res)

        if err == nil then
            t:eq(ts, res.ts)
            t:eq(seq, res.seq)
            t:eq(mid, res.mid)
        else
            t:eq(err_expected, err, err_msg)
        end
    end
end
