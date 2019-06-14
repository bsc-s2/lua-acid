local strutil = require("acid.strutil")

local _M = { _VERSION = "0.1" }

local to_str = strutil.to_str

function _M.assert_nwr_ok(nwr, oknum, idx)
    if oknum >= nwr[idx] then
        return true
    end

    return nil, "QuorumNotEnough", to_str('nwr=', nwr, ', oknum=', oknum, ', idx=', idx)
end

return _M
