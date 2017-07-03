local json = require( "acid.json" )
local cjson = require( "cjson" )

function test.enc(t)
    local cases = {
            {nil , nil, 'null'},
            {{}, nil, '{}'},
            {{}, {is_array=true}, '[]'},
            {{1, "2"}, nil, cjson.encode({1, "2"})},
            {{a=1, b='2', c={c1=1}}, nil, cjson.encode({a=1, b='2', c={c1=1}})},
        }

    for _, case in ipairs(cases) do
        local j, opt, exp = unpack(case)
        t:eq(json.enc(j, opt), exp)
    end
end

function test.dec(t)
    local cases = {
            {nil, nil, nil},
            {'{"a":1, "b":2}', nil, {a=1, b=2}},
            {'{"a":1, "b":2, "c":null}', nil, {a=1, b=2}},
            {'{"a":1, "b":2, "c":null}', {use_nil=false}, {a=1, b=2, c=cjson.null}},
        }

    for _, case in ipairs(cases) do
        local j, opt, exp = unpack(case)
        t:eqdict(json.dec(j, opt), exp)
    end
end
