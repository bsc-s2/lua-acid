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

=== TEST 1: test base get
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local httpclient = require("acid.httpclient")

            local cli = httpclient:new( "127.0.0.1", ngx.var.server_port)
            local err, errmes = cli:request( "/b")
            if err ~= nil then
                ngx.log(ngx.ERR, "requset error")
                return
            end

            if cli.status ~= 200 then
                ngx.log(ngx.ERR, "requset error")
                return
            end

            local body = cli:read_body( 1024 )
            ngx.print(body)
            return
        ';
    }

    location /b {
        echo "ok";
    }
--- request
GET /t
--- response_body
ok
--- no_error_log
[error]

=== TEST 2: test status code
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local httpclient = require("acid.httpclient")

            local cli = httpclient:new( "127.0.0.1", ngx.var.server_port)
            local err, errmes = cli:request( "/b")
            if err ~= nil then
                ngx.log(ngx.ERR, "requset error")
                return
            end

            ngx.say(cli.status)
            return
        ';
    }

    location /b {
        content_by_lua '
            ngx.status = 400
        ';
    }
--- request
GET /t
--- response_body
400
--- no_error_log
[error]

=== TEST 3: test request headers
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local httpclient = require("acid.httpclient")

            local cli = httpclient:new( "127.0.0.1", ngx.var.server_port)
            local err, errmes = cli:request( "/b", {headers={["x-header-t"]="x-val"}})
            if err ~= nil then
                ngx.log(ngx.ERR, "requset error")
                return
            end

            ngx.say(cli.status)
            return
        ';
    }

    location /b {
        content_by_lua '
            local hdr = ngx.req.get_headers(0)
            if hdr["x-header-t"] ~= "x-val" then
                ngx.status = 400
            else
                ngx.status = 200
            end
        ';
    }
--- request
GET /t
--- response_body
200
--- no_error_log
[error]

=== TEST 4: test response headers
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local httpclient = require("acid.httpclient")

            local cli = httpclient:new( "127.0.0.1", ngx.var.server_port)
            local err, errmes = cli:request( "/b")
            if err ~= nil then
                ngx.log(ngx.ERR, "requset error")
                return
            end

            if cli.status ~= 200 then
                ngx.log(ngx.ERR, "requset error")
                return
            end

            ngx.say(cli.headers["x-header-t"])
            return
        ';
    }

    location /b {
        content_by_lua '
            ngx.header["x-header-t"] = "x-val"
        ';
    }
--- request
GET /t
--- response_body
x-val
--- no_error_log
[error]

=== TEST 5: test request with body
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local httpclient = require("acid.httpclient")

            local cli = httpclient:new( "127.0.0.1", ngx.var.server_port)
            local err, errmes = cli:request( "/b", {mehod="put", body="test_body"})
            if err ~= nil then
                ngx.log(ngx.ERR, "requset error")
                return
            end

            if cli.status ~= 200 then
                ngx.log(ngx.ERR, "requset error")
                return
            end

            local body = cli:read_body(1024)
            ngx.say(body)
            return
        ';
    }

    location /b {
        content_by_lua '
            ngx.req.read_body()
            ngx.print(ngx.req.get_body_data())
        ';
    }
--- request
GET /t
--- response_body
test_body
--- no_error_log
[error]

=== TEST 6: test request with pipe body
--- http_config eval: $::HttpConfig
--- config

    client_body_buffer_size 10m;

    location /t {
        content_by_lua '
            local httpclient = require("acid.httpclient")

            local size = 512

            local cli = httpclient:new( "127.0.0.1", ngx.var.server_port)
            local err, errmes = cli:send_request( "/b", {mehod="put", headers={["Content-Length"]=size}})
            if err ~= nil then
                ngx.log(ngx.ERR, "requset error")
                return
            end

            math.randomseed(ngx.now()*1000)

            local body = {}
            while size > 0 do
                local send_size = math.min(size, 128)

                local buf = string.rep(string.char(math.random(255)), send_size)
                table.insert(body, buf)

                local _, err, errmes = cli:send_body(buf)
                if err ~= nil then
                    ngx.log(ngx.ERR, "requset error", err, errmes)
                    return
                end

                size = size - #buf
            end

            cli:finish_request()

            body = table.concat(body)

            if cli.status ~= 200 then
                ngx.log(ngx.ERR, "requset error", cli.status )
                return
            end

            local recv_body = cli:read_body(1024*1024*10)
            if body ~= recv_body then
                ngx.say("bad")
            else
                ngx.say("ok")
            end
            return
        ';
    }

    location /b {
        content_by_lua '
            ngx.req.read_body()
            ngx.print(ngx.req.get_body_data())
        ';
    }
--- request
GET /t
--- response_body
ok
--- no_error_log
[error]

=== TEST 7: test HEAD request with no body
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local httpclient = require("acid.httpclient")

            local cli = httpclient:new( "127.0.0.1", ngx.var.server_port)
            local err, errmes = cli:request( "/b", {method="HEAD"})
            if err ~= nil then
                ngx.log(ngx.ERR, "requset error")
                return
            end

            if cli.status ~= 200 then
                ngx.log(ngx.ERR, "requset error")
                return
            end

            local body = cli:read_body(1024)
            ngx.print(body)
            return
        ';
    }

    location /b {
        content_by_lua '
            local m = ngx.req.get_method()
            if m ~= "HEAD" then
                ngx.status = 400
            else
                ngx.status = 200
            end
            ngx.say("ok")
        ';
    }
--- request
GET /t
--- response_body
--- no_error_log
[error]

=== TEST 8: test 204 request with no body
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local httpclient = require("acid.httpclient")

            local cli = httpclient:new( "127.0.0.1", ngx.var.server_port)
            local err, errmes = cli:request( "/b", {method="HEAD"})
            if err ~= nil then
                ngx.log(ngx.ERR, "requset error")
                return
            end

            if cli.status ~= 204 then
                ngx.log(ngx.ERR, "requset error")
                return
            end

            local body = cli:read_body(1024)
            ngx.print(body)
            return
        ';
    }

    location /b {
        content_by_lua '
            ngx.status = 204
            ngx.say("ok")
        ';
    }
--- request
GET /t
--- response_body
--- no_error_log
[error]

=== TEST 9: test 304 request with no body
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local httpclient = require("acid.httpclient")

            local cli = httpclient:new( "127.0.0.1", ngx.var.server_port)
            local err, errmes = cli:request( "/b" )
            if err ~= nil then
                ngx.log(ngx.ERR, "requset error")
                return
            end

            if cli.status ~= 304 then
                ngx.log(ngx.ERR, "requset error")
                return
            end

            local body = cli:read_body(1024)
            ngx.print(body)
            return
        ';
    }

    location /b {
        content_by_lua '
            ngx.status = 304
            ngx.say("ok")
        ';
    }
--- request
GET /t
--- response_body
--- no_error_log
[error]

=== TEST 10: test chunked body
--- http_config eval: $::HttpConfig
--- config

    client_body_buffer_size 10m;

    location /t {
        content_by_lua '
            local httpclient = require("acid.httpclient")

            local cli = httpclient:new( "127.0.0.1", ngx.var.server_port)
            local err, errmes = cli:request( "/b" )
            if err ~= nil then
                ngx.log(ngx.ERR, "requset error")
                return
            end

            if cli.status ~= 200 then
                ngx.log(ngx.ERR, "requset error", cli.status )
                return
            end

            local recv_body, err, errmes = cli:read_body(1024*1024*10)
            ngx.say(#(recv_body or ""))
            return
        ';
    }

    location /b {
        chunked_transfer_encoding on;

        content_by_lua '
            math.randomseed(ngx.now()*1000)

            ngx.status = 200

            local size = 1024 * 4
            while size > 0 do
                local send_size = math.min(size, 256)

                local buf = string.rep(string.char(math.random(255)), send_size)
                ngx.print(buf)
                size = size - #buf
            end

            ngx.eof()
            ngx.exit( ngx.HTTP_OK )
        ';
    }
--- request
GET /t
--- response_body
4096
--- no_error_log
[error]

=== TEST 11: test keep-alive
--- http_config eval: $::HttpConfig
--- config

    client_body_buffer_size 10m;

    location /t {
        content_by_lua '
            local httpclient = require("acid.httpclient")

            local cli = httpclient:new( "127.0.0.1", ngx.var.server_port)
            cli:request( "/b", {headers = {Connection = "Keep-alive"}} )
            local body = cli:read_body(1024)

            ngx.say(cli.headers["connection"])
            local x, y = cli:set_keepalive(1000, 10)

            local cli = httpclient:new( "127.0.0.1", ngx.var.server_port)
            cli:request( "/b", {headers = {Connection = "Keep-alive"}} )
            ngx.say(cli:get_reused_times())

            return
        ';
    }

    location /b {
        keepalive_timeout 5;
        keepalive_requests 64;
        content_by_lua '
            ngx.say("OK")
        ';
    }
--- request
GET /t
--- response_body
keep-alive
1
--- no_error_log
[error]
