local table = require("table")
local libluafs = require( "libluafs" )
local strutil = require("acid.strutil")
local s2conf = require("s2conf")

local io = io
local os = os
local ngx = ngx
local base = _G
local math = math
local string = string

module("fs")

math.randomseed(ngx.now()*1000)

function read_dir( name )

    local ds, i, k
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

function is_dir(path)
    return libluafs.is_dir(path)
end

function is_file(path)
    return libluafs.is_file(path)
end

function is_exist(path)
    return libluafs.is_exist(path)
end

function get_sorted_unique_fns(origin_fns)
    local i, fn
    local prev_fn = nil
    local fns = {}

    table.sort(origin_fns)

    for i, fn in base.ipairs(origin_fns) do
        if prev_fn ~= fn then
            table.insert(fns, fn)
            prev_fn = fn
        end
    end

    return fns

end

function rm_file( path )
    local rst, err = os.remove( path )
    return rst, err
end

function mk_dir( path, mode, uid, gid )

    local rst, err_msg = libluafs.makedir( path, mode or 0755 )

    if not rst and not libluafs.is_dir( path ) then

        err_msg = string.format( 'make dir %s error:%s',
                path, err_msg )

        return 'FileError', err_msg
    end

    return nil, nil

end

function make_dir( path, mode, uid, gid )

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

function atomic_write( fpath, data, mode )
    local res
    local tmp_fpath
    local rst, err_code, err_msg

    tmp_fpath = fpath .. '._tmp_.'
            .. math.random(10000).. ngx.md5(data)

    rst, err_code, err_msg = write( tmp_fpath, data, mode )
    if err_code ~= nil then
        os.remove(tmp_fpath)
        return nil, err_code, err_msg
    end

    res, err_msg = os.rename( tmp_fpath, fpath )
    if err_msg ~= nil then
        os.remove(tmp_fpath)
        return nil, 'FileError', err_msg
    end

    return rst, nil, nil
end

function write( fpath, data, mode )
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

function read( fpath, mode )
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

function rm_tree(path)

    local names
    local fullname
    local _
    local err_code, err_msg

    names, err_code, err_msg = read_dir( path )
    if err_code ~= nil then
        return nil, err_code, err_msg
    end

    for _, name in base.ipairs(names) do

        fullname = path .. '/' .. name

        if is_dir(fullname) then

            _, err_code, err_msg = rm_tree(fullname)
            if err_code ~= nil then
                return nil, err_code, err_msg
            end

        else

            _, err_msg = rm_file(fullname)
            if err_msg ~= nil then
                return nil, 'FileError', err_msg
            end

        end

    end

    _, err_msg = libluafs.rmdir(path)
    if err_msg ~= nil then
        return nil, 'FileError', err_msg
    end

    return nil, nil, nil

end

function base_path(path)
    local elts = strutil.split( path, '/' )
    elts[ #elts ] = nil
    local base = table.concat( elts, '/' )
    return base
end

function make_dirs(path, mode, uid, gid)

    local _
    local err_code, err_msg

    if is_dir(path) then
        return nil, nil, nil
    end

    _, err_code, err_msg = make_dirs( base_path(path), mode, uid, gid )
    if err_code ~= nil then
        return nil, err_code, err_msg
    end

    _, err_code, err_msg = make_dir( path, mode, uid, gid )
    if err_code ~= nil then
        return nil, err_code, err_msg
    end

    return nil, nil, nil
end

function mk_s2_dir(path)
    return make_dir( path, 0755,  s2conf.s2uid, s2conf.s2gid )
end

function make_s2_dirs(path)
    return make_dirs( path, 0755, s2conf.s2uid, s2conf.s2gid )
end

function chown_s2_file(fpath)

    local rst, err_msg = libluafs.chown( fpath, s2conf.s2uid, s2conf.s2gid )
    if not rst then
        return nil, 'FileError', err_msg
    end

    return nil, nil, nil
end

function file_size( fn )
    local info, err_msg = libluafs.stat( fn )
    if info == nil then
        return nil, 'FileError', err_msg
    end

    return base.tonumber(info.size)
end
