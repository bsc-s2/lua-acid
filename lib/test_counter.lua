
local counter = require('acid.counter')


local dd  = test.dd


function _new_storage()
    local storage = {
        stat={
            incr=0,
            get=0,
        },
        tbl={},
    }

    storage.incr = function(self, key, val, init, init_ttl)
        self.stat.incr = self.stat.incr + 1
        local curr = (self.tbl[key] or {}).val or 0
        self.tbl[key] = {
            val=curr + val,
            expire_at=ngx.now() + init_ttl,
        }
    end

    storage.get = function(self, key)
        self.stat.get = self.stat.get + 1
        local curr = self.tbl[key]
        if curr == nil then
            return 0
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


function test.more_than_least_tps(t)
    local sto = _new_storage()

    local c = counter:new(sto, 1000, 0.1)
    -- c.timeout = 0.01

    for _ = 0, 20 do
        ngx.sleep(1/1200)
        c:incr('foo')
    end

    -- probability to call storage:incr is 0.1
    t:eq(true, c.storage.stat.incr >= 2)
    t:eq(true, c.storage.stat.incr <= 5)

    t:neq(0, c:get('foo'))
end


function test.less_than_least_tps(t)
    local sto = _new_storage()

    local c = counter:new(sto, 1000, 0.1)
    -- c.timeout = 0.01

    for _ = 0, 20 do
        c:incr('foo')
        ngx.sleep(1/800)
    end

    t:eq(0, c:get('foo'))
end
