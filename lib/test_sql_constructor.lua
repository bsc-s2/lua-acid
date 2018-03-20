local sql_constructor = require('acid.sql_constructor')


function test.make_fields(t)
    for _, raw_fields, exp_fields, desc in t:case_iter(2, {
        {
            {
                field_foo = {
                    data_type = 'bigint',
                },
            },
            {
                field_foo = {
                    data_type = 'bigint',
                    backticked_name = '`field_foo`',
                    select_expr = 'CAST(`field_foo` AS CHAR) as `field_foo`',
                },
            },
        },
        {
            {
                field_foo = {
                    data_type = 'binary',
                },
            },
            {
                field_foo = {
                    data_type = 'binary',
                    backticked_name = '`field_foo`',
                    select_expr = 'LOWER(HEX(`field_foo`)) as `field_foo`',
                },
            },
        },
        {
            {
                field_foo = {
                    data_type = 'varbinary',
                    use_hex = false,
                },
            },
            {
                field_foo = {
                    data_type = 'varbinary',
                    use_hex = false,
                    backticked_name = '`field_foo`',
                    select_expr = '`field_foo`',
                },
            },
        },
    }) do

        local fields, err, errmsg = sql_constructor.make_fields(raw_fields)
        t:eq(nil, err, errmsg)

        t:eqdict(exp_fields, fields, desc)
    end
end


local raw_fields = {
    id = {
        data_type = 'bigint',
    },
    age = {
        data_type = 'bigint',
        use_string = false,
    },
    name = {
        data_type = 'varchar',
    },
}


function test.make_insert_sql(t)
    for _, param, args, exp_sql, desc in t:case_iter(3, {
        {
            {
                allowed_field = {
                    id = true, age = true, name = true,
                },
            },
            {
                id = '123456',
                age = 28,
                name = 'bob',
            },
            [[INSERT IGNORE INTO `employee` (`age`,`name`,`id`) VALUES (28,'bob','123456')]],
        },
    }) do
        local fields, err, errmsg = sql_constructor.make_fields(raw_fields)
        t:eq(nil, err, errmsg)

        local constructor, err, errmsg = sql_constructor.new(
                'employee', fields)
        t:eq(nil, err, errmsg)

        local sql, err, errmsg = constructor:make_insert_sql(param, args)
        t:eq(nil, err, errmsg)

        t:eq(exp_sql, sql, desc)
    end
end


function test.make_update_sql(t)
    for _, param, args, opts, exp_sql, desc in t:case_iter(4, {
        {
            {
                allowed_field = {
                    age = true,
                },
                ident = {
                    id = true,
                },
            },
            {
                age = 28,
                id = '123456'
            },
            {
                match = {name = 'bob'},
            },
            [[UPDATE IGNORE `employee` SET `age`=28 WHERE `id`='123456' AND `name`='bob']],
        },
        {
            {
                allowed_field = {
                    age = true,
                },
                ident = {
                    id = true,
                },
            },
            {
                age = 1,
                id = '123456'
            },
            {
                incremental = true,
            },
            [[UPDATE IGNORE `employee` SET `age`=1+`age` WHERE `id`='123456']],
        },
    }) do
        local fields, err, errmsg = sql_constructor.make_fields(raw_fields)
        t:eq(nil, err, errmsg)

        local constructor, err, errmsg = sql_constructor.new(
                'employee', fields)
        t:eq(nil, err, errmsg)

        local sql, err, errmsg = constructor:make_update_sql(param, args, opts)
        t:eq(nil, err, errmsg)

        t:eq(exp_sql, sql, desc)
    end
end


function test.make_delete_sql(t)
    for _, param, args, opts, exp_sql, desc in t:case_iter(4, {
        {
            {
                range = {
                    age = true,
                },
            },
            {
                age = {20, 30},
            },
            {match = {name = 'bob'}, leftopen = 1},
            [[DELETE IGNORE FROM `employee` WHERE `age`>20 AND `age`<30 AND `name`='bob']],
        },
        {
            {
                range = {
                    age = true,
                },
            },
            {
                age = {20},
            },
            {match = {name = 'bob'}, leftopen = 1},
            [[DELETE IGNORE FROM `employee` WHERE `age`>20 AND `name`='bob']],
        },
        {
            {
                range = {
                    age = true,
                },
            },
            {
                age = {nil, 30},
            },
            {match = {name = 'bob'}, rightopen = 1},
            [[DELETE IGNORE FROM `employee` WHERE `age`<30 AND `name`='bob']],
        },
    }) do
        local fields, err, errmsg = sql_constructor.make_fields(raw_fields)
        t:eq(nil, err, errmsg)

        local constructor, err, errmsg = sql_constructor.new(
                'employee', fields)
        t:eq(nil, err, errmsg)

        local sql, err, errmsg = constructor:make_delete_sql(param, args, opts)
        t:eq(nil, err, errmsg)

        t:eq(exp_sql, sql, desc)
    end
end


function test.make_select_sql(t)
    for _, select_field, param, args, opts, exp_sql, desc in t:case_iter(5, {
        {
            {'id', 'age', 'name'},
            {
                range = {
                    age = true
                },
            },
            {
                age = {20, 30},
            },
            {
                index_condition = '`id`>"123456"',
                order_by = {
                    {'age', 'ASC'},
                    {'name', 'DESC'},
                },
            },
            [[SELECT CAST(`id` AS CHAR) as `id`,`age`,`name` FROM `employee` WHERE `id`>"123456" AND `age`>=20 AND `age`<30 ORDER BY `age` ASC, `name` DESC]],
        },
        {
            {'id', 'age', 'name'},
            {
                ident = {
                    age = true
                },
            },
            {
                age = 20,
            },
            {
                limit = 3,
            },
            [[SELECT CAST(`id` AS CHAR) as `id`,`age`,`name` FROM `employee` WHERE `age`=20 LIMIT 3]],
        },
        {
            {},
            {},
            {},
            {
                select_expr_list = '`age`, COUNT(*) as `count`',
                group_by_clause = ' GROUP BY `age`',
            },
            [[SELECT `age`, COUNT(*) as `count` FROM `employee` GROUP BY `age`]],
        },
    }) do
        local fields, err, errmsg = sql_constructor.make_fields(raw_fields)
        t:eq(nil, err, errmsg)

        local constructor, err, errmsg = sql_constructor.new(
                'employee', fields)
        t:eq(nil, err, errmsg)

        local sql, err, errmsg = constructor:make_select_sql(
                select_field, param, args, opts)
        t:eq(nil, err, errmsg)

        t:eq(exp_sql, sql, desc)
    end
end
