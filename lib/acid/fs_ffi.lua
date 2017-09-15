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
}


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


return _M
