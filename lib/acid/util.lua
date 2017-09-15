local ffi = require('ffi')

ffi.cdef[[
int errno;
struct passwd {
	char *pw_name;
	char *pw_passwd;
	unsigned int pw_uid;
	unsigned int pw_gid;
	char *pw_gecos;
	char *pw_dir;
	char *pw_shell;
};
struct group {
	char *gr_name;
	char *gr_passwd;
	unsigned int gr_gid;
	char **gr_mem;
};

char *strerror(int errnum);
struct passwd *getpwnam(const char *name);
struct passwd *getpwuid(unsigned int gid);
struct group *getgrnam(const char *name);
struct group *getgrgid(unsigned int gid);
]]


local _M = {}


function _M.strerror(errnum)
    local strp = ffi.C.strerror(errnum)
    local err_str = string.format('%d: %s', errnum, ffi.string(strp))
    return err_str
end


function _M.get_user(name_or_uid)
    local passwdp

    ffi.C.errno = 0
    if type(name_or_uid) == 'string' then
        passwdp = ffi.C.getpwnam(name_or_uid)
    elseif type(name_or_uid) == 'number' then
        passwdp = ffi.C.getpwuid(name_or_uid)
    else
        return nil, 'InvalidArgument', string.format(
                '%s is type %s, not a string or number',
                tostring(name_or_uid), type(name_or_uid))
    end

    local errno = ffi.errno()
    if errno ~= 0 then
        return nil, 'GetUserError', _M.strerror(errno)
    end

    if passwdp == nil then
        return nil, nil, nil
    end

    local user = {
        pw_name = ffi.string(passwdp.pw_name),
        pw_passwd = ffi.string(passwdp.pw_passwd),
        pw_uid = tonumber(passwdp.pw_uid),
        pw_gid = tonumber(passwdp.pw_gid),
        pw_gecos = ffi.string(passwdp.pw_gecos),
        pw_dir = ffi.string(passwdp.pw_dir),
        pw_shell = ffi.string(passwdp.pw_shell),
    }

    return user, nil, nil
end


function _M.get_group(name_or_gid)
    local groupp

    ffi.C.errno = 0
    if type(name_or_gid) == 'string' then
        groupp = ffi.C.getgrnam(name_or_gid)
    elseif type(name_or_gid) == 'number' then
        groupp = ffi.C.getgrgid(name_or_gid)
    else
        return nil, 'InvalidArgument', string.format(
                '%s is type %s, not a string or number',
                tostring(name_or_gid), type(name_or_gid))
    end

    local errno = ffi.errno()
    if errno ~= 0 then
        return nil, 'GetUserError', _M.strerror(errno)
    end

    if groupp == nil then
        return nil, nil, nil
    end

    local group = {
        gr_name = ffi.string(groupp.gr_name),
        gr_passwd = ffi.string(groupp.gr_passwd),
        gr_gid = tonumber(groupp.gr_gid),
    }

    return group, nil, nil
end


return _M

