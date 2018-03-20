local ngx_timer = require('acid.ngx_timer')


function test.at(t)
    local r = {}
    local func = function(a, b, c)
        table.insert(r, a)
        table.insert(r, b)
        table.insert(r, c)
    end

    local _, err, errmsg = ngx_timer.at(0.1, func, 1, 2, 3)
    t:eq(nil, err, errmsg)

    ngx.sleep(0.5)
    t:eqdict({1, 2, 3} ,r)
end


function test.every(t)
    local r = {}
    local func = function(v)
        table.insert(r, v)
    end

    local _, err, errmsg = ngx_timer.every(0.2, func, 3)
    t:eq(nil, err, errmsg)

    ngx.sleep(0.5)
    t:eqdict({3, 3} ,r)
end
