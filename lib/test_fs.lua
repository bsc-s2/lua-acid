local fs = require('acid.fs')


function test.read_dir(t)
    local r, err, errmsg = fs.read_dir('/')
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)
    t:eq('table', type(r))
    t:eq(true, #r > 0)

    local _, err, errmsg = fs.read_dir('/not_exist_dir')
    t:neq(nil, err)
    t:neq(nil, errmsg)
end


function test.is_dir(t)
    local r, err, errmsg = fs.is_dir('/root')
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)
    t:eq(true, r)

    local r, err, errmsg = fs.is_dir('/root/.bashrc')
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)
    t:eq(false, r)

    local r, err, errmsg = fs.is_dir('/not_exist_dir')
    t:neq(nil, err, errmsg)
    t:neq(nil, errmsg)
    t:eq(nil, r)
end


function test.is_file(t)
    local r, err, errmsg = fs.is_file('/root')
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)
    t:eq(false, r)

    local r, err, errmsg = fs.is_file('/root/.bashrc')
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)
    t:eq(true, r)

    local r, err, errmsg = fs.is_dir('/not_exist_file')
    t:neq(nil, err, errmsg)
    t:neq(nil, errmsg)
    t:eq(nil, r)
end


function test.is_exist(t)
    local r, err, errmsg = fs.is_exist('/root')
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)
    t:eq(true, r)

    local r, err, errmsg = fs.is_exist('/not_exist')
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)
    t:eq(false, r)
end


function test.get_sorted_unique_fns(t)
    for _, ori_fns, expected, desc in t:case_iter(2, {
        {{                         },  {}                },
        {{'a', 'a'                 },  {'a'}             },
        {{'a', 'a', 'c', 'b'       },  {'a', 'b', 'c'}   },
        {{'测试', '测试', 'c', 'b' },  {'b', 'c', '测试'}},
    }) do

        local r, err, errmsg = fs.get_sorted_unique_fns(ori_fns)
        t:eq(nil, err, desc)
        t:eq(nil, errmsg, desc)
        t:eqdict(expected, r, desc)
    end
end


function test.rm_file(t)
    local r, err, errmsg = fs.rm_file('not_exist_file')
    t:neq(nil, err)
    t:neq(nil, errmsg)
    t:eq(nil, r)

    local test_dir = 'test_dir_' .. tostring(math.random(10000, 99999))
    local _, err, errmsg = fs.make_dir(test_dir)
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)

    local _, err, errmsg = fs.rm_file(test_dir)
    t:eq(nil, err)
    t:eq(nil, errmsg)

    local r, err, errmsg = fs.is_exist(test_dir)
    t:eq(nil, err)
    t:eq(nil, errmsg)
    t:eq(false, r)

    local test_file = 'test_file' .. tostring(math.random(10000, 99999))
    local _, err, errmsg = fs.write(test_file, 'test_data')
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)

    local _, err, errmsg = fs.rm_file(test_file)
    t:eq(nil, err)
    t:eq(nil, errmsg)

    local r, err, errmsg = fs.is_exist(test_file)
    t:eq(nil, err)
    t:eq(nil, errmsg)
    t:eq(false, r)
end


function test.make_dir(t)
    local test_dir = 'test_dir_' .. tostring(math.random(10000, 99999))
    local _, err, errmsg = fs.make_dir(test_dir)
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)

    local r, _, _ = fs.is_dir(test_dir)
    os.remove(test_dir)
    t:eq(true, r)
end


function test.atomic_write(t)
    local test_file = 'test_file' .. tostring(math.random(10000, 99999))
    local _, err, errmsg = fs.atomic_write(test_file, 'test_data')
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)

    local f = io.open(test_file, 'r')
    local data = f:read('*a')
    os.remove(test_file)
    t:eq('test_data', data)
end


function test.read(t)
    local test_file = 'test_file' .. tostring(math.random(10000, 99999))
    local _, err, errmsg = fs.write(test_file, 'test_data')
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)

    local data, err, errmsg = fs.read(test_file)
    os.remove(test_file)
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)
    t:eq('test_data', data)
end


function test.rm_tree(t)
    local test_dir = 'test_dir_' .. tostring(math.random(10000, 99999))
    local _, err, errmsg = fs.mkdir(test_dir)
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)

    local _, err, errmsg = fs.write(test_dir .. '/test_file', 'test_data')
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)

    local _, err, errmsg = fs.rm_tree(test_dir)
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)

    local r, _, _ = fs.is_exist(test_dir)
    t:eq(false, r)
end


function test.rm_tree(t)
    local test_dir = 'test_dir_' .. tostring(math.random(10000, 99999))
    local _, err, errmsg = fs.make_dir(test_dir)
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)

    local _, err, errmsg = fs.write(test_dir .. '/test_file', 'test_data')
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)

    local _, err, errmsg = fs.rm_tree(test_dir)
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)

    local r, _, _ = fs.is_exist(test_dir)
    t:eq(false, r)
end


function test.rm_tree_keep_root(t)
    local test_dir = 'test_dir_' .. tostring(math.random(10000, 99999))
    local _, err, errmsg = fs.make_dir(test_dir)
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)

    local _, err, errmsg = fs.write(test_dir .. '/test_file', 'test_data')
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)

    local _, err, errmsg = fs.make_dir(test_dir .. '/sub_dir')
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)

    local _, err, errmsg = fs.rm_tree(test_dir, {keep_root=true})
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)

    local r, err, errmsg = fs.is_dir(test_dir)
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)
    t:eq(true, r)

    local r, err, errmsg = fs.is_exist(test_dir .. '/sub_dir')
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)
    t:eq(false, r)

    os.remove(test_dir)
end


function test.base_path(t)
    for _, path, expected, desc in t:case_iter(2, {
        {'',       ''     },
        {'a',      ''     },
        {'a/',     'a'    },
        {'a/a',    'a'    },
        {'a/a/',   'a/a'  },
        {'/',      '/'    },
        {'/a',     '/'    },
        {'/a/',    '/a'   },
        {'/a/b',   '/a'   },
        {'/a/b/',  '/a/b' },
        {'/a/b/c', '/a/b' },
    }) do

        t:eq(1, 1)
        local r, err, errmsg = fs.base_path(path)
        t:eq(nil, err, desc)
        t:eq(nil, errmsg, desc)
        t:eq(expected, r, desc)
    end
end


function test.make_dirs(t)
    local test_dir = 'test_dir_' .. tostring(math.random(10000, 99999))
    for _, path, desc in t:case_iter(2, {
        {'a/b/c/d/e/f/g/h/i/j/k/l/m/n/o/p/q/r/s/t/u/v/w/x/y/z' },
        {'a/b/c'                                               },
        {'a/c'                                                 },
        {'a'                                                   },
        {'b'                                                   },
    }) do

        local dir = test_dir .. '/' .. path
        local _, err, errmsg = fs.make_dirs(dir)
        t:eq(nil, err, desc)
        t:eq(nil, errmsg, desc)

        local r, err, errmsg = fs.is_dir(dir)
        t:eq(nil, err, desc)
        t:eq(nil, errmsg, desc)
        t:eq(true, r, desc)
    end

    fs.rm_tree(test_dir)
end
