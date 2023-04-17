# vim:set ft=lua ts=4 sw=4 et:

use Test::Nginx::Socket 'no_plan';

use Cwd qw(cwd);
my $pwd = cwd();

no_long_string();

our $HttpConfig = qq{
    lua_package_path "$pwd/lib/?.lua;;";
    lua_package_cpath "$pwd/lib/?.so;;";
    init_worker_by_lua_block {
        local category_log = require('acid.category_log')
        local function get_category_file()
            return ngx.ctx.category_log_file
        end

        local opts = {
            get_category_file = get_category_file,
            max_repeat_n = 2,
            max_entry_n = 4,
        }
        category_log.wrap_log(opts)
    }

    log_by_lua_block {
        local category_log = require('acid.category_log')
        category_log.write_log()
    }
};

run_tests();

__DATA__

=== TEST 1: test original error log
--- http_config eval: $::HttpConfig
--- config
    location /t {
        lua_check_client_abort on;

        rewrite_by_lua_block {
            ngx.log(ngx.ERR, 'test_error_log', 'foo', 'bar')
            ngx.exit(ngx.HTTP_OK)
        }
    }

--- request
GET /t

--- error_log
test_error_logfoobar


=== TEST 2: test category log basic
--- http_config eval: $::HttpConfig
--- config
    location /t {
        lua_check_client_abort on;

        rewrite_by_lua_block {
            ngx.ctx.category_log_file = 'category_log_test_2.error.log'
            ngx.log(ngx.ERR, 'test_error_log', 'foo', 'bar')
            ngx.say('ok')
            ngx.exit(ngx.HTTP_OK)
        }
    }

    location /check_category_log {
        rewrite_by_lua_block {
            local log_file_name = 'category_log_test_2.error.log'
            os.execute('echo 3 > /proc/sys/vm/drop_caches')
            os.execute('sync')

            ngx.sleep(1)
            local f, err = io.open(log_file_name, 'r')
            if err ~= nil then
                ngx.say('open file error: ' .. err)
                ngx.exit(ngx.HTTP_OK)
            end

            local data = f:read('*a')

            local expected = 'test_error_log, foo, bar'
            local m, err = ngx.re.match(data, expected)
            if err ~= nil then
                ngx.say('ngx.re.match error: ' .. err)
                ngx.exit(ngx.HTTP_OK)
            end

            if m == nil then
                ngx.say('not match')
                ngx.exit(ngx.HTTP_OK)
            end

            if m[0] ~= expected then
                ngx.say('not in category log')
                ngx.exit(ngx.HTTP_OK)
            end

            ngx.say('check ok')

            os.remove(log_file_name)
            ngx.exit(ngx.HTTP_OK)
        }
    }

--- pipelined_requests eval
["GET /t", "GET /check_category_log"]

--- response_body eval
["ok\n", "check ok\n"]

--- timeout: 6000


=== TEST 3: test client abort
--- http_config eval: $::HttpConfig
--- config
    location /t {
        lua_check_client_abort on;

        rewrite_by_lua_block {
            local ok, err = ngx.on_abort(function ()
                ngx.log(ngx.ERR, 'on abort handler called')
                ngx.exit(ngx.HTTP_OK)
            end)

            if not ok then
                ngx.say('cannot set on abort: ' .. err)
                ngx.exit(ngx.HTTP_OK)
            end

            ngx.ctx.category_log_file = 'category_log_test_3.error.log'
            ngx.log(ngx.ERR, 'test_client_abort', 'foo', 'bar')
            ngx.sleep(1)
            ngx.exit(ngx.HTTP_OK)
        }
    }

--- request
GET /t

--- timeout: 0.6
--- abort
--- ignore_response


=== TEST 4: test max_entry_n and max_repeat_n
--- http_config eval: $::HttpConfig
--- config
    location /t {
        lua_check_client_abort on;

        rewrite_by_lua_block {
            ngx.ctx.category_log_file = 'category_log_test_4.error.log'

            ngx.log(ngx.ERR, 'only once log')

            for i = 1, 5 do
                ngx.log(ngx.ERR, 'repeat log1')
            end

            for i = 1, 5 do
                ngx.log(ngx.ERR, 'repeat log2')
            end

            ngx.say('ok')
            ngx.exit(ngx.HTTP_OK)
        }
    }

    location /check_category_log {
        rewrite_by_lua_block {
            local strutil = require('acid.strutil')
            local log_file_name = 'category_log_test_4.error.log'
            os.execute('echo 3 > /proc/sys/vm/drop_caches')
            os.execute('sync')

            ngx.sleep(1)
            local f, err = io.open(log_file_name, 'r')
            if err ~= nil then
                ngx.say('open file error: ' .. err)
                ngx.exit(ngx.HTTP_OK)
            end

            local data = f:read('*a')

            parts = strutil.split(data, "\n", {plain=true})
            if #parts - 1 ~=  5 then
                ngx.say('number fo lines is not 5')
                ngx.exit(ngx.HTTP_OK)
            end

            local m = ngx.re.match(parts[1], 'only once log')
            if m == nil then
                ngx.say('only once log not found')
                ngx.exit(ngx.HTTP_OK)
            end

            local m = ngx.re.match(parts[3], 'repeat log1')
            if m == nil then
                ngx.say('repeat log1 not found')
                ngx.exit(ngx.HTTP_OK)
            end

            local m = ngx.re.match(parts[4], 'repeat log2')
            if m == nil then
                ngx.say('repeat log2 not found')
                ngx.exit(ngx.HTTP_OK)
            end
            ngx.say('check ok')

            os.remove(log_file_name)
            ngx.exit(ngx.HTTP_OK)
        }
    }

--- pipelined_requests eval
["GET /t", "GET /check_category_log"]

--- response_body eval
["ok\n", "check ok\n"]

--- timeout: 6000


=== TEST 5: test log in timer
--- http_config eval: $::HttpConfig
--- config
    location /t {
        lua_check_client_abort on;

        rewrite_by_lua_block {
            ngx.ctx.category_log_file = 'category_log_test_5.error.log'

            local ok, err = ngx.timer.at(0, function()
                    ngx.log(ngx.ERR, 'log in timer')
                end)
            if not ok then
                ngx.say('set timer error: ' .. err)
                ngx.exit(ngx.HTTP_OK)
            end

            ngx.sleep(0.2)

            ngx.log(ngx.ERR, 'normal log')
            ngx.say('ok')
            ngx.exit(ngx.HTTP_OK)
        }
    }

    location /check_category_log {
        rewrite_by_lua_block {
            local log_file_name = 'category_log_test_5.error.log'
            os.execute('echo 3 > /proc/sys/vm/drop_caches')
            os.execute('sync')

            ngx.sleep(1)
            local f, err = io.open(log_file_name, 'r')
            if err ~= nil then
                ngx.say('open file error: ' .. err)
                ngx.exit(ngx.HTTP_OK)
            end

            local data = f:read('*a')

            local m = ngx.re.match(data, 'log in timer')
            if m ~= nil then
                ngx.say('log in timer should not in category log')
                ngx.exit(ngx.HTTP_OK)
            end

            local m = ngx.re.match(data, 'normal log')
            if m == nil then
                ngx.say('normal log not in category log')
                ngx.exit(ngx.HTTP_OK)
            end

            ngx.say('check ok')

            os.remove(log_file_name)
            ngx.exit(ngx.HTTP_OK)
        }
    }

--- pipelined_requests eval
["GET /t", "GET /check_category_log"]

--- response_body eval
["ok\n", "check ok\n"]

--- timeout: 6000
