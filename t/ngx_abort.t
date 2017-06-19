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

=== TEST 1: add callback on client abort
--- http_config eval: $::HttpConfig
--- config
    location /t {
        lua_check_client_abort on;

        content_by_lua '
            local ngx_abort = require("acid.ngx_abort")

            local cb = function()
                ngx.log(ngx.INFO, "on abort callback called")
                ngx.exit(444)
            end

            local rst, err, errmes = ngx_abort.add_callback(cb)
            if err ~= nil then
                ngx.log(ngx.ERR, "add callback error")
            end

            ngx.sleep(1)
            ngx.log(ngx.INFO, "main coroutine done")
            return
        ';
    }
--- request
GET /t
--- timeout: 0.2
--- abort
--- ignore_response
--- no_error_log eval
[
    "add callback error",
    "main coroutine done"
]
--- error_log eval
[
    "client prematurely closed connection",
    "on abort callback called"
]

=== TEST 2: add multiple callbacks on client abort
--- http_config eval: $::HttpConfig
--- config
    location /t {
        lua_check_client_abort on;

        content_by_lua '
            local ngx_abort = require("acid.ngx_abort")

            local cb = function()
                ngx.log(ngx.INFO, "on abort one callback called")
            end

            local cb2 = function()
                ngx.log(ngx.INFO, "on abort two callback called")
            end

            local rst, err, errmes = ngx_abort.add_callback(cb)
            if err ~= nil then
                ngx.log(ngx.ERR, "add callback error")
            end

            local rst, err, errmes = ngx_abort.add_callback(cb2)
            if err ~= nil then
                ngx.log(ngx.ERR, "add callback error")
            end

            ngx.sleep(1)
            ngx.log(ngx.INFO, "main coroutine done")
            return
        ';
    }
--- request
GET /t
--- timeout: 0.2
--- abort
--- ignore_response
--- no_error_log eval
[
    "add callback1 error",
    "main coroutine done"
]
--- error_log eval
[
    "client prematurely closed connection",
    "on abort one callback called",
    "on abort two callback called"
]

=== TEST 3: add callback with args on client abort
--- http_config eval: $::HttpConfig
--- config
    location /t {
        lua_check_client_abort on;

        content_by_lua '
            local ngx_abort = require("acid.ngx_abort")
            local json = require("acid.json")

            local cb = function(...)
                ngx.log(ngx.INFO, "on abort callback called, args:", json.enc({...}))
                ngx.exit(444)
            end

            local rst, err, errmes = ngx_abort.add_callback(cb, "arg1", "arg2")
            if err ~= nil then
                ngx.log(ngx.ERR, "add callback error")
            end

            ngx.sleep(1)
            ngx.log(ngx.INFO, "main coroutine done")
            return
        ';
    }
--- request
GET /t
--- timeout: 0.2
--- abort
--- ignore_response
--- no_error_log eval
[
    "add callback error",
    "main coroutine done"
]
--- error_log eval
[
    'client prematurely closed connection',
    'on abort callback called, args:["arg1","arg2"]'
]

=== TEST 4: test log phase not allowed
--- http_config eval: $::HttpConfig
--- config
    location /t {
        lua_check_client_abort on;

        log_by_lua '
            local ngx_abort = require("acid.ngx_abort")

            local cb = function()
                ngx.log(ngx.INFO, "on abort callback called")
                ngx.exit(444)
            end

            local rst, err, errmes = ngx_abort.add_callback(cb)
            if err ~= nil then
                ngx.log(ngx.ERR, "add callback error. err:",
                 err, ", errmes:", errmes)
            end

            ngx.log(ngx.INFO, "main coroutine done")
            return
        ';
    }
--- request
GET /t
--- timeout: 0.2
--- abort
--- ignore_response
--- no_error_log eval
[
    "on abort callback called",
]
--- error_log eval
[
    "add callback error. err:InstallOnAbortError, errmes:log not allowed"
]

=== TEST 5: test remove callback
--- http_config eval: $::HttpConfig
--- config
    location /t {
        lua_check_client_abort on;

        content_by_lua '
            local ngx_abort = require("acid.ngx_abort")

            local cb = function()
                ngx.log(ngx.INFO, "on abort callback called")
            end

            local rst_cb, err, errmes = ngx_abort.add_callback(cb)
            if err ~= nil then
                ngx.log(ngx.ERR, "add callback error")
                return
            end

            local rst, err, errmes = ngx_abort.remove_callback(cb)
            if err ~= nil then
                ngx.log(ngx.ERR, "remove callback error")
                return
            end

            ngx.sleep(1)
            ngx.log(ngx.INFO, "main coroutine done")
            return
        ';
    }
--- request
GET /t
--- timeout: 0.2
--- abort
--- ignore_response
--- no_error_log eval
[
    "add callback error",
    "main coroutine done"
    "on abort callback called",
    "remove callback error",
]
--- error_log eval
[
    "client prematurely closed connection",
]

=== TEST 6: test install running callback
--- http_config eval: $::HttpConfig
--- config
    location /t {
        lua_check_client_abort on;

        content_by_lua '
            local ngx_abort = require("acid.ngx_abort")

            local is_run, err, errmsg = ngx_abort.install_running()
            if err ~= nil then
                ngx.log(ngx.ERR, "add callback error")
                return
            end

            while is_run() do
                ngx.sleep(0.01)
            end

            ngx.log(ngx.INFO, "main coroutine done")
            return
        ';
    }
--- request
GET /t
--- timeout: 0.2
--- abort
--- ignore_response
--- no_error_log eval
[
    "add callback error"
]
--- error_log eval
[
    "client prematurely closed connection",
    "main coroutine done"
]
