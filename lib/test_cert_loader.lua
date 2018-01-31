local cert_loader = require('acid.cert_loader')
local time = require('acid.time')


function test.build_cert_tree_and_choose(t)
    local sess = {
        cert_path = 'test_certs',
        cert_suffix = '.crt',
        cert_key_suffix = '.key',
    }

    local r, err, errmsg = cert_loader.build_cert_tree(sess, 'cert_tree')
    t:eq(nil, err, errmsg)

    local cert_tree = r.value
    t:neq(nil, cert_tree.com.aa.bb._cert_info.der_cert)
    t:neq(nil, cert_tree.com.aa.bb._cert_info.der_key)
    t:neq(nil, cert_tree.com.aa.bb.cc._cert_info.der_cert)
    t:neq(nil, cert_tree.com.aa.bb.cc._cert_info.der_key)
    t:neq(nil, cert_tree.root_cert._cert_info.der_cert)
    t:neq(nil, cert_tree.root_cert._cert_info.der_key)
    t:eq(nil, cert_tree.invalid_cert)

    for _, server_name, cert_name, desc in t:case_iter(2, {
        {'bb.aa.com', 'bb.aa.com'},
        {'foo.bar.bb.aa.com', 'bb.aa.com'},
        {'foo.cc.bb.aa.com', 'cc.bb.aa.com'},
        {'cc.bb.aa.com', 'cc.bb.aa.com'},
        {'bar.cc.bb.aa.com', 'cc.bb.aa.com'},
        {'aa.com', nil},
        {'foo', nil},
        {'foo.root_cert', 'root_cert'},
    }) do
        local cert_info = cert_loader.choose_cert(cert_tree, server_name)
        t:eq(cert_name, (cert_info or {}).cert_name, desc)
    end
end


function test.get_cert_tree(t)
    local opts = {
        expire_time=0.1,
        cache_expire_time=0.1,
        cert_path='test_certs',
        shared_dict_name='test_shared',
        lock_shared_dict_name='shared_dict_lock',
    }

    local start_ms = time.get_ms()
    local _, err, errmsg = cert_loader.get_cert_tree(opts)
    local first_time_used = time.get_ms() - start_ms
    t:eq(nil, err, errmsg)
    test.dd(string.format('at first time, time used: %d ms.',
                          first_time_used))

    ngx.sleep(1.1)

    local start_ms = time.get_ms()
    local _, err, errmsg = cert_loader.get_cert_tree(opts)
    local second_time_used = time.get_ms() - start_ms
    t:eq(nil, err, errmsg)
    test.dd(string.format('at second time, time used: %d ms.',
                          second_time_used))
    t:eq(true, second_time_used < first_time_used / 10)

    ngx.sleep(1.1)

    local start_ms = time.get_ms()
    local _, err, errmsg = cert_loader.get_cert_tree(opts)
    local third_time_used = time.get_ms() - start_ms
    t:eq(nil, err, errmsg)
    test.dd(string.format('at third time, time used: %d ms.',
                          third_time_used))
    t:eq(true, third_time_used < first_time_used / 10)
end
