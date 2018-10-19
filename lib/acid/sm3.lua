local ffi = require("ffi")

local crypto = ffi.load('crypto')
local setmetatable = setmetatable

local _M = {}

local mt = {__index = _M}

ffi.cdef[[

typedef struct engine_st ENGINE;
typedef struct evp_pkey_ctx_st EVP_PKEY_CTX;
typedef struct env_md_ctx_st EVP_MD_CTX;
typedef struct env_md_st EVP_MD;

struct env_md_ctx_st
    {
     const EVP_MD *digest;
     ENGINE *engine;
     unsigned long flags;
     void *md_data;
     EVP_PKEY_CTX *pctx;
     int (*update) (EVP_MD_CTX *ctx, const void *data, size_t count);
    };

struct env_md_st
    {
     int type;
     int pkey_type;
     int md_size;
     unsigned long flags;
     int (*init)(EVP_MD_CTX *ctx);
     int (*update)(EVP_MD_CTX *ctx,const void *data,size_t count);
     int (*final)(EVP_MD_CTX *ctx,unsigned char *md);
     int (*copy)(EVP_MD_CTX *to,const EVP_MD_CTX *from);
     int (*cleanup)(EVP_MD_CTX *ctx);
     int block_size;
     int ctx_size;
     int (*md_ctrl) (EVP_MD_CTX *ctx, int cmd, int p1, void *p2);
    };

EVP_MD_CTX *EVP_MD_CTX_new(void);
const EVP_MD *EVP_sm3(void);
int EVP_DigestInit_ex(EVP_MD_CTX *ctx, const EVP_MD *type, ENGINE *impl);
int EVP_MD_CTX_reset(EVP_MD_CTX *ctx);
int EVP_DigestUpdate(EVP_MD_CTX *ctx, const void *data, size_t count);
int EVP_DigestFinal_ex(EVP_MD_CTX *ctx, unsigned char *md, unsigned int *s);

]]

local char_typ = ffi.typeof("char[64]")
local int_typ = ffi.typeof("int[1]")
local buf = ffi.new(char_typ, 64)
local len = ffi.new(int_typ)

function _M.new(self)

    local ctx = crypto.EVP_MD_CTX_new()
    local ret = crypto.EVP_DigestInit_ex(ctx, crypto.EVP_sm3(), nil)

    if ret == 0 then
        return nil
    end

    return setmetatable({_ctx = ctx}, mt)

end

function _M.update(self, s)

    return crypto.EVP_DigestUpdate(self._ctx, s, #s) == 1

end

function _M.final(self)

    if crypto.EVP_DigestFinal_ex(self._ctx, buf, len) == 1 then
        return ffi.string(buf, len[0])
    end

    return nil

end

function _M.reset(self)

    return crypto.EVP_MD_CTX_reset(self._ctx) == 1

end

return _M
