
local counter = require('acid.counter')


local dd  = test.dd


function _new_storage()
    local storage = {
        tbl={}
    }

    storage.incr = function(self, key, val, init, init_ttl)
        local curr = (self.tbl[key] or {}).val or 0
        self.tbl[key] = {
            val=curr + val,
            expire_at=ngx.now() + init_ttl,
        }
    end

    storage.get = function(self, key)
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
    t:eq(0.5, c.timeout)
    t:eq(2, c.least_tps)
    t:eq(1, c.probability)

    local c = counter:new(sto, 200, 0.02)
    t:eq(0.25, c.probability)

    -- min value
    local c = counter:new(sto, 2000 * 2000 * 2000)
    t:eq(0.001 * 0.001, c.probability)
end


function test.more_than_least_tps(t)
    local sto = _new_storage()

    local c = counter:new(sto, 1000)
    -- c.probability = 0.1

    for _ = 0, 20 do
        c:incr('foo')
        ngx.sleep(1/1200)
    end

    t:neq(0, c:get('foo'))
end


function test.less_than_least_tps(t)
    local sto = _new_storage()

    local c = counter:new(sto, 1000)
    -- c.probability = 0.1

    for _ = 0, 20 do
        c:incr('foo')
        ngx.sleep(1/800)
    end

    t:eq(0, c:get('foo'))
end
