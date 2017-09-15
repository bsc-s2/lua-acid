local fs_ffi = require('acid.fs_ffi')

math.randomseed(ngx.now() * 1000)


local function get_random_str()
    return tostring(math.random(10000, 99999))
end


function test.stat(t)
    local _, err, errmsg = fs_ffi.stat('not_exist_file')
    test.dd(err)
    test.dd(errmsg)
    t:neq(nil, err)
    t:neq(nil, errmsg)

    local file_stat, err, errmsg = fs_ffi.stat('/')
    test.dd(file_stat)
    t:eq(nil, err, errmsg)

    t:eq('number', type(file_stat.st_dev))
    t:eq('number', type(file_stat.st_ino))
    t:eq('number', type(file_stat.st_nlink))
    t:eq('number', type(file_stat.st_mode))
    t:eq('number', type(file_stat.st_uid))
    t:eq('number', type(file_stat.st_gid))
    t:eq('number', type(file_stat.st_rdev))
    t:eq('number', type(file_stat.st_size))
    t:eq('number', type(file_stat.st_blksize))
    t:eq('number', type(file_stat.st_blocks))
    t:eq('table', type(file_stat.st_atim))
    t:eq('table', type(file_stat.st_mtim))
    t:eq('table', type(file_stat.st_ctim))
    t:eq('number', type(file_stat.st_atim.tv_sec))
    t:eq('number', type(file_stat.st_atim.tv_nsec))
    t:eq('number', type(file_stat.st_mtim.tv_sec))
    t:eq('number', type(file_stat.st_mtim.tv_nsec))
    t:eq('number', type(file_stat.st_ctim.tv_sec))
    t:eq('number', type(file_stat.st_ctim.tv_nsec))
end


function test.access(t)
    local test_dir = '/tmp/test_file_' .. get_random_str()
    test.dd(test_dir)

    local _, err, errmsg = fs_ffi.mkdir(test_dir, tonumber('000', 8))
    t:eq(nil, err, errmsg)

    -- root always have access permissions
    local _, err, errmsg = fs_ffi.access(test_dir, fs_ffi.F_OK)
    t:eq(nil, err, errmsg)

    local _, err, errmsg = fs_ffi.access(test_dir, fs_ffi.X_OK)
    t:eq(nil, err, errmsg)

    local _, err, errmsg = fs_ffi.access(test_dir, fs_ffi.R_OK)
    t:eq(nil, err, errmsg)

    local _, err, errmsg = fs_ffi.access(test_dir, fs_ffi.W_OK)
    t:eq(nil, err, errmsg)

    local _, err, errmsg = fs_ffi.access('not_exist_file', 0)
    test.dd(err)
    test.dd(errmsg)
    t:neq(nil, err)
    t:neq(nil, errmsg)
end


function test.readdir(t)
    local _, err, errmsg = fs_ffi.readdir('not_exist_dir')
    test.dd(err)
    test.dd(errmsg)
    t:neq(nil, err)
    t:neq(nil, errmsg)

    local entries, err, errmsg = fs_ffi.readdir('/')
    t:eq(nil, err, errmsg)

    local entry = entries[3]
    test.dd(entry)

    t:eq('number', type(entry.d_ino))
    t:eq('number', type(entry.d_off))
    t:eq('number', type(entry.d_reclen))
    t:eq('number', type(entry.d_type))
    t:eq('string', type(entry.d_name))
end


function test.mkdir(t)
    local _, err, errmsg = fs_ffi.mkdir('/not_exist_dir/test_dir',
                                        tonumber('0755', 8))
    test.dd(err)
    test.dd(errmsg)
    t:neq(nil, err)
    t:neq(nil, errmsg)
end


function test.chmod(t)
    local _, err, errmsg = fs_ffi.chmod('/not_exist_dir',
                                        tonumber('0755', 8))
    test.dd(err)
    test.dd(errmsg)
    t:neq(nil, err)
    t:neq(nil, errmsg)
end


function test.chown(t)
    local _, err, errmsg = fs_ffi.chown('/not_exist_dir', 0, 0)
    test.dd(err)
    test.dd(errmsg)
    t:neq(nil, err)
    t:neq(nil, errmsg)
end
