local httpclient = require('acid.httpclient')

function test.basic(t)
    local opts = {
        server_name = 'ss.bscstorage.com',
    }
    local cli, err, errmsg = httpclient:new('ss.bscstorage.com', 443,
                                            nil, opts)
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)

    local _, err, errmsg = cli:request('/')
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)
    t:eq(403, cli.status)
end

function test.not_verify(t)
    local opts = {
        server_name = 'foo',
        ssl_verify = true,
    }
    local cli, err, errmsg = httpclient:new('ss.bscstorage.com', 443,
                                            nil, opts)
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)

    local _, err, errmsg = cli:request('/', opts)
    t:neq(nil, err)
    t:neq(nil, errmsg)

    local opts = {
        server_name = 'foo',
        ssl_verify = false,
    }
    local cli, err, errmsg = httpclient:new('ss.bscstorage.com', 443,
                                            nil, opts)
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)

    local _, err, errmsg = cli:request('/', opts)
    t:eq(nil, err)
    t:eq(nil, errmsg)
    t:eq(403, cli.status)
end

function test.reused_session(t)
    local opts = {
        server_name = 'ss.bscstorage.com',
        reused_session = false,
    }
    local cli, err, errmsg = httpclient:new('ss.bscstorage.com', 443,
                                            nil, opts)
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)

    local _, err, errmsg = cli:request('/', opts)
    t:eq(nil, err)
    t:eq(nil, errmsg)
    t:eq(403, cli.status)
    t:eq(true, cli.ssl_session)

    local opts = {
        server_name = 'ss.bscstorage.com',
    }
    local cli, err, errmsg = httpclient:new('ss.bscstorage.com', 443,
                                            nil, opts)
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)

    local _, err, errmsg = cli:request('/', opts)
    t:eq(nil, err)
    t:eq(nil, errmsg)
    t:eq(403, cli.status)
    t:eq('userdata', type(cli.ssl_session))
end

function test.no_server_name(t)
    local opts = {
        ssl_verify = false,
    }
    local cli, err, errmsg = httpclient:new('ss.bscstorage.com', 443,
                                            nil, opts)
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)

    local _, err, errmsg = cli:request('/')
    t:eq(nil, err, errmsg)
    t:eq(nil, errmsg)
    t:eq(403, cli.status)
end
