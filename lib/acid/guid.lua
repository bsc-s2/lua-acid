local time = require("acid.time")
local typeutil = require("acid.typeutil")

local _M = {}
local mt = { __index = _M }

-- guid format:
--     1451577623124010001
--     tttttttttttttssmmmm
--
-- t: is a number representing the current timestamp
-- s: is a number representing sequence id
-- m: is a number representing the unique machine id of cluster
-- the machine id to ensure the machine between the one and only in cluster,
-- and sequence number to ensure the single only

local max_len_ts = 13

local function next_seq(self, timestamp)
    local seq, err_msg = self.guid_dict:incr(timestamp, 1)
    if err_msg == nil then
        return seq
    end

    seq = 0
    local is_ok = self.guid_dict:safe_add(timestamp, seq, self.key_exptime)
    if is_ok == true then
        return seq
    end

    seq, err_msg = self.guid_dict:incr(timestamp, 1)
    if err_msg == nil then
        return seq
    end

    return nil, 'IncrSequenceError', err_msg
end


function _M.new(shared_guid, shared_lock, len_ts, len_seq, len_mid)
    if ngx.shared[shared_guid] == nil or ngx.shared[shared_lock] == nil then
        return nil, 'NoSharedDict', string.format(
            'shared dict is not exists: %s,%s', shared_guid, shared_lock)
    end

    if not typeutil.check_integer_range(len_ts, 1, max_len_ts)
        or not typeutil.check_integer_range(len_seq, 1)
        or not typeutil.check_integer_range(len_mid, 1) then

        return nil, 'InvalidLength', string.format(
            'lengths of guid parts are not integer or beyond range, %s, %s, %s',
            tostring(len_ts), tostring(len_seq), tostring(len_mid))
    end

    local unit_ms = math.pow(10, max_len_ts - len_ts)
    local key_exptime = math.max(60, 2 * unit_ms / 1000)

    local guid = {
        guid_dict = ngx.shared[shared_guid],
        lock_guid_dict = ngx.shared[shared_lock],

        len_ts   = len_ts,
        len_seq  = len_seq,
        len_mid  = len_mid,
        len_guid = len_ts + len_seq +len_mid,

        max_seq = math.pow(10, len_seq) - 1,
        max_mid = math.pow(10, len_mid) - 1,

        unit_ms = unit_ms,
        key_exptime = key_exptime,

        id_pattern = string.format("%%%dd%%0%dd%%0%dd", len_ts, len_seq, len_mid),
        parse_pattern = string.format('^([0-9]{%d})([0-9]{%d})([0-9]{%d})$',
            len_ts, len_seq, len_mid),
    }

    return setmetatable(guid, mt)
end


function _M.generate(self, mid, max_wait_ms)
    max_wait_ms = max_wait_ms or 500

    if not typeutil.check_integer_range(mid, 0, self.max_mid) then
        return nil, 'InvalidMachineId', string.format(
            'mid %s is beyond range [0, %d]', tostring(mid), self.max_mid)
    end

    while true do
        local ts = time.get_time()
        local ms = ts.seconds * 1000 + ts.milliseconds
        local timestamp = math.floor(ms / self.unit_ms)

        local seq, err, err_msg = next_seq(self, timestamp)
        if err ~= nil then
            return nil, err, err_msg
        end

        if seq <= self.max_seq and ngx.time()-ts.seconds < self.key_exptime then
            return string.format(self.id_pattern, timestamp, seq, mid)
        end

        local next_ms = (timestamp + 1) * self.unit_ms
        local sleep_ms = math.max(next_ms - ms, 1)

        if sleep_ms > max_wait_ms then
            break
        end

        ngx.sleep(sleep_ms / 1000)
        max_wait_ms = max_wait_ms - sleep_ms
    end

    return nil, 'MakeTimeOut', 'make guid timeout'
end


function _M.parse(self, guid)
    if type(guid) ~= 'string' then
        return nil, 'NotString', 'the guid is not a string: ' .. type(guid)
    end

    local guid_tb = ngx.re.match(guid, self.parse_pattern, 'o')

    if guid_tb == nil then
        return nil, 'InvalidGuid', string.format(
            'guid %s is not number string or length not %d', guid, self.len_guid)
    end

    local t = {
        ts  = tonumber(guid_tb[1]),
        seq = tonumber(guid_tb[2]),
        mid = tonumber(guid_tb[3])
    }

    return t
end

return _M
