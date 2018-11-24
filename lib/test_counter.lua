
local counter = require('acid.counter')


local dd  = test.dd


function _new_storage()
    local storage = {
        stat={
            set=0,
            get=0,
        },
        tbl={},
    }

    storage.set = function(self, key, val, expire)
        self.stat.set = self.stat.set + 1
        self.tbl[key] = {val=val, expire_at=ngx.now() + expire}

        return true
    end

    storage.get = function(self, key)
        self.stat.get = self.stat.get + 1
        local curr = self.tbl[key]
        if curr == nil then
            return nil
        end

        if ngx.now() > curr.expire_at then
            self.tbl[key] = nil
            return nil
        end
        return curr.val
    end

    return storage
end


function test.new(t)
    local sto = _new_storage()
    local c = counter:new(sto, 2, 0.5)
    t:eq(1, c.timeout)
    t:eq(2, c.least_tps)
    t:eq(0.5, c.probability)

    local c = counter:new(sto, 200, 0.02)
    t:eq(0.25, c.timeout)
end


function test.least_tps(t)

    for i, tps, expected_left, expected_right, desc in t:case_iter(3, {
        {800, 0, 100, 'tps < 1000 will not be recorded'},
        {1200, 1000, 1400, 'tps > 1000 will be recorded'},
    }) do

        local sto = _new_storage()

        local p = 0.05
        local n = 1000
        local c = counter:new(sto, 1000, p)
        -- c.timeout = 0.01

        for _ = 0, n do
            ngx.sleep(1 / tps)
            c:incr('foo')
        end

        local rst = c:get('foo')
        dd('curr tps:', rst)

        t:eq(true, expected_left <= rst)
        t:eq(true, rst <= expected_right)

        -- probability to call storage:incr is 0.1
        dd('N.O. of set:', c.storage.stat.set)
        dd(p * n * 0.8)
        dd(p * n * 1.2)
        t:eq(true, c.storage.stat.set >= p * n * 0.8)
        t:eq(true, c.storage.stat.set <= p * n * 1.2)
    end

end
