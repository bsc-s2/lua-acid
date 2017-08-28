local libluafs = require( "libluafs" )
local strutil = require("acid.strutil")

math.randomseed(ngx.now()*1000)

local _M = {}


function _M.read_dir( name )

    local ds
    local dirs = {}

    if not libluafs.is_dir(name) then
        return nil, 'PathError', name .. "is not a dir"
    end

    ds = libluafs.readdir( name )
    if ds == nil then
        return nil, 'FileError', "can't read " .. name .. " dir"
    end

    for i = 0, ds.n do
        name = ds[i]
        if name ~= '.' and name ~= '..' then
            table.insert( dirs, name )
        end
    end

    return dirs, nil, nil

end


function _M.is_dir(path)
    return libluafs.is_dir(path)
end


function _M.is_file(path)
    return libluafs.is_file(path)
end


function _M.is_exist(path)
    return libluafs.is_exist(path)
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


function _M.rm_file( path )
    local rst, err = os.remove( path )
    if err ~= nil then
        return nil, 'RemoveError', err
    end
    return rst, nil, nil
end


function _M.make_dir( path, mode, uid, gid )
    local rst, err_msg

    rst, err_msg = libluafs.makedir( path, mode or 0755 )

    if not rst and not libluafs.is_dir( path ) then

        err_msg = string.format( 'make dir %s error:%s',
                path, err_msg )

        return nil, 'FileError', err_msg
    end

    if uid ~= nil and gid ~= nil then

        rst, err_msg = libluafs.chown( path, uid, gid )
        if not rst then
            return nil, 'FileError', err_msg
        end

    end

    return nil, nil, nil
end


function _M.atomic_write( fpath, data, mode )
    local tmp_fpath = fpath .. '._tmp_.'
            .. math.random(10000).. ngx.md5(data)

    local rst, err_code, err_msg = _M.write( tmp_fpath, data, mode )
    if err_code ~= nil then
        os.remove(tmp_fpath)
        return nil, err_code, err_msg
    end

    local _, err_msg = os.rename( tmp_fpath, fpath )
    if err_msg ~= nil then
        os.remove(tmp_fpath)
        return nil, 'FileError', err_msg
    end

    return rst, nil, nil
end


function _M.write( fpath, data, mode )
    local fp
    local rst
    local err_msg

    fp, err_msg = io.open( fpath, mode or 'w' )
    if fp == nil then
        return nil, 'FileError', err_msg
    end

    rst, err_msg = fp:write( data )
    if rst == nil then
        fp:close()
        return nil, 'FileError', err_msg
    end

    fp:close()

    return #data, nil, nil
end


function _M.read( fpath, mode )
    local fp
    local data
    local err_msg

    fp, err_msg = io.open( fpath , mode or 'r' )
    if fp == nil then
        return nil, 'FileError', err_msg
    end

    -- '*a' means read the whole file
    data = fp:read( '*a' )
    fp:close()

    if data == nil then
        return nil, 'FileError',
            'read data error,file path:' .. fpath
    end

    return data, nil, nil
end


function _M.rm_tree(path, opts)
    opts = opts or {}

    local names
    local fullname
    local _
    local err_code, err_msg

    names, err_code, err_msg = _M.read_dir( path )
    if err_code ~= nil then
        return nil, err_code, err_msg
    end

    for _, name in ipairs(names) do

        fullname = path .. '/' .. name

        if _M.is_dir(fullname) then

            _, err_code, err_msg = _M.rm_tree(fullname)
            if err_code ~= nil then
                return nil, err_code, err_msg
            end

        else

            _, err_msg = _M.rm_file(fullname)
            if err_msg ~= nil then
                return nil, 'FileError', err_msg
            end

        end

    end

    if opts.keep_root == true then
        return nil, nil, nil
    end

    _, err_msg = libluafs.rmdir(path)
    if err_msg ~= nil then
        return nil, 'FileError', err_msg
    end

    return nil, nil, nil

end


function _M.base_path(path)
    local elts = strutil.rsplit(path, '/', {maxsplit=1} )
    if #elts == 1 then
        return ''
    end

    if elts[1] == '' then
        return '/'
    end

    return elts[1]
end


function _M.make_dirs(path, mode, uid, gid)
    local _
    local err_code, err_msg

    if path == '' then
        return nil, nil, nil
    end

    if _M.is_dir(path) then
        return nil, nil, nil
    end

    _, err_code, err_msg = _M.make_dirs( _M.base_path(path), mode, uid, gid )
    if err_code ~= nil then
        return nil, err_code, err_msg
    end

    _, err_code, err_msg = _M.make_dir( path, mode, uid, gid )
    if err_code ~= nil then
        return nil, err_code, err_msg
    end

    return nil, nil, nil
end


function _M.file_size( fn )
    local info, err_msg = libluafs.stat( fn )
    if info == nil then
        return nil, 'FileError', err_msg
    end

    return tonumber(info.size)
end


return _M
