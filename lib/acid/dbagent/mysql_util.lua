local upstream_util = require('acid.dbagent.upstream_util')
local util = require('acid.dbagent.util')
local strutil = require('acid.strutil')
local mysql = require('resty.mysql')

local to_str = strutil.to_str
local string_format = string.format
local string_sub = string.sub
local table_insert = table.insert


local _M = {}

local TRANSACTION_START = 'START TRANSACTION'
local TRANSACTION_ROLLBACK = 'ROLLBACK'
local TRANSACTION_COMMIT = 'COMMIT'


function _M.connect_db(connection_info, callbacks, query_opts)
    local db, err = mysql:new()
    if not db then
        return nil, 'MysqlNewError', string_format(
                'failed to new mysql: %s', err)
    end

    db:set_timeout(query_opts.timeout or 1000) -- default 1 second

    local options = {
        host = connection_info.host,
        port = connection_info.port,
        database = connection_info.database,
        user = connection_info.user,
        password = connection_info.password,

        -- use default
        charset = nil,
        max_packet_size = nil,
        ssl_verify = nil,
    }

    if callbacks.before_connect ~= nil then
        callbacks.before_connect(connection_info)
    end

    local ok, err, errcode, sqlstate = db:connect(options)

    if callbacks.after_connect ~= nil then
        callbacks.after_connect(connection_info)
    end

    if not ok then
        local error_code = 'MysqlConnectError'
        local error_message = string_format(
                'failed to connect to: %s, %s, %s, %s, %s',
                options.host, tostring(options.port), err,
                tostring(errcode), sqlstate)

        if callbacks.connect_error ~= nil then
            callbacks.connect_error(error_code, error_message)
        end

        return nil, error_code, error_message
    end

    local conn_repr = util.get_connect_repr(options)

    return {db=db, conn_repr=conn_repr}, nil, nil
end


local function close_db(connection)
    local ok, err = connection.db:close()
    if not ok then
        ngx.log(ngx.ERR, string_format('failed to close: %s, %s',
                                       connection.conn_repr, err))
    end
end


function _M.db_query(connection, sql, callbacks)
    if callbacks.before_query ~= nil then
        callbacks.before_query(sql)
    end

    local query_result, err, errcode, sqlstate = connection.db:query(sql)

    if callbacks.after_query ~= nil then
        callbacks.after_query(query_result)
    end

    if err ~= nil then
        close_db(connection)

        local error_code = 'MysqlQueryError'
        local error_message = string_format(
                'failed to query mysql: %s on: %s, error: %s, %s, %s',
                sql, connection.conn_repr, err, errcode, sqlstate)

        if callbacks.query_error ~= nil then
            callbacks.query_error(error_code, error_message)
        end

        return nil, error_code, error_message
    end

    return query_result, nil, nil
end


function _M.single_query(connection_info, sql, callbacks, query_opts)
    local connection, err, errmsg = _M.connect_db(
            connection_info, callbacks, query_opts)
    if err ~= nil then
        return nil, err, errmsg
    end

    local query_result, err, errmsg = _M.db_query(connection, sql, callbacks)
    if err ~= nil then
        return nil, err, errmsg
    end

    ngx.log(ngx.INFO, string_format(
            'execute sql: %s on: %s, result: %s...',
            sql, connection.conn_repr,
            string_sub(to_str(query_result), 1, 256)))

    local ok, err = connection.db:set_keepalive(10 * 1000, 100)
    if not ok then
        ngx.log(ngx.ERR, string_format(
                'failed to set mysql keepalive on: %s, %s',
                connection.conn_repr, err))
    end

    return query_result, nil, nil
end


local function roll_back(connection, callbacks)
    local query_result, err, errmsg = _M.db_query(
            connection, TRANSACTION_ROLLBACK, callbacks)
    if err ~= nil then
        ngx.log(ngx.INFO, string_format(
                'failed to roll back on: %s, %s, %s',
                connection.conn_repr, err, errmsg))
    end
    ngx.log(ngx.INFO, string_format('roll back on: %s, result: %s',
                                    connection.conn_repr, to_str(query_result)))
end


local function transaction_query(connection_info, sqls, sqls_opts,
                                 callbacks, query_opts)
    if sqls_opts == nil then
        sqls_opts = {}
    end

    local connection, err, errmsg = _M.connect_db(
            connection_info, callbacks, query_opts)
    if err ~= nil then
        return nil, err, errmsg
    end

    local query_result, err, errmsg = _M.db_query(
            connection, TRANSACTION_START, callbacks)
    if err ~= nil then
        return nil, 'StartTransactionError', string_format(
                'failed to start transaction: %s, %s', err, errmsg)
    end

    ngx.log(ngx.INFO, string_format('start transaction on: %s, result: %s',
                                    connection.conn_repr, to_str(query_result)))

    local transaction_result = {}

    for i, sql in ipairs(sqls) do
        local query_result, err, errmsg = _M.db_query(connection, sql, callbacks)
        if err ~= nil then
            return nil, err, errmsg
        end

        table_insert(transaction_result, query_result)
        ngx.log(ngx.INFO, string_format(
                'execute sql: %s on: %s, result: %s...',
                sql, connection.conn_repr,
                string_sub(to_str(query_result), 1, 256)))

        local sql_opts = sqls_opts[i] or {}

        if not sql_opts.allow_empty_write then
            if query_result.affected_rows == 0 then
                roll_back(connection, callbacks)
                close_db(connection)

                return nil, 'EmptyWriteError', string_format(
                        'execute of sql: %s affected 0 row', sql)
            end
        end
    end

    local query_result, err, errmsg = _M.db_query(
            connection, TRANSACTION_COMMIT, callbacks)
    if err ~= nil then
        roll_back(connection, callbacks)
        close_db(connection)
        return nil, 'CommitTransactionError', string_format(
                'failed to commit transaction: %s, %s', err, errmsg)
    end

    ngx.log(ngx.INFO, string_format('commited transaction on: %s, result: %s',
                                    connection.conn_repr, to_str(query_result)))

    local ok, err = connection.db:set_keepalive(10 * 1000, 100)
    if not ok then
        ngx.log(ngx.ERR, string_format(
                'failed to set mysql keepalive on: %s, %s',
                connection.conn_repr, err))
    end

    return transaction_result[#transaction_result], nil, nil
end


local function mysql_query(api_ctx, callbacks)
    local query_result, err, errmsg
    local db_connetctions = api_ctx.conf.connections

    local query_opts = api_ctx.action_model.query_opts or {}

    for _ = 1, 3 do
        local connection_name = upstream_util.get_connection(api_ctx)
        local connection_info = db_connetctions[connection_name]

        if #api_ctx.sqls == 1 then
            query_result, err, errmsg = _M.single_query(
                    connection_info, api_ctx.sqls[1], callbacks, query_opts)
        else
            query_result, err, errmsg = transaction_query(
                    connection_info, api_ctx.sqls,
                    api_ctx.sqls_opts, callbacks, query_opts)
        end

        if err == nil then
            return query_result, nil, nil
        end
    end

    return nil, err, errmsg
end


function _M.do_query(api_ctx)
    local callbacks = api_ctx.opts.callbacks or {}
    local query_result, err, errmsg = mysql_query(api_ctx, callbacks)
    if err ~= nil then
        return nil, err, errmsg
    end

    api_ctx.query_result = query_result
    return query_result, nil, nil
end


return _M
