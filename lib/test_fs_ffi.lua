local bit = require('bit')
local fs_ffi = require('acid.fs_ffi')
local fsutil = require('acid.fsutil')
local time = require('acid.time')

math.randomseed(ngx.now() * 1000)


local function get_random_str()
    return tostring(math.random(10000, 99999))
end


local function get_test_path()
    return '/tmp/test_fs_ffi_path_' .. get_random_str()
end


local function read_file(t, path)
    local f, err = io.open(path, 'r')
    t:eq(nil, err)

    local data = f:read('*a')
    f:close()

    return data
end


local function write_file(t, path, data)
    local f, err = io.open(path, 'wb')
    t:eq(nil, err)
    f:write(data)
    f:close()

    t:eq(data, read_file(t, path))
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


function test.link(t)
    local test_path = get_test_path()
    test.dd(test_path)

    write_file(t, test_path, 'foo')

    local link_path = test_path .. '_link'
    test.dd(link_path)

    local _, err, errmsg = fs_ffi.link(test_path, link_path)
    t:eq(nil, err, errmsg)

    t:eq('foo', read_file(t, link_path))
end


function test.open(t)
    local test_path = get_test_path()
    test.dd(test_path)
    local fd, err, errmsg = fs_ffi.open(test_path)
    test.dd(err)
    test.dd(errmsg)
    t:eq(nil, fd)
    t:neq(nil, err)

    local file, err, errmsg = fs_ffi.open(test_path, fs_ffi.O_CREAT)
    test.dd(file)
    t:eq(nil, err, errmsg)

    local file, err, errmsg = fs_ffi.open(test_path)
    test.dd(file)
    t:eq(nil, err, errmsg)

    os.remove(test_path)
end


function test.open_with_mode(t)
    local mode_mask = bit.bor(fs_ffi.S_IRWXU,
                              fs_ffi.S_IRWXG,
                              fs_ffi.S_IRWXO)

    for _, mode, desc in t:case_iter(1, {
        { bit.bor(fs_ffi.S_IRWXU, fs_ffi.S_IRWXG, fs_ffi.S_IRWXO) },
        { bit.bor(fs_ffi.S_IRUSR, fs_ffi.S_IRGRP, fs_ffi.S_IROTH) },
        { bit.bor(fs_ffi.S_IWUSR, fs_ffi.S_IWGRP, fs_ffi.S_IWOTH) },
        { bit.bor(fs_ffi.S_IXUSR, fs_ffi.S_IXGRP, fs_ffi.S_IXOTH) },

        { fs_ffi.S_IRWXU },
        { fs_ffi.S_IRUSR },
        { fs_ffi.S_IWUSR },
        { fs_ffi.S_IWUSR },

        { fs_ffi.S_IRWXG },
        { fs_ffi.S_IRGRP },
        { fs_ffi.S_IWGRP },
        { fs_ffi.S_IXGRP },

        { fs_ffi.S_IRWXO },
        { fs_ffi.S_IROTH },
        { fs_ffi.S_IWOTH },
        { fs_ffi.S_IXOTH },
    }) do

        local test_path = get_test_path()
        test.dd(test_path)
        local _, err, errmsg = fs_ffi.open(test_path, fs_ffi.O_CREAT, mode)
        t:eq(nil, err, errmsg)

        local file_stat, err, errmsg = fs_ffi.stat(test_path)
        t:eq(nil, err, errmsg)

        t:eq(mode, bit.band(file_stat.st_mode, mode_mask), desc)

        os.remove(test_path)
    end
end


function test.open_with_oflag(t)
    local test_path = get_test_path()
    test.dd(test_path)
    local f, err = io.open(test_path, 'w')
    t:eq(nil, err)
    f:write('abc')
    f:close()

    -- RDONLY
    local file, err, errmsg = fs_ffi.open(test_path, fs_ffi.O_RDONLY)
    t:eq(nil, err, errmsg)

    local data, err, errmsg = file:read(1)
    t:eq(nil, err, errmsg)
    t:eq('a', data)

    local _, err, errmsg = file:write('foo')
    test.dd(err)
    test.dd(errmsg)
    t:neq(nil, err)
    t:neq(nil, errmsg)

    file:close()

    -- WRONLY
    local file, err, errmsg = fs_ffi.open(test_path, fs_ffi.O_WRONLY)
    t:eq(nil, err, errmsg)

    local _, err, errmsg = file:read(1)
    test.dd(err)
    test.dd(errmsg)
    t:neq(nil, err)
    t:neq(nil, errmsg)

    local _, err, errmsg = file:write('foo')
    t:eq(nil, err, errmsg)

    file:close()

    -- RDWR
    local file, err, errmsg = fs_ffi.open(test_path, fs_ffi.O_RDWR)
    t:eq(nil, err, errmsg)

    local data, err, errmsg = file:read(1)
    t:eq(nil, err, errmsg)
    t:eq('f', data)

    local _, err, errmsg = file:write('foo')
    t:eq(nil, err, errmsg)

    file:close()

    os.remove(test_path)
end


function test.append(t)
    local test_path = get_test_path()
    test.dd(test_path)
    local f, err = io.open(test_path, 'w')
    t:eq(nil, err)
    f:write('foo')
    f:close()

    local oflag = bit.bor(fs_ffi.O_WRONLY, fs_ffi.O_APPEND)
    local file, err, errmsg = fs_ffi.open(test_path, oflag)
    t:eq(nil, err, errmsg)

    local n, err, errmsg = file:write('bar')
    t:eq(nil, err, errmsg)
    t:eq(3, n)
    file:close()

    local f, err = io.open(test_path, 'r')
    t:eq(nil, err)
    local data = f:read('*a')
    t:eq('foobar', data)

    os.remove(test_path)
end


function test.EXCL(t)
    local test_path = get_test_path()
    test.dd(test_path)
    local f, err = io.open(test_path, 'w')
    t:eq(nil, err)
    f:close()

    local oflag = bit.bor(fs_ffi.O_CREAT, fs_ffi.O_EXCL)
    local _, err, errmsg = fs_ffi.open(test_path, oflag)
    test.dd(err)
    test.dd(errmsg)
    t:neq(nil, err)
    t:neq(nil, errmsg)

    os.remove(test_path)
end


function test.truncate(t)
    for _, ori_data, oflag, new_data, r_size, r_data, desc in t:case_iter(5, {
        {'abcd', 0,              'foo', 4, 'food' },
        {'abcd', fs_ffi.O_TRUNC, 'foo', 3, 'foo'  },
    }) do
        local test_path = get_test_path()
        test.dd(test_path)

        write_file(t, test_path, ori_data)

        local oflag_to_use = bit.bor(fs_ffi.O_WRONLY, oflag)
        local file, err, errmsg = fs_ffi.open(test_path, oflag_to_use)
        t:eq(nil, err, errmsg)

        local n, err, errmsg = file:write(new_data)
        t:eq(nil, err, errmsg)
        t:eq(#new_data, n, desc)
        file:close()

        local file_stat, err, errmsg = fs_ffi.stat(test_path)
        t:eq(nil, err, errmsg)
        t:eq(r_size, file_stat.st_size, desc)

        test.dd(#read_file(t, test_path))
        t:eq(r_data, read_file(t, test_path), desc)

        os.remove(test_path)
    end
end


function test.sync_flag(t)
    local buf = string.rep('0', 1024 * 1024 * 10)

    local times = {}

    for _, tag, oflag, desc in t:case_iter(2, {
        {'no_integrity',   0              },
        {'file_integrity', fs_ffi.O_SYNC  },
        {'data_integrity', fs_ffi.O_DSYNC },
    }) do

        local test_path = get_test_path()
        test.dd(test_path)

        local oflag_to_use = bit.bor(fs_ffi.O_CREAT, fs_ffi.O_RDWR, oflag)
        local file, err, errmsg = fs_ffi.open(test_path, oflag_to_use)
        t:eq(nil, err, errmsg)

        local start_time = time.get_ms()

        local n, err, errmsg = file:write(buf)

        local end_time = time.get_ms()
        times[tag] = end_time - start_time

        t:eq(nil, err, errmsg)
        t:eq(#buf, n, desc)

        file:close()
        os.remove(test_path)
    end

    test.dd(times)
    t:eq(true, times.no_integrity < times.file_integrity / 2)
    t:eq(true, times.no_integrity < times.data_integrity / 2)
end


function test.read(t)
    local test_path = get_test_path()
    test.dd(test_path)
    write_file(t, test_path, '12345')

    local file, err, errmsg = fs_ffi.open(test_path, fs_ffi.O_RDONLY)
    t:eq(nil, err, errmsg)

    local data, err, errmsg = file:read(3)
    t:eq(nil, err, errmsg)
    t:eq('123', data)

    local data, err, errmsg = file:read(3)
    t:eq(nil, err, errmsg)
    t:eq('45', data)

    local data, err, errmsg = file:read(3)
    t:eq(nil, err, errmsg)
    t:eq('', data)

    os.remove(test_path)
end


function test.pread(t)
    local test_path = get_test_path()
    test.dd(test_path)
    write_file(t, test_path, '12345')

    local file, err, errmsg = fs_ffi.open(test_path, fs_ffi.O_RDONLY)
    t:eq(nil, err, errmsg)

    local data, err, errmsg = file:pread(3, 2)
    t:eq(nil, err, errmsg)
    t:eq('345', data)

    local data, err, errmsg = file:pread(3, 2)
    t:eq(nil, err, errmsg)
    t:eq('345', data)

    local data, err, errmsg = file:pread(4, 2)
    t:eq(nil, err, errmsg)
    t:eq('345', data)

    local data, err, errmsg = file:pread(4, 5)
    t:eq(nil, err, errmsg)
    t:eq('', data)

    os.remove(test_path)
end


function test.pwrite(t)
    local test_path = get_test_path()
    test.dd(test_path)

    local oflag = bit.bor(fs_ffi.O_CREAT, fs_ffi.O_WRONLY, fs_ffi.O_SYNC)

    local file, err, errmsg = fs_ffi.open(test_path, oflag)
    t:eq(nil, err, errmsg)

    local n, err, errmsg = file:pwrite('foo', 1)
    t:eq(nil, err, errmsg)
    t:eq(3, n)

    local n, err, errmsg = file:pwrite('fo', 5)
    t:eq(nil, err, errmsg)
    t:eq(2, n)

    local n, err, errmsg = file:pwrite('bar', 6)
    t:eq(nil, err, errmsg)
    t:eq(3, n)

    local data = read_file(t, test_path)
    test.dd(data)
    t:eq('\0foo\0fbar', data)

    local n, err, errmsg = file:pwrite('', 1024 * 1024)
    t:eq(nil, err, errmsg)
    t:eq(0, n)

    local file_stat, err, errmsg = fs_ffi.stat(test_path)
    t:eq(nil, err, errmsg)
    t:eq(9, file_stat.st_size)

    local n, err, errmsg = file:pwrite('0', 1024 * 1024)
    t:eq(nil, err, errmsg)
    t:eq(1, n)

    local file_stat, err, errmsg = fs_ffi.stat(test_path)
    t:eq(nil, err, errmsg)
    t:eq(1024 * 1024 + 1, file_stat.st_size)

    os.remove(test_path)
end


function test.fsync(t)
    local test_path = get_test_path()
    test.dd(test_path)

    local buf = string.rep('0', 1024 * 1024 * 20)

    local oflag = bit.bor(fs_ffi.O_CREAT, fs_ffi.O_WRONLY)

    local file, err, errmsg = fs_ffi.open(test_path, oflag)
    t:eq(nil, err, errmsg)

    local start_time = time.get_ms()
    local _, err, errmsg = file:write(buf)
    local write_time = time.get_ms() - start_time
    test.dd(write_time)
    t:eq(nil, err, errmsg)

    local start_time = time.get_ms()
    local _, err, errmsg = file:fsync()
    local sync_time = time.get_ms() - start_time
    test.dd(sync_time)
    t:eq(nil, err, errmsg)

    t:eq(true, sync_time > write_time * 10)

    os.remove(test_path)
end


function test.fdatasync(t)
    local test_path = get_test_path()
    test.dd(test_path)

    local buf = string.rep('0', 1024 * 1024 * 20)

    local oflag = bit.bor(fs_ffi.O_CREAT, fs_ffi.O_WRONLY)

    local file, err, errmsg = fs_ffi.open(test_path, oflag)
    t:eq(nil, err, errmsg)

    local start_time = time.get_ms()
    local _, err, errmsg = file:write(buf)
    local write_time = time.get_ms() - start_time
    test.dd(write_time)
    t:eq(nil, err, errmsg)

    local start_time = time.get_ms()
    local _, err, errmsg = file:fdatasync()
    local sync_time = time.get_ms() - start_time
    test.dd(sync_time)
    t:eq(nil, err, errmsg)

    t:eq(true, sync_time > write_time * 2)

    os.remove(test_path)
end


function test.seek(t)
    local test_path = get_test_path()
    test.dd(test_path)
    write_file(t, test_path, '12345')

    for _, offset, whence, r_offset, data, desc in t:case_iter(4, {
        {0, fs_ffi.SEEK_SET, 0, '1'  },
        {1, fs_ffi.SEEK_SET, 1, '2'  },
        {6, fs_ffi.SEEK_SET, 6, ''   },
        {0, fs_ffi.SEEK_CUR, 0, '1'  },
        {2, fs_ffi.SEEK_CUR, 2, '3'  },
        {6, fs_ffi.SEEK_CUR, 6, ''   },
        {0, fs_ffi.SEEK_END, 5, ''   },
        {-1, fs_ffi.SEEK_END, 4, '5' },
        {-5, fs_ffi.SEEK_END, 0, '1' },
    }) do
        local file, err, errmsg = fs_ffi.open(test_path, fs_ffi.O_RDONLY)
        t:eq(nil, err, errmsg)

        local r, err, errmsg = file:seek(offset, whence)
        t:eq(nil, err, errmsg)
        t:eq(r_offset, r, desc)

        local data_read, err, errmsg = file:read(1)
        t:eq(nil, err, errmsg)
        t:eq(data, data_read, desc)
    end

    os.remove(test_path)
end


function test.close(t)
    local test_path = get_test_path()
    test.dd(test_path)
    local file, err, errmsg = fs_ffi.open(test_path, fs_ffi.O_CREAT)
    t:eq(nil, err, errmsg)
    t:neq(-1, file.fhandle.fd)

    local _, err, errmsg = file:close()
    t:eq(nil, err, errmsg)
    t:eq(-1, file.fhandle.fd)

    local _, err, errmsg = file:close()
    t:eq(nil, err, errmsg)
    t:eq(-1, file.fhandle.fd)

    os.remove(test_path)
end


function test.close_by_collectgarbage(t)
    local test_path = get_test_path()
    test.dd(test_path)

    local file, err, errmsg = fs_ffi.open(test_path, fs_ffi.O_CREAT)
    t:eq(nil, err, errmsg)
    t:neq(-1, file.fhandle.fd)

    local fd = file.fhandle.fd
    local r = os.execute('ls /proc/self/fd/' .. fd)
    t:eq(true, r)

    file = nil

    local r = os.execute('ls /proc/self/fd/' .. fd)
    t:eq(true, r)

    collectgarbage('collect')

    local r = os.execute('ls /proc/self/fd/' .. fd)
    t:eq(nil, r)

    os.remove(test_path)
end


local function run_command(t, command, log)
    if log then
        ngx.log(ngx.INFO, 'run command: ' .. command)
    else
        test.dd(command)
    end

    local r = os.execute(command)

    if log then
        ngx.log(ngx.INFO, 'run command result: ' .. tostring(r))
    else
        test.dd(r)
    end

    t:eq(true, r)
end


local function setup_loop_dev(t)
    local dev = {}
    local random_str = get_random_str()
    dev.loop_dev = '/dev/loop' .. random_str
    dev.mount_point = '/tmp/test_mount_point_' .. random_str
    dev.block_file = '/tmp/test_block_file_' .. random_str

    local _, err, errmsg = fsutil.make_dir(dev.mount_point)
    t:eq(nil, err, errmsg)

    local cmd = string.format('/usr/bin/dd if=/dev/zero of=%s bs=1M count=9',
                              dev.block_file)
    run_command(t, cmd)

    local cmd = string.format('/usr/sbin/losetup %s %s',
                              dev.loop_dev, dev.block_file)
    run_command(t, cmd)

    local cmd = string.format('/usr/sbin/mkfs -t ext4 %s', dev.loop_dev)
    run_command(t, cmd)

    local cmd = string.format('/usr/bin/mount -t ext4 %s %s',
                              dev.loop_dev, dev.mount_point)
    run_command(t, cmd)

    return dev
end


local function clean_loop_dev(t, dev)
    local cmd = string.format('/usr/bin/umount %s', dev.mount_point)
    run_command(t, cmd)

    local cmd = string.format('/usr/sbin/losetup -d %s', dev.loop_dev)
    run_command(t, cmd)

    local cmd = string.format('/usr/bin/rm -rf %s', dev.mount_point)
    run_command(t, cmd)

    os.remove(dev.block_file)
end


local function remove_filling_file(premature, t, mount_point)
    if premature then
        ngx.log(ngx.ERR, 'premature')
    end

    local cmd = string.format('rm -f $(ls %s/fill_file_* | head -n 1)',
                              mount_point)
    run_command(t, cmd, true)

    local _, err = ngx.timer.at(1, remove_filling_file, t, mount_point)
    t:eq(nil, err)
end


function test.write(t)
    local dev = setup_loop_dev(t)
    local buf = string.rep('0', 1024 * 1024)

    for i = 1, 10 do
        local file_name = dev.mount_point .. '/fill_file_' .. tostring(i)
        local oflag = bit.bor(fs_ffi.O_CREAT, fs_ffi.O_WRONLY)

        local file, err, errmsg = fs_ffi.open(file_name, oflag)
        t:eq(nil, err, errmsg)

        local n, err, errmsg = file:write(buf)
        if err ~= nil then
            test.dd(err)
            test.dd(errmsg)
            file:close()
            break
        end
        test.dd(string.format('wrote %d bytes to file: %s', n, file_name))
        file:close()
    end

    local _, err = ngx.timer.at(1, remove_filling_file, t, dev.mount_point)
    t:eq(nil, err)

    local test_file = dev.mount_point .. '/test_file'
    test.dd(test_file)

    local oflag = bit.bor(fs_ffi.O_CREAT, fs_ffi.O_WRONLY)
    local file, err, errmsg = fs_ffi.open(test_file, oflag)
    t:eq(nil, err, errmsg)

    local buf = string.rep('0', 1024 * 1024 * 5)

    local _, err, errmsg = file:write(buf, {retry=true,
                                            max_try_n=2,
                                            retry_sleep_time=1.1})
    test.dd(err)
    test.dd(errmsg)
    t:neq(nil, err)
    t:neq(nil, errmsg)

    ngx.sleep(1.1)

    local _, err, errmsg = file:write(buf, {retry=true,
                                            max_try_n=10,
                                            retry_sleep_time=1.1})
    t:eq(nil, err, errmsg)

    file:close()

    clean_loop_dev(t, dev)
end
