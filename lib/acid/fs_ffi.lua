local ffi = require('ffi')
local fs_ffi_cdef = require('acid.fs_ffi_cdef')
local util = require('acid.util')


ffi.cdef(fs_ffi_cdef.cdef)


local _M = {
    F_OK = 0,
    X_OK = 1,
    W_OK = 2,
    R_OK = 4,

    -- d_type
    DT_UNKNOWN = 0,
    DT_FIFO = 1,
    DT_CHR = 2,
    DT_DIR = 4,
    DT_BLK = 6,
    DT_REG = 8,
    DT_LNK = 10,
    DT_SOCK = 12,
    DT_WHT = 14,

    -- st_mode:
    S_IFMT = tonumber(0170000, 8),
    S_IFSOCK = tonumber(0140000, 8),
    S_IFLNK = tonumber(0120000, 8),
    S_IFREG = tonumber(0100000, 8),
    S_IFBLK = tonumber(0060000, 8),
    S_IFDIR = tonumber(0040000, 8),
    S_IFCHR = tonumber(0020000, 8),
    S_IFIFO = tonumber(0010000, 8),
    S_ISUID = tonumber(0004000, 8),
    S_ISGID = tonumber(0002000, 8),
    S_ISVTX = tonumber(0001000, 8),

    S_IRWXU = tonumber('00700', 8),
    S_IRUSR = tonumber('00400', 8),
    S_IWUSR = tonumber('00200', 8),
    S_IXUSR = tonumber('00100', 8),

    S_IRWXG = tonumber('00070', 8),
    S_IRGRP = tonumber('00040', 8),
    S_IWGRP = tonumber('00020', 8),
    S_IXGRP = tonumber('00010', 8),

    S_IRWXO = tonumber('00007', 8),
    S_IROTH = tonumber('00004', 8),
    S_IWOTH = tonumber('00002', 8),
    S_IXOTH = tonumber('00001', 8),

    -- oflag
    O_RDONLY = tonumber('00000000', 8),
    O_WRONLY = tonumber('00000001', 8),
    O_RDWR = tonumber('00000002', 8),
    O_CREAT = tonumber('00000100', 8),
    O_EXCL = tonumber('00000200', 8),
    O_TRUNC = tonumber('00001000', 8),
    O_APPEND = tonumber('00002000', 8),
    O_NONBLOCK = tonumber('00004000', 8),
    O_DSYNC = tonumber('00010000', 8),
    O_SYNC = tonumber('04010000', 8),
    O_DIRECT = tonumber('00040000', 8),
    O_DIRECTORY = tonumber('00200000', 8),
    O_CLOEXEC = tonumber('02000000', 8),

    -- whence
    SEEK_SET = 0,
    SEEK_CUR = 1,
    SEEK_END = 2,
}

local mt = { __index = _M }

local fhandle_t = ffi.metatype("fhandle_t", {})


function _M.stat(path)
    local buf = ffi.new('struct stat')

    local ret = ffi.C.__xstat(1, path, buf)
    if ret < 0 then
        return nil, 'StatFileError', util.strerror(ffi.errno())
    end

    local file_stat = {
        st_dev = tonumber(buf.st_dev),
        st_ino = tonumber(buf.st_ino),
        st_nlink = tonumber(buf.st_nlink),
        st_mode = tonumber(buf.st_mode),
        st_uid = tonumber(buf.st_uid),
        st_gid = tonumber(buf.st_gid),
        st_rdev = tonumber(buf.st_rdev),
        st_size = tonumber(buf.st_size),
        st_blksize = tonumber(buf.st_blksize),
        st_blocks = tonumber(buf.st_blocks),
        st_atim = {
            tv_sec = tonumber(buf.st_atim.tv_sec),
            tv_nsec = tonumber(buf.st_atim.tv_nsec),
        },
        st_mtim = {
            tv_sec = tonumber(buf.st_mtim.tv_sec),
            tv_nsec = tonumber(buf.st_mtim.tv_nsec),
        },
        st_ctim = {
            tv_sec = tonumber(buf.st_ctim.tv_sec),
            tv_nsec = tonumber(buf.st_ctim.tv_nsec),
        },
    }

    return file_stat, nil, nil
end


function _M.access(path, amode)
    local ret = ffi.C.access(path, amode)
    if ret < 0 then
        return nil, 'AccessFileError', util.strerror(ffi.errno())
    end

    return true, nil, nil
end


function _M.readdir(path)
    local dirp = ffi.C.opendir(path)
    if dirp == nil then
        return nil, 'OpendirError', util.strerror(ffi.errno())
    end

    local entries = {}

    while true  do
        ffi.C.errno = 0
        local dir_entry = ffi.C.readdir(dirp)
        if dir_entry == nil then
            if ffi.errno() ~= 0 then
                ffi.C.closedir(dirp)
                return nil, 'ReaddirError', util.strerror(ffi.errno())
            end
            break
        end

        local entry = {
            d_ino = tonumber(dir_entry.d_ino),
            d_off = tonumber(dir_entry.d_off),
            d_reclen = tonumber(dir_entry.d_reclen),
            d_type = tonumber(dir_entry.d_type),
            d_name = ffi.string(dir_entry.d_name),
        }

        table.insert(entries, entry)
    end

    local ret = ffi.C.closedir(dirp)
    if ret < 0 then
        return nil, 'ClosedirError', util.strerror(ffi.errno())
    end

    return entries, nil, nil
end


function _M.mkdir(path, mode)
    local ret = ffi.C.mkdir(path, mode)
    if ret < 0 then
        return nil, 'MkdirError', util.strerror(ffi.errno())
    end

    return true, nil, nil
end


function _M.chmod(path, mode)
    local ret = ffi.C.chmod(path, mode)
    if ret < 0 then
        return nil, 'ChmodError', util.strerror(ffi.errno())
    end

    return true, nil, nil
end


function _M.chown(path, uid, gid)
    local ret = ffi.C.chown(path, uid, gid)
    if ret < 0 then
        return nil, 'ChownError', util.strerror(ffi.errno())
    end

    return true, nil, nil
end


function _M.link(old_path, new_path)

    local ret = ffi.C.link(old_path, new_path)
    if ret < 0 then
        return nil, 'LinkError', util.strerror(ffi.errno())
    end

    return nil, nil, nil
end


local function close_fhandle(fhandle)

    if fhandle.fd == -1 then
        return nil, nil, nil
    end

    local res = ffi.C.close(fhandle.fd)
    if res < 0 then
        return nil, 'CloseFileError', util.strerror(ffi.errno())
    end

    fhandle.fd = -1

    return nil, nil, nil
end


function _M.open(fpath, flags, mode)
    -- if O_CREAT is not specified, then mode is ignored.
    flags = flags or 0
    mode = mode or tonumber('00660', 8)

    ffi.C.umask(000)

    local fd = ffi.C.open(fpath, flags, mode)
    if fd < 0 then
        return nil, 'OpenFileError', util.strerror(ffi.errno())
    end

    local f = {
        fpath = fpath,
        flags = flags,
        mode = mode,
        fhandle = ffi.gc(fhandle_t(fd), close_fhandle),
    }

    return setmetatable(f, mt), nil, nil
end


function _M.close(self)
    return close_fhandle(self.fhandle)
end


function _M.write(self, data, opts)
    opts = opts or {}
    local retry = opts.retry == true
    local max_try_n = opts.max_try_n or 3

    local total_size = #data

    for _ = 1, max_try_n do
        local written = ffi.C.write(self.fhandle.fd, data, #data)
        written = tonumber(written)

        if not retry then
            if written < 0 then
                return nil, 'WriteFileError', util.strerror(ffi.errno())
            end
           return written, nil, nil
        end

        if written < 0 then
            return nil, 'WriteFileError', util.strerror(ffi.errno())
        end

        data = string.sub(data, written + 1)

        if #data == 0 then
            return total_size, nil, nil
        end

        if opts.retry_sleep_time ~= nil then
            ngx.sleep(opts.retry_sleep_time)
        end
    end

    return nil, 'WriteFileError', string.format(
            'failed to write all %d bytes in %d write, remain %d bytes',
            total_size, max_try_n, #data)
end


function _M.pwrite(self, data, offset)
    local written = ffi.C.pwrite(self.fhandle.fd, data, #data, offset)
    written = tonumber(written)

    if written < 0 then
        return nil, 'WriteFileError', util.strerror(ffi.errno())
    end

    return written, nil, nil
end


function _M.fsync(self)
    local res = ffi.C.fsync(self.fhandle.fd)
    if res < 0 then
        return nil, 'FileSyncError', util.strerror(ffi.errno())
    end

    return nil, nil, nil
end


function _M.fdatasync(self)
    local res = ffi.C.fdatasync(self.fhandle.fd)
    if res < 0 then
        return nil, 'FileDataSyncError', util.strerror(ffi.errno())
    end

    return nil, nil, nil
end


function _M.read(self, size, opts)
    opts = opts or {}
    local retry = opts.retry == true
    local max_try_n = opts.max_try_n or 3

    local buf = ffi.new("char[?]", size)
    local bufs = {}
    local to_read = size
    local reached_end = false

    for _ = 1, max_try_n do
        local read = ffi.C.read(self.fhandle.fd, buf, to_read)
        read = tonumber(read)

        if not retry then
            if read < 0 then
                return nil, 'ReadFileError', util.strerror(ffi.errno())
            end
            return ffi.string(buf, read), nil, nil
        end

        if read < 0 then
            return nil, 'ReadFileError', util.strerror(ffi.errno())
        end

        if read == 0 then
            reached_end = true
            break
        end

        table.insert(bufs, ffi.string(buf, read))

        to_read = to_read - read

        if to_read == 0 then
            break
        end

        if opts.retry_sleep_time ~= nil then
            ngx.sleep(opts.retry_sleep_time)
        end
    end

    local all_read = table.concat(bufs)
    if reached_end or #all_read == size then
        return all_read, nil, nil
    end

    return nil, 'ReadFileError', string.format(
            'failed to read %d bytes in %d read, remain %d bytes to read',
            size, max_try_n, to_read)
end


function _M.pread(self, size, offset)
    local buf = ffi.new("char[?]", size)

    local read = ffi.C.pread(self.fhandle.fd, buf, size, offset)
    read = tonumber(read)

    if read < 0 then
        return nil, 'ReadFileError', util.strerror(ffi.errno())
    end

    return ffi.string(buf, read), nil, nil
end


function _M.seek(self, offset, whence)
    local off = ffi.C.lseek(self.fhandle.fd, offset, whence)
    off = tonumber(off)

    if off < 0 then
        return nil, 'SeekError', util.strerror(ffi.errno())
    end

    return off, nil, nil
end


return _M
