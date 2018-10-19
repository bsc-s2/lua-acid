local ffi = require("ffi")

local crypto = ffi.load('crypto')
local setmetatable = setmetatable

local _M = {}

local mt = {__index = _M}

ffi.cdef[[

enum {
    EVP_MAX_MD_SIZE = 64
};

typedef struct engine_st ENGINE;
typedef struct evp_md_ctx_st EVP_MD_CTX;
typedef struct evp_md_st EVP_MD;

EVP_MD_CTX *EVP_MD_CTX_new(void);
const EVP_MD *EVP_sm3(void);
int EVP_DigestInit_ex(EVP_MD_CTX *ctx, const EVP_MD *type, ENGINE *impl);
int EVP_MD_CTX_reset(EVP_MD_CTX *ctx);
int EVP_DigestUpdate(EVP_MD_CTX *ctx, const void *data, size_t count);
int EVP_DigestFinal_ex(EVP_MD_CTX *ctx, unsigned char *md, unsigned int *s);

]]

local char_typ = ffi.typeof("unsigned char[?]")
local int_typ = ffi.typeof("unsigned int[1]")

function _M.new(self)

    local ctx = crypto.EVP_MD_CTX_new()

    if ctx == nil then
        return nil
    end

    local ret = crypto.EVP_DigestInit_ex(ctx, crypto.EVP_sm3(), nil)

    if ret == 0 then
        return nil
    end

    return setmetatable({_ctx = ctx}, mt)

end

function _M.update(self, s)

    assert(type(s) == 'string', 's is not a string, type: ' .. type(s))
    return crypto.EVP_DigestUpdate(self._ctx, s, #s) == 1

end

function _M.final(self)

    local buf = ffi.new(char_typ, ffi.C.EVP_MAX_MD_SIZE)
    local len = ffi.new(int_typ)

    if crypto.EVP_DigestFinal_ex(self._ctx, buf, len) == 1 then
        return ffi.string(buf, len[0])
    end

    return nil

end

function _M.reset(self)

    return crypto.EVP_MD_CTX_reset(self._ctx) == 1

end

return _M
