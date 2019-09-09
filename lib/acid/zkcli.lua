local strutil      = require("acid.strutil")
local struct       = require("acid.struct")
local bit          = require("bit")
local hashlib      = require('acid.hashlib')
local rpc_logging  = require('acid.rpc_logging')

local _M = { _VERSION = '1.0' }
local mt = { __index  = _M }

local char         = string.char
local bor          = bit.bor
local band         = bit.band
local to_str       = strutil.to_str
local zero_4bytes  = string.rep(char(0), 4)
local zero_8bytes  = string.rep(char(0), 8)
local zero_16bytes = string.rep(char(0), 16)

_M.zk_err = {
    [-1]   = "SystemZookeeperError",
    [-2]   = "RuntimeInconsistency",
    [-3]   = "DataInconsistency",
    [-4]   = "ConnectionLoss",
    [-5]   = "MarshallingError",
    [-6]   = "UnimplementedError",
    [-7]   = "OperationTimeoutError",
    [-8]   = "BadArgumentsError",
    [-13]  = "NewConfigNoQuorumError",
    [-14]  = "ReconfigInProcessError",
    [-100] = "APIError",
    [-101] = "NoNodeError",
    [-102] = "NoAuthError",
    [-103] = "BadVersionError",
    [-108] = "NoChildrenForEphemeralsError",
    [-110] = "NodeExistsError",
    [-111] = "NotEmptyError",
    [-112] = "SessionExpiredError",
    [-113] = "InvalidCallbackError",
    [-114] = "InvalidACLError",
    [-115] = "AuthFailedError",
    [-118] = "SessionMovedError",
    [-119] = "NotReadOnlyCallError",
}

_M.watch_xid = -1
_M.ping_xid  = -2
_M.auth_xid  = -4


local function perm_to_num(perm)
    local num = 0
    for i=1, #perm do
        local b = perm:sub(i, i)
        if b == 'c' then num = bor(num, 4)  end     -- create
        if b == 'd' then num = bor(num, 8)  end     -- delete
        if b == 'r' then num = bor(num, 1)  end     -- read
        if b == 'w' then num = bor(num, 2)  end     -- write
        if b == 'a' then num = bor(num, 16) end     -- admin
    end

    return num
end


local function num_to_perm(num)
    local perm = ''
    if band(num, 4) == 4   then perm = perm .. 'c' end
    if band(num, 8) == 8   then perm = perm .. 'd' end
    if band(num, 1) == 1   then perm = perm .. 'r' end
    if band(num, 2) == 2   then perm = perm .. 'w' end
    if band(num, 16) == 16 then perm = perm .. 'a' end

    return perm
end


local function normalize_path(path)
    if not strutil.startswith(path, '/') then
        path = '/' .. path
    end

    return (string.gsub(path, '/+', '/'))
end


local function make_acls(acls)
    if acls == nil then
        return {{"cdrwa", "world", "anyone"}}
    end

    local rst = {}
    for _, a in ipairs(acls) do
        local username, pwd = a[2], a[3]
        local cred = username .. ":" .. pwd
        local sha1 = hashlib.sha1()
        sha1:update(cred)
        local sha1_cred = sha1:final()
        table.insert(rst, {a[1], 'digest', username .. ":" .. ngx.encode_base64(sha1_cred)})
    end

    return rst
end


local function pack_acls(acls)
    local rst = {}
    local cnt, err, errmsg = struct.pack_int32(#acls)
    if err ~= nil then
        return nil, err, errmsg
    end
    table.insert(rst, cnt)
    for _, a in ipairs(acls) do
        local perm, scheme, cred = perm_to_num(a[1]), a[2], a[3]
        local s, err, errmsg = struct.pack('>iSS', perm, scheme, cred)
        if err ~= nil then
            return nil, err, errmsg
        end
        table.insert(rst, s)
    end

    return table.concat(rst)
end


local function znode_stat(buffer)
    local st, err, errmsg = struct.unpack('>8s8s8s8siii8sii8s', buffer)
    if err ~= nil then
        return nil, err, errmsg
    end
    return {
        czxid           = st[1],
        mzxid           = st[2],
        ctime           = st[3],
        mtime           = st[4],
        version         = st[5],
        cversion        = st[6],
        aversion        = st[7],
        ephemeral_owner = st[8],
        data_length     = st[9],
        num_children    = st[10],
        pzxid           = st[11],
    }
end


local conn_req_mt = {
    __index = {
        deserialize = function(buffer)
            local res, err, errmsg = struct.unpack('>ii8sS', buffer)
            if err ~= nil then
                return nil, err, errmsg
            end
            -- don't have read_only(1 char) in zookeeper ver <= 3.3.5
            struct.unpack('1s', buffer)

            return {
                timeout    = res[2],
                session_id = res[3],
                pwd        = res[4],
            }
        end
    }
}


local function connect_req(zxid, timeout, session_id, pwd, read_only)
    local args = {zero_4bytes, zxid or zero_8bytes, timeout, session_id
        or zero_8bytes, pwd, read_only and char(1) or char(0)}

    local req = {
        args = args,
        pack_format = '>ssisSs',
    }

    return setmetatable(req, conn_req_mt)
end


local function ping_req()
    return {
        _type = 11,
        args = {},
        pack_format = '',
    }
end


local function auth_req(auth_type, scheme, credential)
    return {
        _type = 100,
        args = {auth_type, scheme, credential},
        pack_format = '>iSS',
    }
end


local get_req_mt = {
    __index = {
        deserialize = function(buffer)
            local data, err, errmsg = struct.unpack_string(buffer)
            if err ~= nil then
                return nil, err, errmsg
            end
            local st, err, errmsg = znode_stat(buffer)
            if err ~= nil then
                return nil, err, errmsg
            end
            return {data, st}
        end
    }
}


local function get_req(path, watch)
    local req = {
        _type = 4,
        args = {normalize_path(path), char(watch and 1 or 0)},
        pack_format = 'Ss',
    }

    return setmetatable(req, get_req_mt)
end


local get_children_req_mt = {
    __index = {
        deserialize = function(buffer)
            local cnt, err, errmsg = struct.unpack_int32(buffer)
            if err ~= nil then
                return nil, err, errmsg
            end

            local rst = {}
            if cnt <= 0 then
                return rst
            end

            for _ = 1, cnt do
                local child, err, errmsg = struct.unpack_string(buffer)
                if err ~= nil then
                    return nil, err, errmsg
                end
                table.insert(rst, child)
            end

            return rst
        end
    }
}


local function get_children_req(path)
    local req = {
        _type = 8,
        args = {normalize_path(path), char(0)},
        pack_format = 'Ss',
    }

    return setmetatable(req, get_children_req_mt)
end


local set_req_mt = {
    __index = {
        deserialize = znode_stat,
    }
}


local function set_req(path, value, version)
    local req = {
        _type = 5,
        args = {normalize_path(path), value, version or -1},
        pack_format = '>SSi',
    }

    return setmetatable(req, set_req_mt)
end


local create_req_mt = {
    __index = {
        deserialize = struct.unpack_string,
    }
}


local function create_req(path, value, acls, ephemeral, sequence)
    local flags = 0
    acls = make_acls(acls)
    if ephemeral then flags = bor(flags, 1) end
    if sequence  then flags = bor(flags, 2) end
    local pacls, err, errmsg = pack_acls(acls)
    if err ~= nil then
        return nil, "PackAclsError", err .. ',' .. errmsg
    end

    local req = {
        _type = 1,
        args = {normalize_path(path), value or '', pacls, flags},
        pack_format = '>SSsi',
    }

    return setmetatable(req, create_req_mt)
end


local delete_req_mt = {
    __index = {
        deserialize = function() return true end
    }
}


local function delete_req(path, version)
    local req = {
        _type = 2,
        args = {normalize_path(path), version or -1},
        pack_format = '>Si',
    }

    return setmetatable(req, delete_req_mt)
end


local get_acls_req_mt = {
    __index = {
        deserialize = function(buffer)
            local rst = {}
            local cnt, err, errmsg = struct.unpack_int32(buffer)
            if err ~= nil then
                return nil, err, errmsg
            end
            if cnt <= 0 then
                return rst
            end

            for _ = 1, cnt do
                local unpack_res, err, errmsg = struct.unpack('>iSS', buffer)
                if err ~= nil then
                    return nil, err, errmsg
                end
                table.insert(rst, {num_to_perm(unpack_res[1]), unpack_res[2], unpack_res[3]})
            end

            local st, err, errmsg = znode_stat(buffer)
            if err ~= nil then
                return nil, err, errmsg
            end

            return {rst, st}
        end
    }
}


local function get_acls_req(path)
    local req = {
        _type = 6,
        args = {normalize_path(path)},
        pack_format = 'S',
    }

    return setmetatable(req, get_acls_req_mt)
end


local set_acls_req_mt = set_req_mt
local function set_acls_req(path, acls, version)
    acls = make_acls(acls)
    local pacls, err, errmsg = pack_acls(acls)
    if err ~= nil then
        return nil, "PackAclsError", err .. ',' .. errmsg
    end

    local req = {
        _type = 7,
        args = {normalize_path(path), pacls, version or -1},
        pack_format = '>Ssi',
    }

    return setmetatable(req, set_acls_req_mt)
end


local function normalize_hosts(hosts)
    if type(hosts) == 'table' then
        return hosts
    end

    if type(hosts) == 'string' then
        local rst = {}
        local parts = strutil.split(hosts, ',')
        for _, part in ipairs(parts) do
            local host_port = strutil.split(part, ':')
            table.insert(rst, {host_port[1], host_port[2]})
        end
        return rst
    end

    return nil, 'InvalidHosts', to_str('only support table or string got:', type(hosts))
end


local function read_header(sock)
    local res, err, errmsg
    res, err = sock:receive(4)
    if err ~= nil then
        return nil, 'RecvHeaderLenError', err
    end

    local len = struct.unpack_int32({stream=res, offset=1})
    res, err = sock:receive(len)
    if err ~= nil then
        return nil, 'RecvHeaderError', err
    end

    local unpack_res
    local buffer = {stream=res, offset=1}
    unpack_res, err, errmsg = struct.unpack('>i8si', buffer)
    if err ~= nil then
        return nil, 'UnpackHeaderError', err .. ',' .. errmsg
    end

    local header = {
        xid = unpack_res[1],
        zxid = unpack_res[2],
        err = unpack_res[3],
    }

    return {header, buffer}
end


local function send_request(sock, req, xid)
    local msg = ''
    if xid ~= nil then
        msg = msg .. struct.pack_int32(xid)
    end

    if req._type ~= nil then
        msg = msg .. struct.pack_int32(req._type)
    end

    local req_str, err, errmsg = struct.pack(req.pack_format, unpack(req.args))
    if err ~= nil then
        return nil, 'PackReqError', err .. ',' .. errmsg
    end

    msg = msg .. req_str
    local _, err = sock:send(struct.pack_int32(#msg) .. msg)
    if err ~= nil then
        return nil, "SocketSendError", err
    end
end


function _M._get_xid(self)
    self.xid = self.xid % (2 ^ 31 - 1) + 1
    return self.xid
end


function _M.submit(self, req)
    local _, err, errmsg = self:start()
    if err ~= nil then
        return nil, err, errmsg
    end

    rpc_logging.reset_start(self.log)
    local _, err, errmsg = send_request(self.sock, req, self:_get_xid())
    if err ~= nil then
        rpc_logging.set_err(self.log, err .. ',' .. errmsg)
        return nil, "SendReqError", err .. "," .. errmsg
    end
    rpc_logging.incr_time(self.log, 'upstream', 'send')
    rpc_logging.reset_start(self.log)

    local rst, err, errmsg = self:read_response(req, self.xid)
    if err ~= nil then
        rpc_logging.set_err(self.log, err .. ',' .. errmsg)
        return nil, err, errmsg
    end
    rpc_logging.incr_time(self.log, 'downstream', 'recv')

    return rst
end


function _M.connect(self, ip, port)
    local _, err, errmsg
    _, err = self.sock:connect(ip, port)
    if err ~= nil then
        rpc_logging.set_err(self.log, err)
        return nil , 'SocketConnectError', to_str("conn:", err)
    end
    rpc_logging.set_time(self.log, 'upstream', 'conn')
    rpc_logging.reset_start(self.log)

    local conn_req = connect_req(self.zxid, self.conn_timeout, self.session_id, self.pwd, self.read_only)
    _, err, errmsg = send_request(self.sock, conn_req)
    if err ~= nil then
        rpc_logging.set_err(self.log, err .. ',' .. errmsg)
        return nil, 'SendConnectReqError', err .. "," .. errmsg
    end
    rpc_logging.incr_time(self.log, 'upstream', 'send')
    rpc_logging.reset_start(self.log)

    local res
    res, err = self.sock:receive(4)
    if err ~= nil then
        rpc_logging.set_err(self.log, err)
        return nil, 'RecvConnectResLenError', err
    end
    rpc_logging.incr_time(self.log, 'downstream', 'recv')

    local len = struct.unpack_int32({stream=res, offset=1})
    res, err = self.sock:receive(len)
    if err ~= nil then
        return nil, 'RecvConnectResError', err
    end

    res, err, errmsg = conn_req.deserialize({stream=res, offset=1})
    if err ~= nil then
        return nil, err, errmsg
    end

    self.keepalive_timeout = math.floor(res.timeout / 2)
    self.session_id = res.session_id
    self.pwd = res.pwd
end


function _M.start(self)
    local err, errmsg
    for _, host_port in ipairs(self.hosts) do
        self.log = rpc_logging.new_entry(self.log_service, {ip=host_port[1], port=host_port[2]})
        rpc_logging.add_log(self.log)

        local ip, port = host_port[1], host_port[2]
        _, err, errmsg = self:connect(ip, port)
        if err == nil then
            break
        end
    end

    if err ~= nil then
        return nil, 'ConnServerError', err .. "," .. errmsg
    end

    for _, auth in ipairs(self.auth_data) do
        local req = auth_req(0, auth[1], auth[2])

        rpc_logging.reset_start(self.log)
        _, err ,errmsg = send_request(self.sock, req, self.auth_xid)
        if err ~= nil then
            rpc_logging.set_err(self.log, err .. ',' .. errmsg)
            return nil, err, errmsg
        end
        rpc_logging.incr_time(self.log, 'upstream', 'send')
        rpc_logging.reset_start(self.log)

        _, err, errmsg = self:read_response(req, self.auth_xid)
        if err ~= nil then
            rpc_logging.set_err(self.log, err .. ',' .. errmsg)
            return nil, err, errmsg
        end
        rpc_logging.incr_time(self.log, 'downstream', 'recv')
    end
end


function _M.setkeepalive(self, timeout, size)
    local _, errmsg = self.sock:setkeepalive(timeout, size)
    if errmsg ~= nil then
        return nil, 'SocketError', to_str('set keepalive:', errmsg)
    end
end


function _M.close(self)
    local _, errmsg = self.sock:close()
    if errmsg ~= nil then
        return nil, 'SocketError', to_str('close:', errmsg)
    end
end


function _M.read_response(self, req, xid)
    local h, err, errmsg = read_header(self.sock)
    if err ~= nil then
        return nil, err, errmsg
    end

    local header, buffer = h[1], h[2]
    if header.xid ~= xid then
        return nil, "XidMismatch", to_str("expected:", xid, " got:", header.xid)
    end

    if header.zxid ~= zero_8bytes then
        self.zxid = header.zxid
    end

    if header.err ~= 0 then
        return nil, self.zk_err[header.err] or "UnknownError", to_str("code:", header.err)
    end

    if req.deserialize ~= nil then
        return req.deserialize(buffer)
    end
end


function _M.send_ping(self)
    local req = ping_req()
    local _, err, errmsg = send_request(self.sock, req, self.ping_xid)
    if err ~= nil then
        return nil, "SendPingReqError", err .. ',' .. errmsg
    end

    return self:read_response(req, self.ping_xid)
end


-- don't keep connection with zookeeper, so don't support ephemeral
function _M.create(self, path, value, acls, sequence)
    return self:submit(create_req(path, value, acls, false, sequence))
end


function _M._get(self, path, watch)
    return self:submit(get_req(path, watch))
end


function _M.get(self, path)
    return self:_get(path)
end


function _M.get_children(self, path)
    return self:submit(get_children_req(path))
end


function _M.get_acls(self, path)
    return self:submit(get_acls_req(path))
end


function _M.get_next(self, path, version, timeout)
    local res, err, errmsg = self:_get(path, true)
    if err ~= nil then
        return nil, err, errmsg
    end

    local stat = res[2]
    if version == nil then
        version = -1
    end
    if stat.version > version then
        return res
    end

    -- defaults to one year in ms
    if timeout == nil then
        timeout = 365 * 86400 * 1000
    end
    local start_time = ngx.now() * 1000
    self.sock:settimeouts(self.conn_timeout, self.send_timeout, self.keepalive_timeout)
    while (ngx.now() * 1000 - start_time <= timeout) do
        local h, err, errmsg = read_header(self.sock)

        if err == nil then
            local header = h[1]
            if header.xid ~= self.watch_xid then
                return nil, 'WatchXidMismatch', to_str("expected:", self.watch_xid, " got:", header.xid)
            end
            return self:get(path)
        else
            if errmsg == 'timeout' then
                local _, err, errmsg = self:send_ping()
                if err ~= nil then
                    return nil, err, errmsg
                end
            else
                return nil, err, errmsg
            end
        end
    end

    return nil, 'GetNextTimeout', to_str('timeout for ', timeout, 'ms')
end


function _M.set(self, path, value, version)
    return self:submit(set_req(path, value, version))
end


function _M.set_acls(self, path, acls, version)
    return self:submit(set_acls_req(path, acls, version))
end


function _M.delete(self, path, version)
    return self:submit(delete_req(path, version))
end


function _M.add_auth(self, scheme, credential)
    table.insert(self.auth_data, {scheme, credential})
end


function _M.new(_, hosts, timeout, auth_data, opts)
    local err, errmsg

    if opts == nil then
        opts = {}
    end
    if hosts == nil then
        hosts = '127.0.0.1:2181'
    end
    if timeout == nil then
        timeout = 10000
    end

    hosts, err, errmsg = normalize_hosts(hosts)
    if err ~= nil then
        return nil, err, errmsg
    end

    if #hosts == 0 then
        return nil, "HostNotFound", to_str(hosts)
    end

    local conn_timeout, send_timeout, read_timeout
    if type(timeout) == 'table' then
        conn_timeout, send_timeout, read_timeout = timeout[1], timeout[2], timeout[3]
    else
        conn_timeout, send_timeout, read_timeout = timeout, timeout, timeout
    end

    local sock = ngx.socket.tcp()
    sock:settimeouts(conn_timeout, send_timeout, read_timeout)

    return setmetatable({
        sock = sock,
        hosts = hosts,
        conn_timeout = conn_timeout,
        send_timeout = send_timeout,
        read_timeout = read_timeout,
        keepalive_timeout = 300,
        auth_data = auth_data or {},
        read_only = opts.read_only,
        pwd = zero_16bytes,
        xid = 0,
        log_service = 'zookeeper',
    }, mt)
end

return _M
