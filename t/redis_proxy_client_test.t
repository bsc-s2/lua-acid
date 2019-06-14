# vim:set ft=lua ts=4 sw=4 et:

use Test::Nginx::Socket 'no_plan';

use Cwd qw(cwd);
my $pwd = cwd();

no_long_string();

our $HttpConfig = qq{

    lua_package_path "$pwd/lib/?.lua;;";
    lua_package_cpath "$pwd/lib/?.so;;";
};

run_tests();

__DATA__

=== TEST 1: test get
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local rp = require("acid.redis_proxy_cli")
            local cli = rp:new({{"127.0.0.1", ngx.var.server_port}}, {nwr={3,2,2},ak_sk={"ak","sk"}})

            if cli == nil then
                ngx.log(ngx.ERR, " create client error")
                return
            end

            local res, err, errmsg = cli:get("test_key")
            if err ~= nil then
                ngx.log(ngx.ERR, " get error", " err:", err, " msg:", errmsg)
            end

            ngx.say(res)
        ';
    }

    location /redisproxy/v1 {
        content_by_lua '
            local json = require("acid.json")
            local qs = ngx.req.get_uri_args()

            if qs.n ~= "3" or qs.w ~= "2" or qs.r ~= "2" then
                ngx.log(ngx.ERR, "nwr error")
            end

            if ngx.var.uri ~= "/redisproxy/v1/GET/test_key" then
                ngx.log(ngx.ERR, "uri error")
            end

            if ngx.var.request_method ~= "GET" then
                ngx.log(ngx.ERR, "http method error")
            end

            ngx.say(json.enc("ok"))
        ';
    }
--- request
GET /t
--- response_body
ok
--- no_error_log
[error]

=== TEST 2: test get with retry
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local rp = require("acid.redis_proxy_cli")
            local cli = rp:new({{"127.0.0.1", ngx.var.server_port}}, {nwr={3,2,2},ak_sk={"ak","sk"}})

            if cli == nil then
                ngx.log(ngx.ERR, " create client error")
                return
            end

            local res, err, errmsg = cli:get("test_key", 2)
            if err ~= nil then
                ngx.log(ngx.ERR, " get error", " err:", err, " msg:", errmsg)
            end

            ngx.say(res)
        ';
    }

    location /redisproxy/v1 {
        content_by_lua '
            local json = require("acid.json")
            local qs = ngx.req.get_uri_args()

            if qs.n ~= "3" or qs.w ~= "2" or qs.r ~= "2" then
                ngx.log(ngx.ERR, "nwr error")
            end

            if ngx.var.uri ~= "/redisproxy/v1/GET/test_key" then
                ngx.log(ngx.ERR, "uri error")
            end

            if ngx.var.request_method ~= "GET" then
                ngx.log(ngx.ERR, "http method error")
            end

            ngx.say(json.enc("ok"))
        ';
    }
--- request
GET /t
--- response_body
ok
--- no_error_log
[error]

=== TEST 3: test set
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local rp = require("acid.redis_proxy_cli")
            local cli = rp:new({{"127.0.0.1", ngx.var.server_port}}, {nwr={3,2,2},ak_sk={"ak","sk"}})

            if cli == nil then
                ngx.log(ngx.ERR, " create client error")
                return
            end

            local res, err, errmsg = cli:set("test_key", 2)
            if err ~= nil then
                ngx.log(ngx.ERR, " set error", " err:", err, " msg:", errmsg)
            end
        ';
    }

    location /redisproxy/v1 {
        content_by_lua '
            local json = require("acid.json")
            local qs = ngx.req.get_uri_args()

            if ngx.var.request_method ~= "PUT" then
                ngx.log(ngx.ERR, "http method error")
            end

            if qs.n ~= "3" or qs.w ~= "2" or qs.r ~= "2" then
                ngx.log(ngx.ERR, "nwr error")
            end

            if qs.expire ~= nil then
                ngx.log(ngx.ERR, "expire error")
            end

            if ngx.var.uri ~= "/redisproxy/v1/SET/test_key" then
                ngx.log(ngx.ERR, "uri error")
            end

            ngx.req.read_body()
            local value = ngx.req.get_body_data()

            if value ~= json.enc(2) then
                ngx.log(ngx.ERR, "set value error")
            end
        ';
    }
--- request
GET /t
--- no_error_log
[error]

=== TEST 4: test set expire
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local rp = require("acid.redis_proxy_cli")
            local cli = rp:new({{"127.0.0.1", ngx.var.server_port}}, {nwr={3,2,2},ak_sk={"ak","sk"}})

            if cli == nil then
                ngx.log(ngx.ERR, " create client error")
                return
            end

            local val = {"1", "2"}
            local res, err, errmsg = cli:set("test_key", val, 1000)
            if err ~= nil then
                ngx.log(ngx.ERR, " set error", " err:", err, " msg:", errmsg)
            end
        ';
    }

    location /redisproxy/v1 {
        content_by_lua '
            local json = require("acid.json")
            local qs = ngx.req.get_uri_args()

            if ngx.var.request_method ~= "PUT" then
                ngx.log(ngx.ERR, "http method error")
            end

            if qs.n ~= "3" or qs.w ~= "2" or qs.r ~= "2" then
                ngx.log(ngx.ERR, "nwr error")
            end

            if qs.expire ~= "1000" then
                ngx.log(ngx.ERR, "expire error")
            end

            if ngx.var.uri ~= "/redisproxy/v1/SET/test_key" then
                ngx.log(ngx.ERR, "uri error")
            end

            ngx.req.read_body()
            local value = ngx.req.get_body_data()

            if value ~= json.enc({"1", "2"}) then
                ngx.log(ngx.ERR, "set value error")
            end
        ';
    }
--- request
GET /t
--- no_error_log
[error]

=== TEST 5: test set expire retry
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local rp = require("acid.redis_proxy_cli")
            local cli = rp:new({{"127.0.0.1", ngx.var.server_port}}, {nwr={3,2,2},ak_sk={"ak","sk"}})

            if cli == nil then
                ngx.log(ngx.ERR, " create client error")
                return
            end

            local val = {"1", "2"}
            local res, err, errmsg = cli:set("test_key", val, 1000, 20)
            if err ~= nil then
                ngx.log(ngx.ERR, " set error", " err:", err, " msg:", errmsg)
            end
        ';
    }

    location /redisproxy/v1 {
        content_by_lua '
            local json = require("acid.json")
            local qs = ngx.req.get_uri_args()

            if ngx.var.request_method ~= "PUT" then
                ngx.log(ngx.ERR, "http method error")
            end

            if qs.n ~= "3" or qs.w ~= "2" or qs.r ~= "2" then
                ngx.log(ngx.ERR, "nwr error")
            end

            if qs.expire ~= "1000" then
                ngx.log(ngx.ERR, "expire error")
            end

            if ngx.var.uri ~= "/redisproxy/v1/SET/test_key" then
                ngx.log(ngx.ERR, "uri error")
            end

            ngx.req.read_body()
            local value = ngx.req.get_body_data()

            if value ~= json.enc({"1", "2"}) then
                ngx.log(ngx.ERR, "set value error")
            end
        ';
    }
--- request
GET /t
--- no_error_log
[error]

=== TEST 6: test hget
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local rp = require("acid.redis_proxy_cli")
            local cli = rp:new({{"127.0.0.1", ngx.var.server_port}}, {nwr={3,2,2},ak_sk={"ak","sk"}})

            if cli == nil then
                ngx.log(ngx.ERR, " create client error")
                return
            end

            local res, err, errmsg = cli:hget("hashname1", "hashkey1")
            if err ~= nil then
                ngx.log(ngx.ERR, " hget error", " err:", err, " msg:", errmsg)
            end

            ngx.say(res)
        ';
    }

    location /redisproxy/v1 {
        content_by_lua '
            local json = require("acid.json")
            local qs = ngx.req.get_uri_args()

            if ngx.var.request_method ~= "GET" then
                ngx.log(ngx.ERR, "http method error")
            end

            if qs.n ~= "3" or qs.w ~= "2" or qs.r ~= "2" then
                ngx.log(ngx.ERR, "nwr error")
            end

            if ngx.var.uri ~= "/redisproxy/v1/HGET/hashname1/hashkey1" then
                ngx.log(ngx.ERR, "uri error")
            end

            ngx.say(json.enc("ok"))
        ';
    }
--- request
GET /t
--- response_body
ok
--- no_error_log
[error]

=== TEST 7: test hget with retry
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local rp = require("acid.redis_proxy_cli")
            local cli = rp:new({{"127.0.0.1", ngx.var.server_port}}, {nwr={3,2,2},ak_sk={"ak","sk"}})

            if cli == nil then
                ngx.log(ngx.ERR, " create client error")
                return
            end

            local res, err, errmsg = cli:hget("hashname1", "hashkey1", 2)
            if err ~= nil then
                ngx.log(ngx.ERR, " hget error", " err:", err, " msg:", errmsg)
            end

            ngx.say(res)
        ';
    }

    location /redisproxy/v1 {
        content_by_lua '
            local json = require("acid.json")
            local qs = ngx.req.get_uri_args()

            if ngx.var.request_method ~= "GET" then
                ngx.log(ngx.ERR, "http method error")
            end

            if qs.n ~= "3" or qs.w ~= "2" or qs.r ~= "2" then
                ngx.log(ngx.ERR, "nwr error")
            end

            if ngx.var.uri ~= "/redisproxy/v1/HGET/hashname1/hashkey1" then
                ngx.log(ngx.ERR, "uri error")
            end

            ngx.say(json.enc("ok"))
        ';
    }
--- request
GET /t
--- response_body
ok
--- no_error_log
[error]

=== TEST 8: test hset
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local rp = require("acid.redis_proxy_cli")
            local cli = rp:new({{"127.0.0.1", ngx.var.server_port}}, {nwr={3,2,2},ak_sk={"ak","sk"}})

            if cli == nil then
                ngx.log(ngx.ERR, " create client error")
                return
            end

            local res, err, errmsg = cli:hset("hashname1", "hashkey1", "val")
            if err ~= nil then
                ngx.log(ngx.ERR, " hset error", " err:", err, " msg:", errmsg)
            end
        ';
    }

    location /redisproxy/v1 {
        content_by_lua '
            local json = require("acid.json")
            local qs = ngx.req.get_uri_args()

            if ngx.var.request_method ~= "PUT" then
                ngx.log(ngx.ERR, "http method error")
            end

            if qs.n ~= "3" or qs.w ~= "2" or qs.r ~= "2" then
                ngx.log(ngx.ERR, "nwr error")
            end

            if qs.expire ~= nil then
                ngx.log(ngx.ERR, "expire error")
            end

            if ngx.var.uri ~= "/redisproxy/v1/HSET/hashname1/hashkey1" then
                ngx.log(ngx.ERR, "uri error")
            end

            ngx.req.read_body()
            local value = ngx.req.get_body_data()

            if value ~= json.enc("val") then
                ngx.log(ngx.ERR, "hset value error")
            end
        ';
    }
--- request
GET /t
--- no_error_log
[error]

=== TEST 9: test hset expire
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local rp = require("acid.redis_proxy_cli")
            local cli = rp:new({{"127.0.0.1", ngx.var.server_port}}, {nwr={3,2,2},ak_sk={"ak","sk"}})

            if cli == nil then
                ngx.log(ngx.ERR, " create client error")
                return
            end

            local res, err, errmsg = cli:hset("hashname1", "hashkey1", "val", 1000)
            if err ~= nil then
                ngx.log(ngx.ERR, " hset error", " err:", err, " msg:", errmsg)
            end
        ';
    }

    location /redisproxy/v1 {
        content_by_lua '
            local json = require("acid.json")
            local qs = ngx.req.get_uri_args()

            if ngx.var.request_method ~= "PUT" then
                ngx.log(ngx.ERR, "http method error")
            end

            if qs.n ~= "3" or qs.w ~= "2" or qs.r ~= "2" then
                ngx.log(ngx.ERR, "nwr error")
            end

            if qs.expire ~= "1000" then
                ngx.log(ngx.ERR, "expire error")
            end

            if ngx.var.uri ~= "/redisproxy/v1/HSET/hashname1/hashkey1" then
                ngx.log(ngx.ERR, "uri error")
            end

            ngx.req.read_body()
            local value = ngx.req.get_body_data()

            if value ~= json.enc("val") then
                ngx.log(ngx.ERR, "hset value error")
            end
        ';
    }
--- request
GET /t
--- no_error_log
[error]

=== TEST 10: test hset expire retry
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local rp = require("acid.redis_proxy_cli")
            local cli = rp:new({{"127.0.0.1", ngx.var.server_port}}, {nwr={3,2,2},ak_sk={"ak","sk"}})

            if cli == nil then
                ngx.log(ngx.ERR, " create client error")
                return
            end

            local res, err, errmsg = cli:hset("hashname1", "hashkey1", {"1"}, 1000, 2)
            if err ~= nil then
                ngx.log(ngx.ERR, " hset error", " err:", err, " msg:", errmsg)
            end
        ';
    }

    location /redisproxy/v1 {
        content_by_lua '
            local json = require("acid.json")
            local qs = ngx.req.get_uri_args()

            if ngx.var.request_method ~= "PUT" then
                ngx.log(ngx.ERR, "http method error")
            end

            if qs.n ~= "3" or qs.w ~= "2" or qs.r ~= "2" then
                ngx.log(ngx.ERR, "nwr error")
            end

            if qs.expire ~= "1000" then
                ngx.log(ngx.ERR, "expire error")
            end

            if ngx.var.uri ~= "/redisproxy/v1/HSET/hashname1/hashkey1" then
                ngx.log(ngx.ERR, "uri error")
            end

            ngx.req.read_body()
            local value = ngx.req.get_body_data()

            if value ~= json.enc({"1"}) then
                ngx.log(ngx.ERR, "hset value error")
            end
        ';
    }
--- request
GET /t
--- no_error_log
[error]

=== TEST 11: test del
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local rp = require("acid.redis_proxy_cli")
            local cli = rp:new({{"127.0.0.1", ngx.var.server_port}}, {nwr={3,2,2},ak_sk={"ak","sk"}})

            if cli == nil then
                ngx.log(ngx.ERR, " create client error")
                return
            end

            local res, err, errmsg = cli:del("key")
            if err ~= nil then
                ngx.log(ngx.ERR, " del error", " err:", err, " msg:", errmsg)
            end
        ';
    }

    location /redisproxy/v1 {
        content_by_lua '
            local json = require("acid.json")
            local qs = ngx.req.get_uri_args()

            if ngx.var.request_method ~= "DELETE" then
                ngx.log(ngx.ERR, "http method error")
            end

            if qs.n ~= "3" or qs.w ~= "2" or qs.r ~= "2" then
                ngx.log(ngx.ERR, "nwr error")
            end

            if ngx.var.uri ~= "/redisproxy/v1/DEL/key" then
                ngx.log(ngx.ERR, "uri error")
            end
        ';
    }
--- request
GET /t
--- no_error_log
[error]

=== TEST 13: test hdel
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local rp = require("acid.redis_proxy_cli")
            local cli = rp:new({{"127.0.0.1", ngx.var.server_port}}, {nwr={3,2,2},ak_sk={"ak","sk"}})

            if cli == nil then
                ngx.log(ngx.ERR, " create client error")
                return
            end

            local res, err, errmsg = cli:hdel("hashname", "key")
            if err ~= nil then
                ngx.log(ngx.ERR, " hdel error", " err:", err, " msg:", errmsg)
            end
        ';
    }

    location /redisproxy/v1 {
        content_by_lua '
            local json = require("acid.json")
            local qs = ngx.req.get_uri_args()

            if ngx.var.request_method ~= "DELETE" then
                ngx.log(ngx.ERR, "http method error")
            end

            if qs.n ~= "3" or qs.w ~= "2" or qs.r ~= "2" then
                ngx.log(ngx.ERR, "nwr error")
            end

            if ngx.var.uri ~= "/redisproxy/v1/HDEL/hashname/key" then
                ngx.log(ngx.ERR, "uri error")
            end
        ';
    }
--- request
GET /t
--- no_error_log
[error]
