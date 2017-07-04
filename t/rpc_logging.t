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

=== TEST 1: basic
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local rpc_logging = require("acid.rpc_logging")

            local ip = "127.0.0.1"
            local port = 80
            local uri = "/basic/rpc_log"

            local send_body_size = 128
            local recv_body_size = 128
            local status = 200

            ngx.sleep(0.001)

            rpc_log = rpc_logging.new_entry("basic", {
                ip = ip,
                port = port,
                uri = uri,
            })

            rpc_logging.add_log(rpc_log)

            rpc_logging.reset_start(rpc_log)
            ngx.sleep(0.001)
            rpc_logging.set_time(rpc_log, "upstream", "conn")

            rpc_logging.reset_start(rpc_log)
            ngx.sleep(0.001)
            rpc_logging.set_time(rpc_log, "upstream", "send")

            rpc_logging.reset_start(rpc_log)
            ngx.sleep(0.001)
            rpc_logging.incr_time(rpc_log, "upstream", "recv")

            rpc_logging.reset_start(rpc_log)
            ngx.sleep(0.001)
            rpc_logging.incr_time(rpc_log, "upstream", "recvbody")

            rpc_logging.incr_byte(rpc_log,
                 "upstream", "sendbody", send_body_size)
            rpc_logging.incr_byte(rpc_log,
                 "upstream", "recvbody", recv_body_size)

            rpc_logging.set_status(rpc_log, status)

            local str = rpc_logging.entry_str(rpc_log)
            ngx.say(str)
            return
        ';
    }
--- request
GET /t
--- response_body_like chomp
basic,status:200,url:127.0.0.1:80/basic/rpc_log,start_in_req:(0|0.00\d),upstream:{time:{conn:0.00\d,send:0.00\d,recv:0.00\d,recvbody:0.00\d},byte:{sendbody:128,recvbody:128},},downstream:{time:{},byte:{},}
--- no_error_log
[error]

=== TEST 2: test dowstream log
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local rpc_logging = require("acid.rpc_logging")

            local ip = "127.0.0.1"
            local port = 80
            local uri = "/basic/rpc_log"

            local send_body_size = 128
            local recv_body_size = 128
            local status = 200

            ngx.sleep(0.001)
            rpc_log = rpc_logging.new_entry("basic", {
                ip = ip,
                port = port,
                uri = uri,
            })

            rpc_logging.add_log(rpc_log)

            rpc_logging.reset_start(rpc_log)
            ngx.sleep(0.001)
            rpc_logging.set_time(rpc_log, "downstream", "conn")

            rpc_logging.reset_start(rpc_log)
            ngx.sleep(0.001)
            rpc_logging.set_time(rpc_log, "downstream", "send")

            rpc_logging.reset_start(rpc_log)
            ngx.sleep(0.001)
            rpc_logging.incr_time(rpc_log, "downstream", "recv")

            rpc_logging.reset_start(rpc_log)
            ngx.sleep(0.001)
            rpc_logging.incr_time(rpc_log, "downstream", "recvbody")

            rpc_logging.incr_byte(rpc_log,
                 "downstream", "sendbody", send_body_size)
            rpc_logging.incr_byte(rpc_log,
                 "downstream", "recvbody", recv_body_size)

            rpc_logging.set_status(rpc_log, status)

            local str = rpc_logging.entry_str(rpc_log)
            ngx.say(str)
            return
        ';
    }
--- request
GET /t
--- response_body_like chomp
basic,status:200,url:127.0.0.1:80/basic/rpc_log,start_in_req:(0|0.00\d),upstream:{time:{},byte:{},},downstream:{time:{conn:0.00\d,send:0.00\d,recv:0.00\d,recvbody:0.00\d},byte:{sendbody:128,recvbody:128},}
--- no_error_log
[error]

=== TEST 3: test empty log
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local rpc_logging = require("acid.rpc_logging")

            ngx.sleep(0.001)
            rpc_log = rpc_logging.new_entry("empty_log")

            rpc_logging.add_log(rpc_log)

            local str = rpc_logging.entry_str(rpc_log)
            ngx.say(str)
            return
        ';
    }
--- request
GET /t
--- response_body_like chomp
empty_log,url:,start_in_req:(0|0.00\d),upstream:{time:{},byte:{},},downstream:{time:{},byte:{},}
--- no_error_log
[error]

=== TEST 4: test multiple rpc log
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local rpc_logging = require("acid.rpc_logging")

            local ip = "127.0.0.1"
            local port = 80
            local uri = "/basic/rpc_log"

            local send_body_size = 128
            local recv_body_size = 128
            local status = 200

            rpc_log = rpc_logging.new_entry("rpc_log1",{
                ip = ip,
                port = port,
                uri = uri,
            })

            rpc_logging.add_log(rpc_log)

            ip = "127.0.0.2"
            port = 81
            uri = "/basic/rpc_log2"

            send_body_size = 256
            recv_body_size = 256
            status = 200

            rpc_log = rpc_logging.new_entry("rpc_log2",{
                ip = ip,
                port = port,
                uri = uri,
            })
            rpc_logging.add_log(rpc_log)

            local str = rpc_logging.log_str()
            ngx.say(str)
            return
        ';
    }
--- request
GET /t
--- response_body_like chomp
rpc_log1,url:127.0.0.1:80/basic/rpc_log,start_in_req:(0|0.00\d),upstream:{time:{},byte:{},},downstream:{time:{},byte:{},} rpc_log2,url:127.0.0.2:81/basic/rpc_log2,start_in_req:(0|0.00\d),upstream:{time:{},byte:{},},downstream:{time:{},byte:{},}
--- no_error_log
[error]
