local errno = require("acid.errno")

function test.errno(t)
    t:eq(1, errno.EPERM)
    t:eq(2, errno.ENOENT)
    t:eq(11, errno.EAGAIN)
    t:eq(122, errno.EDQUOT)
end

