local bit = require('bit')
local fs_ffi = require('acid.fs_ffi')
local strutil = require('acid.strutil')
local util = require('acid.util')

local _M = {}


function _M.is_exist(path)
    local _, err, errmsg = fs_ffi.access(path, fs_ffi.F_OK)
    if err ~= nil then
        return nil, err, errmsg
    end

    return true, nil, nil
end


function _M.is_dir(path)
    local file_stat, err, errmsg = fs_ffi.stat(path)
    if err ~= nil then
        return nil, err, errmsg
    end

    if bit.band(file_stat.st_mode, fs_ffi.S_IFDIR) ~= 0 then
        return true, nil, nil
    end

    return false, nil, nil
end


function _M.is_file(path)
    local file_stat, err, errmsg = fs_ffi.stat(path)
    if err ~= nil then
        return nil, err, errmsg
    end

    if bit.band(file_stat.st_mode, fs_ffi.S_IFREG) ~= 0 then
        return true, nil, nil
    end

    return false, nil, nil
end


function _M.read_dir(path)
    if not _M.is_dir(path) then
        return nil, 'PathTypeError', 'path is not a directory'
    end

    local entries, err, errmsg = fs_ffi.readdir(path)
    if err ~= nil then
        return nil, err, errmsg
    end

    local entry_names = {}
    for _, entry in ipairs(entries) do
        local name = entry.d_name

        if name ~= '.' and name ~= '..' then
            table.insert(entry_names, name)
        end
    end

    return entry_names, nil, nil
end


function _M.make_dir(path, mode, name_or_uid, name_or_gid)
    mode = mode or tonumber('755', 8)

    local uid
    local gid

    if name_or_uid ~= nil then
        local user, err, errmsg = util.get_user(name_or_uid)
        if err ~= nil then
            return nil, 'GetUserError', string.format(
                    'failed to get user: %s, %s, %s',
                    tostring(name_or_uid), err, errmsg)
        end
        uid = user.pw_uid
    end

    if name_or_gid ~= nil then
        local group, err, errmsg = util.get_group(name_or_gid)
        if err ~= nil then
            return nil, 'GetGroupError', string.format(
                    'failed to get group: %s, %s, %s',
                    tostring(name_or_gid), err, errmsg)
        end
        gid = group.gr_gid
    end

    if not _M.is_exist(path) then
        local _, err, errmsg = fs_ffi.mkdir(path, mode)
        if err ~= nil then
            return nil, 'MkdirError', string.format(
                    'failed to make dir: %s, %s, %s',
                    path, err, errmsg)
        end
    else
        if not _M.is_dir(path) then
            return nil, 'PathExistError', string.format(
                    'path: %s exist, and is not directory', path)
        end
        if mode ~= nil then
            local _, err, errmsg = fs_ffi.chmod(path, mode)
            if err ~= nil then
                return nil, 'ChmodError', string.format(
                        'failed to chmod dir: %s, %s, %s',
                        path, err, errmsg)
            end
        end
    end

    if uid == nil or gid == nil then
        return true, nil, nil
    end

    local _, err, errmsg = fs_ffi.chown(path, uid, gid)
    if err ~= nil then
        return nil, 'ChownError', string.format(
                'failed to chown dir: %s, %s, %s',
                path, err, errmsg)
    end

    return true, nil, nil
end


function _M.base_path(path)
    local elts = strutil.rsplit(path, '/', {maxsplit=1})
    if #elts == 1 then
        return ''
    end

    if elts[1] == '' then
        return '/'
    end

    return elts[1]
end


function _M.make_dirs(path, mode, name_or_uid, name_or_gid)
    if path == '' then
        return true, nil, nil
    end

    if _M.is_exist(path) and _M.is_dir(path) then
        return true, nil, nil
    end

    local _, err, errmsg = _M.make_dirs(_M.base_path(path), mode,
                                        name_or_uid, name_or_gid)
    if err ~= nil then
        return nil, err, errmsg
    end

    local _, err, errmsg = _M.make_dir(path, mode, name_or_uid, name_or_gid)
    if err ~= nil then
        return nil, err, errmsg
    end

    return true, nil, nil
end


function _M.remove_one_entry(entry, base_path)
    local name = entry.d_name
    if name == '.' or name == '..' then
        return true, nil, nil
    end

    local path = base_path .. '/' .. name

    local d_type = entry.d_type

    if d_type == fs_ffi.DT_DIR then
        local _, err, errmsg = _M.remove_tree(path)
        if err ~= nil then
            return nil, err, errmsg
        end

    elseif d_type == fs_ffi.DT_REG then
        local _, err = os.remove(path)
        if err ~= nil then
            return nil, 'RemoveError', string.format(
                    'failed to remove file: %s, %s', path, err)
        end

    else
        return nil, 'InvalidFileType', string.format(
                'file: %s type is: %d, not a directory or regular file',
                path, d_type)
    end

    return true, nil, nil
end


function _M.remove_tree(path, opts)
    opts = opts or {}

    if not _M.is_exist(path) then
        return true, nil, nil
    end

    if not _M.is_dir(path) then
        return nil, 'PathError', string.format(
                'path: %s is not a directory', path)
    end

    local entries, err, errmsg = fs_ffi.readdir(path)
    if err ~= nil then
        return nil, err, errmsg
    end

    for _, entry in ipairs(entries) do
        local _, err, errmsg = _M.remove_one_entry(entry, path)
        if err ~= nil then
            return nil, err, errmsg
        end
    end

    if opts.keep_root ~= true then
        local _, err = os.remove(path)
        if err ~= nil then
            return nil, 'RemoveError', string.format(
                    'failed to remove file: %s, %s', path, err)
        end
    end

    return true, nil, nil
end


function _M.file_size(file_name)
    local file_stat, err, errmsg = fs_ffi.stat(file_name)
    if err ~= nil then
        return nil, err, errmsg
    end

    return file_stat.st_size, nil, nil
end


function _M.write(path, data, mode)
    local oflag = bit.bor(fs_ffi.O_CREAT, fs_ffi.O_TRUNC, fs_ffi.O_WRONLY)
    local file, err, errmsg = fs_ffi.open(path, oflag, mode)
    if err ~= nil then
        return nil, err, errmsg
    end

    local _, err, errmsg = file:write(data, {retry=true, max_try_n=3})
    if err ~= nil then
        file:close()
        return nil, err, errmsg
    end

    local _, err, errmsg = file:close()
    if err ~= nil then
        return nil, err, errmsg
    end

    return true, nil, nil
end


function _M.atomic_write(path, data, mode)
    local tmp_path = string.format('%s_tmp_%d_%s', path, math.random(10000),
                                   ngx.md5(data))
    local _, err, errmsg = _M.write(tmp_path, data, mode)
    if err ~= nil then
        os.remove(tmp_path)
        return nil, err, errmsg
    end

    local _, err = os.rename(tmp_path, path)
    if err ~= nil then
        os.remove(tmp_path)
        return nil, 'RenameError', err
    end

    return true, nil, nil
end


function _M.read(path)
    local bufs = {}

    local file, err, errmsg = fs_ffi.open(path, fs_ffi.O_RDONLY)
    if err ~= nil then
        return nil, err, errmsg
    end

    local read_block_size = 1024 * 1024 * 10

    while true do
        local buf, err, errmsg = file:read(read_block_size)
        if err ~= nil then
            file:close()
            return nil, err, errmsg
        end

        table.insert(bufs, buf)

        if #buf == 0 then
            break
        end
    end

    local _, err, errmsg = file:close()
    if err ~= nil then
        return nil, err, errmsg
    end

    return table.concat(bufs), nil, nil
end


function _M.get_sorted_unique_fns(origin_fns)
    local prev_fn = nil
    local fns = {}

    table.sort(origin_fns)

    for _, fn in ipairs(origin_fns) do
        if prev_fn ~= fn then
            table.insert(fns, fn)
            prev_fn = fn
        end
    end

    return fns
end


return _M
