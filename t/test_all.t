# vim:set ft=lua ts=4 sw=4 et ft=perl:

use Test::Nginx::Socket 'no_plan';

use Cwd qw(cwd);
my $pwd = cwd();

no_long_string();

our $HttpConfig = qq{
    lua_shared_dict shared_dict_lock 1m;
    lua_shared_dict test_shared 10m;

    lua_check_client_abort on;

    lua_package_path "$pwd/lib/?.lua;;";
    lua_package_cpath "$pwd/lib/?.so;;";
};

run_tests();

__DATA__

=== TEST 1: run all unittest in one
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local unittest = require("acid.unittest")
            unittest.ngx_test_modules({
                "test_empty",
                "test_logging",
                "test_net",
                "test_paxos",
                "test_proposer_acceptor",
                "test_repr",
                "test_round",
                "test_strutil",
                "test_tableutil",
                "test_json",
            })
        ';
    }
--- request
GET /t
--- response_body_like
.*tests all passed.*
--- no_error_log
[error]
