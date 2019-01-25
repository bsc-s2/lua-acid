local tableutil = require('acid.tableutil')

local _M = {
    inner_ip_patterns = {
        '^172[.]1[6-9].*',
        '^172[.]2[0-9].*',
        '^172[.]3[0-1].*',
        '^10[.].*',
        '^192[.]168[.].*',
    }
}

-- try to load config from a top-level module.
local ok, acidconf = pcall(require, 'acidconf')

if ok and type(acidconf) == 'table' then
    for k, v in pairs(acidconf) do
        _M[k] = tableutil.dup(v, true)
    end
end

return _M
