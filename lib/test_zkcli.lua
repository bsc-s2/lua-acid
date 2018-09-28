local zkcli = require("acid.zkcli")
local strutil   = require("acid.strutil")

local to_str = strutil.to_str
local zk_hosts = '127.0.0.1:21811'


function test.create(t)
    local cli = zkcli:new(zk_hosts, 10000, {{'digest', 'xx:yy'}, {'digest', 'xx1:yy1'}})

    cases = {
        {'foo', 'val', nil},
        {'foo1', 'val1', {{'cdr', 'xx', 'yy'}}},
        {'foo2', 'val2', {{'cdr', 'xx', 'yy'}, {'cdrwa', 'xx1', 'yy1'}}},
    }
    for _, c in ipairs(cases) do
        local p, v, a = c[1], c[2], c[3]
        local res, err, errmsg = cli:create(p, v, a)
        t:eq(nil, err)
        t:eq(nil, errmsg)
        t:eq('/' .. p, res)
        t:eq(v, cli:get(p)[1])
        cli:delete(p)
    end

    cli:create('foo')
    local res, err, errmsg = cli:create('foo', 'val')
    t:eq('NodeExistsError', err)
    cli:delete('foo')

    local p, err, errmsg = cli:create('//////////////a')
    t:eq(nil, err)
    t:eq(nil, errmsg)
    t:eq('/a', p)

    local p, err, errmsg = cli:create('//a///////////////b')
    t:eq(nil, err)
    t:eq(nil, errmsg)
    t:eq('/a/b', p)
    cli:delete('a')
    cli:delete('/a/b')

    cli:create('seq', '')
    local res, err, errmsg = cli:create('seq/', 'val', nil, true)
    t:eq('/seq/0000000000', res)
    t:eq(nil, err)
    t:eq(nil, errmsg)
    cli:delete('seq')
    cli:delete('seq/0000000000')
end


function test.get_set(t)
    local cli = zkcli:new(zk_hosts, 10000)
    cli:create('foo', 'val')

    local res, err, errmsg = cli:get('bar')
    t:eq(nil, res)
    t:eq('NoNodeError', err)

    local res, err, errmsg = cli:get('foo')
    t:eq(nil, err)
    t:eq(nil, errmsg)
    t:eq('val', res[1])

    local st, err, errmsg = cli:set('foo', 'val1')
    t:eq(nil, err)
    t:eq(nil, errmsg)
    t:eq('val1', cli:get('foo')[1])

    local st, err, errmsg = cli:set('foo', 'val1', 0)
    t:eq('BadVersionError', err)

    cli:delete('foo')
end


function test.auth(t)
    local cli = zkcli:new(zk_hosts, 10000)
    cli:create('foo', 'val', {{'cdrwa', 'xx', 'yy'}})

    local res, err, errmsg = cli:get('foo')
    t:eq("NoAuthError", err)

    cli:add_auth('digest', 'xx:yy')
    local res, err, errmsg = cli:get('foo')
    t:eq(nil, err)
    t:eq(nil, errmsg)
    t:eq('val', res[1])

    local cli = zkcli:new(zk_hosts, 10000, {{'digest', 'xx:yy'}})
    local res, err, errmsg = cli:get('foo')
    t:eq(nil, err)
    t:eq(nil, errmsg)
    t:eq('val', res[1])

    cli:delete('foo')
end


function test.acl(t)
    local cli = zkcli:new(zk_hosts, 10000)
    cli:create('foo', 'val')
    local acls, err, errmsg = cli:get_acls('foo')
    t:eq(nil, err)
    t:eq(nil, errmsg)
    t:eq(to_str({{"cdrwa", "world", "anyone"}}), to_str(acls[1]))

    local st, err, errmsg = cli:set_acls('foo', {{'cdrwa', 'xx', 'yy'}}, 100)
    t:eq('BadVersionError', err)

    local st, err, errmsg = cli:set_acls('foo', {{'cdrwa', 'xx', 'yy'}})
    t:eq(nil, err)
    t:eq(nil, errmsg)

    local acls, err, errmsg = cli:get_acls('foo')
    t:eq(nil, err)
    t:eq(nil, errmsg)
    t:eq(to_str({{"cdrwa", "digest", "xx:zTkDyDcaoKWA3Xt0CWBQemWHg7c="}}), to_str(acls[1]))

    cli:add_auth('digest', 'xx:yy')
    local st, err, errmsg = cli:set_acls('foo', {{'cdr', 'xx', 'yy'}, {'cdrwa', 'xx1', 'yy1'}})
    t:eq(nil, err)
    t:eq(nil, errmsg)

    local acls, err, errmsg = cli:get_acls('foo')
    t:eq(nil, err)
    t:eq(nil, errmsg)
    t:eq(to_str({{"cdr", "digest", "xx:zTkDyDcaoKWA3Xt0CWBQemWHg7c="},{"cdrwa", "digest", "xx1:fPlNX0xjlU/NNaCEL4N5nqa6Vjw="}}), to_str(acls[1]))

    cli:delete('foo')
end


function test.get_next(t)
    local cli = zkcli:new(zk_hosts, 10000)
    cli:create('foo', 'val')

    local res, err, errmsg = cli:get('foo')
    local version = res[2].version

    ngx.timer.at(1, function(premature)
        local cli = zkcli:new(zk_hosts, 10000)
        cli:set('foo', 'val1')
    end)

    local res, err, errmsg = cli:get_next('foo', version, 10000)
    t:eq(nil, err)
    t:eq(nil, errmsg)
    t:eq('val1', res[1])

    cli:delete('foo')
end


function test.get_children(t)
    local cli = zkcli:new(zk_hosts, 10000)
    cli:create('foo', 'val')

    local res, err, errmsg = cli:get_children('foo')
    t:eq(nil, err)
    t:eq(nil, errmsg)
    t:eq(to_str({}), to_str(res))

    cli:create('foo/a')
    cli:create('foo/b')
    local res, err, errmsg = cli:get_children('foo')
    t:eq(nil, err)
    t:eq(nil, errmsg)
    t:eq(to_str({"a", "b"}), to_str(res))

    cli:delete('foo')
    cli:delete('foo/a')
    cli:delete('foo/b')
end


function test.delete(t)
    local cli = zkcli:new(zk_hosts, 10000)
    cli:create('foo', 'val')

    local _, err, errmsg = cli:delete('bar')
    t:eq('NoNodeError', err)

    local _, err, errmsg = cli:delete('foo', 100)
    t:eq('BadVersionError', err)

    local res, err, errmsg = cli:delete('foo')
    t:eq(true, res)
    t:eq(nil, err)
    t:eq(nil, errmsg)

    cli:create('bar', 'val')
    local res, err, errmsg = cli:delete('bar', 0)
    t:eq(true, res)
    t:eq(nil, err)
    t:eq(nil, errmsg)
end
