local ffiutil = require('acid.ffiutil')
local ffi = require('ffi')
local tableutil = require('acid.tableutil')
local strutil = require('acid.strutil')

local resty_md5 = require('resty.md5')
local resty_sha1 = require('resty.sha1')
local resty_sha256 = require('resty.sha256')

local to_str = strutil.to_str

local _M = {
    _VERSION = '1.0',
    MD5 = 'md5',
    SHA1 = 'sha1',
    SHA256 = 'sha256'
}

local mt = { __index = _M }

local str_to_unsiged_clong = function(val) return ffiutil.str_to_clong(val, 'u') end
local clong_to_str = ffiutil.clong_to_str

local schemas = {
    md5 = {
        ctype = 'MD5_CTX[1]',
        algorithm = resty_md5,
        enc = {
            {
                A = str_to_unsiged_clong,
                B = str_to_unsiged_clong,
                C = str_to_unsiged_clong,
                D = str_to_unsiged_clong,
                Nl = str_to_unsiged_clong,
                Nh = str_to_unsiged_clong,
                data = function(val) return ffiutil.tbl_to_carray('MD5_LONG[MD5_LBLOCK]', val, str_to_unsiged_clong) end,
                num = tonumber
            }
        },
        dec = {
            {
                A = clong_to_str,
                B = clong_to_str,
                C = clong_to_str,
                D = clong_to_str,
                Nl = clong_to_str,
                Nh = clong_to_str,
                data = function(val) return ffiutil.carray_to_tbl(val, ffi.C.MD5_LBLOCK, clong_to_str) end,
                num = tonumber
            }
        }
    },
    sha1 = {
        ctype = 'SHA_CTX[1]',
        algorithm = resty_sha1,
        enc = {
            {
                h0 = str_to_unsiged_clong,
                h1 = str_to_unsiged_clong,
                h2 = str_to_unsiged_clong,
                h3 = str_to_unsiged_clong,
                h4 = str_to_unsiged_clong,
                Nl = str_to_unsiged_clong,
                Nh = str_to_unsiged_clong,
                data = function(val) return ffiutil.tbl_to_carray('SHA_LONG[SHA_LBLOCK]', val, str_to_unsiged_clong) end,
                num = tonumber
            }
        },
        dec = {
            {
                h0 = clong_to_str,
                h1 = clong_to_str,
                h2 = clong_to_str,
                h3 = clong_to_str,
                h4 = clong_to_str,
                Nl = clong_to_str,
                Nh = clong_to_str,
                data = function(val) return ffiutil.carray_to_tbl(val, ffi.C.SHA_LBLOCK, clong_to_str) end,
                num = tonumber
            }
        }
    },
    sha256 = {
        ctype = 'SHA256_CTX[1]',
        algorithm = resty_sha256,
        enc = {
            {
                h = function(val) return ffiutil.tbl_to_carray('SHA_LONG[8]', val, str_to_unsiged_clong) end,
                Nl = str_to_unsiged_clong,
                Nh = str_to_unsiged_clong,
                data = function(val) return ffiutil.tbl_to_carray('SHA_LONG[SHA_LBLOCK]', val, str_to_unsiged_clong) end,
                num = tonumber,
                md_len = tonumber
            }
        },
        dec = {
            {
                h = function(val) return ffiutil.carray_to_tbl(val, 8, clong_to_str) end,
                Nl = clong_to_str,
                Nh = clong_to_str,
                data = function(val) return ffiutil.carray_to_tbl(val, ffi.C.SHA_LBLOCK, clong_to_str) end,
                num = tonumber,
                md_len = tonumber
            }
        }
    },
}

local supported = tableutil.keys(schemas)

function _M.new(algorithm)

    local schema = schemas[algorithm]

    if schema == nil then
        return nil, 'UnsupportedAlgorithm', string.format('unsupported algorithm %s, we support %s', algorithm, to_str(supported))
    end

    local hasher = schema['algorithm']:new()

    return setmetatable({
        hasher = hasher,
        algorithm = algorithm,
        schema = schema
    }, mt), nil, nil

end

function _M.md5()
    return _M.new(_M.MD5)
end

function _M.sha1()
    return _M.new(_M.SHA1)
end

function _M.sha256()
    return _M.new(_M.SHA256)
end

function _M.update(self, data)
    return self.hasher:update(data)
end

function _M.reset(self)
    return self.hasher:reset()
end

function _M.final(self)
    return self.hasher:final()
end

function _M.deserialize(self, ctx)

    local ctype = self.schema['ctype']

    local enc_schema = self.schema['enc']

    local cdata_ctx, err, errmsg = ffiutil.tbl_to_cdata(ctype, ctx, enc_schema)

    if err ~= nil then
        return nil, err, errmsg
    end

    self.hasher['_ctx'] = cdata_ctx

    return true, nil, nil
end

function _M.serialize(self)

    local dec_schema = self.schema['dec']

    local ctx, err, errmsg = ffiutil.cdata_to_tbl(self.hasher['_ctx'], dec_schema)

    if err ~= nil then
        return nil, err, errmsg
    end

    return ctx, nil, nil
end

return _M
