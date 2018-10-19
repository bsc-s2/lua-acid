local sm3 = require("acid.sm3")
local resty_string = require("resty.string")

function test.sm3(t)

    local cases = {
        {
            '6e0f9e14344c5406a0cf5a3b4dfb665f87f4a771a31f7edbb5c72874a32b2957',
            {'123',}
        },
        {
            '66c7f0f462eeedd9d1f2d46bdc10e4e24167c4875cf2f7a2297da02b8f4ba8e0',
            {'abc',}
        },
        {
            '1ab21d8355cfa17f8e61194831e81a8f22bec8c728fefb747ed035eb5082aa2b',
            {'',}
        },
        {
            'ccf3035fdf3b0ed62133f93b852bec7dd9da55d286a9b61eeb409d57e657ff43',
            {'hello world hello word',}
        },
        {
            'ccf3035fdf3b0ed62133f93b852bec7dd9da55d286a9b61eeb409d57e657ff43',
            {'hello world ', 'hello word'},
        },
    }

    for _, case in ipairs(cases) do

        local exp, msgs = case[1], case[2]

        local mt = sm3:new()
        t:neq(nil, mt)

        for _, msg in ipairs(msgs) do
            t:eq(true, mt:update(msg))
        end

        t:eq(exp, resty_string.to_hex(mt:final()))
        t:eq(true, mt:reset())

    end
end
