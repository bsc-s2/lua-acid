local hashlib = require('acid.hashlib')

local dd = test.dd
local rep = string.rep

local function normal_rst(algorithm, parts)
    local rst = {}
    for idx, _ in pairs(parts) do
        local alg_obj = hashlib.new(algorithm)
        for i=1, idx do
            alg_obj:update(parts[i])
        end
        table.insert(rst, alg_obj:final())
    end
    return rst
end

local function serialize_rst(algorithm, parts)
    local rst = {}
    local alg_obj = hashlib.new(algorithm)
    for _, part in pairs(parts) do
        alg_obj:update(part)
        local ctx = alg_obj:serialize()
        table.insert(rst, alg_obj:final())
        alg_obj:deserialize(ctx)
    end
    return rst
end

function test.new(t)
    local cases = {
        { hashlib.MD5, },
        { hashlib.SHA1 },
        { hashlib.SHA256 },
    }

    for _, case in ipairs(cases) do
        local algorithm = unpack(case)
        t:neq(hashlib.new(algorithm), nil)
    end

    local badcases = {
        {"NotExisted"}
    }

    for _, case in ipairs(badcases) do
        local algorithm = unpack(case)
        t:eq(hashlib.new(algorithm), nil)
    end
end

function test.serialize_and_deserialize(t)

    local algorithms = {
        hashlib.MD5,
        hashlib.SHA1,
        hashlib.SHA256
    }

    local data = '바로中文12ab!@#$%^&*()_+-=~`?.,<>:;"[]{}\'\\'

    local cases = {
        { data, rep(data, 128), rep(data, 256), rep(data, 512), rep(data, 1024), rep(data, 1024 * 128), rep(data, 1024 * 1024) }
    }

    for _, algorithm in ipairs(algorithms) do
        for _, case in ipairs(cases) do
            local normal_rst = normal_rst(algorithm, case)
            local serialize_rst = serialize_rst(algorithm, case)
            t:eqdict(normal_rst, serialize_rst)
        end
    end
end

function test.deserialize(t)

    local badcases = {
        { { test = 'test' }, hashlib.MD5 },
    }

    for _, case in ipairs(badcases) do
        local ctx, algorithm = unpack(case)
        local hasher = hashlib.new(algorithm)
        local _, err, errmsg = hasher:deserialize(ctx)
        t:neq(err, nil)
        t:neq(err, errmsg)
        dd(err)
        dd(errmsg)
    end

end
