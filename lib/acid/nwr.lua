local strutil = require("acid.strutil")

local _M = { _VERSION = "0.1" }

local to_str = strutil.to_str

function _M.assert_w_ok(nwr, wok)
    if wok >= nwr[2] then
        return true
    end

    return nil, "QuorumNotEnough", to_str('nwr=', nwr, ', wok=', wok)
end

return _M
