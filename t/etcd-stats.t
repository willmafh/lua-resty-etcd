use Test::Nginx::Socket::Lua 'no_plan';

log_level('warn');
repeat_each(2);

our $HttpConfig = <<'_EOC_';
    lua_socket_log_errors off;
    lua_package_path '/usr/share/lua/5.1/?.lua;lib/?.lua;;';
    init_by_lua_block {
        function check_res(data, err)
            if err then
                ngx.say("err: ", err)
                ngx.exit(200)
            end
        end
    }
_EOC_

run_tests();

__DATA__

=== TEST 1: version
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local etcd, err = require "resty.etcd" .new()
            check_res(etcd, err)

            local res, err = etcd:version()
            check_res(res, err)

            ngx.say(res.body.etcdserver)
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body_like eval
qr{\d+.\d+.\d+}



=== TEST 2: statsLeader
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local etcd, err = require "resty.etcd" .new()
            check_res(etcd, err)

            local res, err = etcd:statsLeader()
            check_res(res, err)

            -- ngx.say(require "cjson" .encode(res.body))
            ngx.say("leader: ", res.body.leader)
            ngx.say("followers type: ", type(res.body.followers))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body_like
leader: \w+
followers type: table



=== TEST 3: statsSelf
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local etcd, err = require "resty.etcd" .new()
            check_res(etcd, err)

            local res, err = etcd:statsSelf()
            check_res(res, err)

            -- ngx.say(require "cjson" .encode(res.body))

            assert(res.body.id)
            assert(res.body.startTime)
            assert(res.body.leaderInfo)
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body



=== TEST 4: statsStore
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local etcd, err = require "resty.etcd" .new()
            check_res(etcd, err)

            local res, err = etcd:statsStore()
            check_res(res, err)

            -- ngx.log(ngx.WARN, require "cjson" .encode(res.body))

            assert(res.body.compareAndSwapFail)
            assert(res.body.updateFail)
            assert(res.body.getsFail)
            assert(res.body.setsFail)
            assert(res.body.deleteFail)
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
