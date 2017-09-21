local bit = require('bit')
local fs_ffi = require('acid.fs_ffi')
local fsutil = require('acid.fsutil')
local util = require('acid.util')

math.randomseed(ngx.now() * 1000)


local function get_random_str()
    return tostring(math.random(10000, 99999))
end


local test_dir = '/tmp/test_dir_' .. get_random_str()


local function setup_test_files(t, base_path)
    if fsutil.is_dir(base_path) then
        return
    end
    local _, err, errmsg = fsutil.make_dir(base_path)
    t:eq(nil, err, errmsg)

    local test_files = {
        {'file1', false},
        {'sub_dir', true},
        {'sub_dir/file2', false},
    }
    for _, test_file in ipairs(test_files) do
        local path = base_path .. '/' .. test_file[1]
        if test_file[2] then
            local _, err, errmsg = fsutil.make_dir(path)
            t:eq(nil, err, errmsg)
        else
            local fd, err = io.open(path, 'w')
            t:eq(nil, err)
            fd:write('test data')
            fd:close()
        end
    end
end


function test.is_exist(t)
    setup_test_files(t, test_dir)
    local exist, err, errmsg = fsutil.is_exist(test_dir)
    t:eq(nil, err, errmsg)
    t:eq(true, exist)

    local exist, err, errmsg = fsutil.is_exist(test_dir .. '/file1')
    t:eq(nil, err, errmsg)
    t:eq(true, exist)

    local exist, err, errmsg = fsutil.is_exist('/not_exist_file')
    test.dd(err)
    test.dd(errmsg)
    t:neq(nil, err)
    t:eq(nil, exist)
end


function test.is_dir(t)
    setup_test_files(t, test_dir)

    local is_dir, err, errmsg = fsutil.is_dir(test_dir)
    t:eq(nil, err, errmsg)
    t:eq(true, is_dir)

    local is_dir, err, errmsg = fsutil.is_dir(test_dir .. '/file1')
    t:eq(nil, err, errmsg)
    t:eq(false, is_dir)

    local is_dir, err, errmsg = fsutil.is_dir('/not_exist_file')
    test.dd(err)
    test.dd(errmsg)
    t:neq(nil, err)
    t:eq(nil, is_dir)
end


function test.is_file(t)
    setup_test_files(t, test_dir)

    local is_file, err, errmsg = fsutil.is_file(test_dir)
    t:eq(nil, err, errmsg)
    t:eq(false, is_file)

    local is_file, err, errmsg = fsutil.is_file(test_dir .. '/file1')
    t:eq(nil, err, errmsg)
    t:eq(true, is_file)

    local is_file, err, errmsg = fsutil.is_file('/not_exist_file')
    test.dd(err)
    test.dd(errmsg)
    t:neq(nil, err)
    t:eq(nil, is_file)
end


function test.read_dir(t)
    setup_test_files(t, test_dir)

    local entries, err, errmsg = fsutil.read_dir(test_dir)
    test.dd(entries)
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)
    t:eq(2, #entries)

    local entries, err, errmsg = fsutil.read_dir(test_dir .. '/sub_dir')
    test.dd(entries)
    t:eq(nil, err, errmsg)
    t:eqdict({'file2'}, entries)

    local _, err, errmsg = fsutil.read_dir('/not_exist_dir')
    test.dd(err)
    test.dd(errmsg)
    t:neq(nil, err)
    t:neq(nil, errmsg)
end


function test.make_dir(t)
    local test_dir = '/tmp/test_dir_' .. get_random_str()
    test.dd(test_dir)

    local _, err, errmsg = fsutil.make_dir(test_dir)
    t:eq(nil, err, errmsg)

    local file_stat, err, errmsg = fs_ffi.stat(test_dir)
    test.dd(file_stat)
    t:eq(nil, err, errmsg)
    t:eq(0, file_stat.st_uid)
    t:eq(0, file_stat.st_gid)
    local mode_mask = bit.bor(fs_ffi.S_IRWXU, fs_ffi.S_IRWXG, fs_ffi.S_IRWXO)
    t:eq(tonumber('755', 8), bit.band(file_stat.st_mode, mode_mask))

    local _, err, errmsg = fsutil.make_dir(test_dir, tonumber('744', 8),
                                           'nobody', 'nobody')
    t:eq(nil, err, errmsg)

    local file_stat, err, errmsg = fs_ffi.stat(test_dir)
    test.dd(file_stat)
    t:eq(nil, err, errmsg)
    t:eq(util.get_user('nobody').pw_uid, file_stat.st_uid)
    t:eq(util.get_group('nobody').gr_gid, file_stat.st_gid)
    local mode_mask = bit.bor(fs_ffi.S_IRWXU, fs_ffi.S_IRWXG, fs_ffi.S_IRWXO)
    t:eq(tonumber('744', 8), bit.band(file_stat.st_mode, mode_mask))

    local _, err = os.remove(test_dir)
    t:eq(nil, err, 'remove test_dir: ' .. test_dir)
end


function test.make_dir_error(t)
    setup_test_files(t, test_dir)

    local _, err, errmsg = fsutil.make_dir('/not_exist_dir/test_dir')
    test.dd(err)
    test.dd(errmsg)
    t:neq(err)
    t:neq(errmsg)

    local _, err, errmsg = fsutil.make_dir(test_dir .. '/file1')
    test.dd(err)
    test.dd(errmsg)
    t:neq(nil, err)
    t:neq(nil, errmsg)
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
        local r, err, errmsg = fsutil.base_path(path)
        t:eq(nil, err, desc)
        t:eq(nil, errmsg, desc)
        t:eq(expected, r, desc)
    end
end


function test.make_dirs(t)
    local test_dir = '/tmp/test_dir_' .. get_random_str()
    test.dd(test_dir)
    local _, err, errmsg = fsutil.make_dir(test_dir)
    t:eq(nil, err, errmsg)

    for _, path, desc in t:case_iter(1, {
        {'a/b/c/d/e/f/g/h/i/j/k/l/m/n/o/p/q/r/s/t/u/v/w/x/y/z' },
        {'a/b/c'                                               },
        {'a/c'                                                 },
        {'a'                                                   },
        {'b'                                                   },
    }) do

        local dir = test_dir .. '/' .. path
        local _, err, errmsg = fsutil.make_dirs(dir)
        t:eq(nil, err, desc)
        t:eq(nil, errmsg, desc)

        t:eq(true, fsutil.is_dir(dir), desc)
    end

    local _, err, errmsg = fsutil.remove_tree(test_dir)
    t:eq(nil, err, errmsg)

    local _, err, errmsg = fsutil.make_dirs('/aa/bb/cc')
    t:eq(nil, err, errmsg)

    local _, err = os.remove('/aa/bb/cc')
    t:eq(nil, err, 'remove /aa/bb/cc')
end


function test.remove_tree(t)
    local test_dir = '/tmp/test_dir_' .. get_random_str()
    setup_test_files(t, test_dir)

    local _, err, errmsg = fsutil.remove_tree('not_exist_dir')
    t:eq(nil, err, errmsg)

    local _, err, errmsg = fsutil.remove_tree(test_dir .. '/file1')
    test.dd(err)
    test.dd(errmsg)
    t:neq(nil, err)
    t:neq(nil, errmsg)

    local _, err, errmsg = fsutil.remove_tree(test_dir .. '/sub_dir',
                                              {keep_root = true})
    t:eq(nil, err, errmsg)
    t:eq(nil, fsutil.is_exist(test_dir .. '/sub_dir/file2'))
    t:eq(true, fsutil.is_exist(test_dir .. '/sub_dir'))

    local _, err, errmsg = fsutil.remove_tree(test_dir)
    t:eq(nil, err, errmsg)
    t:eq(nil, fsutil.is_exist(test_dir))
end


function test.file_size(t)
    setup_test_files(t, test_dir)

    local _, err, errmsg = fsutil.file_size('not_exist_file')
    test.dd(err)
    test.dd(errmsg)
    t:neq(nil, err)
    t:neq(nil, errmsg)

    local size, err, errmsg = fsutil.file_size(test_dir)
    t:eq(nil, err, errmsg)
    t:eq(4096, size)

    local size, err, errmsg = fsutil.file_size(test_dir .. '/file1')
    t:eq(nil, err, errmsg)
    t:eq(9, size)
end


function test.get_sorted_unique_fns(t)
    for _, ori_fns, expected, desc in t:case_iter(2, {
        {{                         },  {}                },
        {{'a', 'a'                 },  {'a'}             },
        {{'a', 'a', 'c', 'b'       },  {'a', 'b', 'c'}   },
        {{'测试', '测试', 'c', 'b' },  {'b', 'c', '测试'}},
    }) do

        local r, err, errmsg = fsutil.get_sorted_unique_fns(ori_fns)
        t:eq(nil, err, desc)
        t:eq(nil, errmsg, desc)
        t:eqdict(expected, r, desc)
    end
end
