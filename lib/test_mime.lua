local mime = require("acid.mime")

function test.by_fn(t)
    local cases = {
        { '', 'application/octet-stream' },
        { '123', 'application/octet-stream' },
        { '.123', 'application/vnd.lotus-1-2-3' },
        { 'file.123', 'application/vnd.lotus-1-2-3' },
        { 'file.123.not_exist_suffix_aa', 'application/octet-stream' },
        { 'file.json', 'application/json' },
        { 'file.not_exist_suffix_aa', 'application/octet-stream' },
        { 'file.123.json', 'application/json' },
    }
    for _, case in ipairs(cases) do
        local fn, mime_type = unpack(case)
        t:eq(mime_type, mime.by_fn(fn))
    end
end