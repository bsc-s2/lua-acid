local arg_schema_checker = require('acid.arg_schema_checker')


function test.args_shape(t)
    for _, args, schema, exp_err, _ in t:case_iter(3, {
        {
            {},
            {
                a = {
                    required = true,
                },
            },
            'LackArgument',
        },
        {
            {},
            {
                a = {
                    required = false,
                },
            },
            nil,
        },
        {
            {a = 'foo'},
            {
                a = {
                    required = true,
                    checker = {
                        ['type'] = 'any',
                    },
                },
            },
            nil,
        },
        {
            {b = 'foo'},
            {
                a = {
                    required = false,
                },
            },
            'ExtraArgument',
        },
    }) do

        local _, err, errmsg = arg_schema_checker.check_arguments(args, schema)
        t:eq(exp_err, err, errmsg)
    end
end


function test.multi_type(t)
    for _, args, schema, exp_err, _ in t:case_iter(3, {
        {
            {a = 1},
            {
                a = {
                    required = true,
                    checker = {
                        {
                            ['type'] = 'bool',
                        },
                        {
                            ['type'] = 'integer',
                        },
                    },
                },
            },
            nil,
        },
        {
            {a = true},
            {
                a = {
                    required = true,
                    checker = {
                        {
                            ['type'] = 'bool',
                        },
                        {
                            ['type'] = 'integer',
                        },
                    },
                },
            },
            nil,
        },
    }) do

        local _, err, errmsg = arg_schema_checker.check_arguments(args, schema)
        t:eq(exp_err, err, errmsg)
    end
end


function test.type_integer(t)
    for _, args, schema, exp_err, _ in t:case_iter(3, {
        {
            {a = 1},
            {
                a = {
                    required = true,
                    checker = {
                        ['type'] = 'integer',
                    },
                },
            },
            nil,
        },
        {
            {a = 1.1},
            {
                a = {
                    required = true,
                    checker = {
                        ['type'] = 'integer',
                    },
                },
            },
            'InvalidType',
        },
        {
            {a = 4},
            {
                a = {
                    required = true,
                    checker = {
                        ['type'] = 'integer',
                        min = 1,
                        max = 3,
                    },
                },
            },
            'OverRange',
        },
        {
            {a = 4},
            {
                a = {
                    required = true,
                    checker = {
                        ['type'] = 'integer',
                        enum = {1, 2, 3},
                    },
                },
            },
            'NotInEnum',
        },
        {
            {a = 4},
            {
                a = {
                    required = true,
                    checker = {
                        ['type'] = 'integer',
                        ['not'] = {1, 2, 3, 4},
                    },
                },
            },
            'InvalidValue',
        },
    }) do

        local _, err, errmsg = arg_schema_checker.check_arguments(args, schema)
        t:eq(exp_err, err, errmsg)
    end
end


function test.type_float(t)
    for _, args, schema, exp_err, _ in t:case_iter(3, {
        {
            {a = 1},
            {
                a = {
                    required = true,
                    checker = {
                        ['type'] = 'float',
                    },
                },
            },
            nil,
        },
        {
            {a = 1.1},
            {
                a = {
                    required = true,
                    checker = {
                        ['type'] = 'float',
                    },
                },
            },
            nil,
        },
        {
            {a = 4},
            {
                a = {
                    required = true,
                    checker = {
                        ['type'] = 'float',
                        min = 1,
                        max = 3,
                    },
                },
            },
            'OverRange',
        },
        {
            {a = 4},
            {
                a = {
                    required = true,
                    checker = {
                        ['type'] = 'float',
                        enum = {1, 2, 3},
                    },
                },
            },
            'NotInEnum',
        },
        {
            {a = 4},
            {
                a = {
                    required = true,
                    checker = {
                        ['type'] = 'float',
                        ['not'] = {1, 2, 3, 4},
                    },
                },
            },
            'InvalidValue',
        },
    }) do

        local _, err, errmsg = arg_schema_checker.check_arguments(args, schema)
        t:eq(exp_err, err, errmsg)
    end
end


function test.type_string(t)
    for _, args, schema, exp_err, _ in t:case_iter(3, {
        {
            {a = 1},
            {
                a = {
                    required = true,
                    checker = {
                        ['type'] = 'string',
                    },
                },
            },
            'InvalidType',
        },
        {
            {a = '1'},
            {
                a = {
                    required = true,
                    checker = {
                        ['type'] = 'string',
                    },
                },
            },
            nil,
        },
        {
            {a = 'fooo'},
            {
                a = {
                    required = true,
                    checker = {
                        ['type'] = 'string',
                        fixed_length = 3,
                    },
                },
            },
            'InvalidLength',
        },
        {
            {a = 'fooo'},
            {
                a = {
                    required = true,
                    checker = {
                        ['type'] = 'string',
                        min_length = 1,
                        max_length = 3,
                    },
                },
            },
            'InvalidLength',
        },
        {
            {a = 'fooo'},
            {
                a = {
                    required = true,
                    checker = {
                        ['type'] = 'string',
                        enum = {'foo', 'bar'},
                    },
                },
            },
            'NotInEnum',
        },
        {
            {a = 'fooo'},
            {
                a = {
                    required = true,
                    checker = {
                        ['type'] = 'string',
                        ['not'] = {'fooo'},
                    },
                },
            },
            'InvalidValue',
        },
        {
            {a = 'ad'},
            {
                a = {
                    required = true,
                    checker = {
                        ['type'] = 'string',
                        regexp = '^[a-c]{3}$',
                    },
                },
            },
            'PatternNotMatch',
        },
    }) do

        local _, err, errmsg = arg_schema_checker.check_arguments(args, schema)
        t:eq(exp_err, err, errmsg)
    end
end


function test.type_string_number(t)
    for _, args, schema, exp_err, _ in t:case_iter(3, {
        {
            {a = 1},
            {
                a = {
                    required = true,
                    checker = {
                        ['type'] = 'string_number',
                    },
                },
            },
            'InvalidType',
        },
        {
            {a = '1'},
            {
                a = {
                    required = true,
                    checker = {
                        ['type'] = 'string_number',
                    },
                },
            },
            nil,
        },
        {
            {a = '1.001'},
            {
                a = {
                    required = true,
                    checker = {
                        ['type'] = 'string_number',
                    },
                },
            },
            nil,
        },
        {
            {a = '4'},
            {
                a = {
                    required = true,
                    checker = {
                        ['type'] = 'string_number',
                        min = 1,
                        max = 3,
                    },
                },
            },
            'OverRange',
        },
        {
            {a = '4'},
            {
                a = {
                    required = true,
                    checker = {
                        ['type'] = 'string_number',
                        enum = {1, 2, 3, 4},
                    },
                },
            },
            'NotInEnum',
        },
        {
            {a = '4'},
            {
                a = {
                    required = true,
                    checker = {
                        ['type'] = 'string_number',
                        enum = {'1', '2', '3', '4'},
                    },
                },
            },
            nil,
        },
        {
            {a = '4'},
            {
                a = {
                    required = true,
                    checker = {
                        ['type'] = 'string_number',
                        ['not'] = {'4'},
                    },
                },
            },
            'InvalidValue',
        },
        {
            {a = '4'},
            {
                a = {
                    required = true,
                    checker = {
                        ['type'] = 'string_number',
                        ['not'] = {4},
                    },
                },
            },
            nil,
        },
    }) do

        local _, err, errmsg = arg_schema_checker.check_arguments(args, schema)
        t:eq(exp_err, err, errmsg)
    end
end


function test.type_array(t)
    for _, args, schema, exp_err, _ in t:case_iter(3, {
        {
            {a = 1},
            {
                a = {
                    required = true,
                    checker = {
                        ['type'] = 'array',
                    },
                },
            },
            'InvalidType',
        },
        {
            {a = {}},
            {
                a = {
                    required = true,
                    checker = {
                        ['type'] = 'array',
                    },
                },
            },
            nil,
        },
        {
            {a = {1, 2, 3, 4}},
            {
                a = {
                    required = true,
                    checker = {
                        ['type'] = 'array',
                    },
                },
            },
            nil,
        },
        {
            {a = {1, 2, 3, 4}},
            {
                a = {
                    required = true,
                    checker = {
                        ['type'] = 'array',
                        fixed_length = 3,
                    },
                },
            },
            'InvalidLength',
        },
        {
            {a = {1, 2, 3, 4}},
            {
                a = {
                    required = true,
                    checker = {
                        ['type'] = 'array',
                        min_length = 1,
                        max_length = 3,
                    },
                },
            },
            'InvalidLength',
        },
        {
            {a = {1, 2, 3, 4}},
            {
                a = {
                    required = true,
                    checker = {
                        ['type'] = 'array',
                        element_checker = {
                            ['type'] = 'integer',
                            enum = {2, 3, 4, 5},
                        },
                    },
                },
            },
            'NotInEnum',
        },
        {
            {a = {1, 2, '3', '4'}},
            {
                a = {
                    required = true,
                    checker = {
                        ['type'] = 'array',
                        element_checker = {
                            {
                                ['type'] = 'integer',
                            },
                            {
                                ['type'] = 'string',
                            },
                        },
                    },
                },
            },
            nil,
        },
    }) do

        local _, err, errmsg = arg_schema_checker.check_arguments(args, schema)
        t:eq(exp_err, err, errmsg)
    end
end


function test.type_dict(t)
    for _, args, schema, exp_err, _ in t:case_iter(3, {
        {
            {a = 1},
            {
                a = {
                    required = true,
                    checker = {
                        ['type'] = 'dict',
                    },
                },
            },
            'InvalidType',
        },
        {
            {a = {}},
            {
                a = {
                    required = true,
                    checker = {
                        ['type'] = 'dict',
                    },
                },
            },
            nil,
        },
        {
            {a = {1, 2, foo = 'bar'}},
            {
                a = {
                    required = true,
                    checker = {
                        ['type'] = 'dict',
                        fixed_length = 2,
                    },
                },
            },
            nil,
        },
        {
            {a = {1, 2, foo = 'bar'}},
            {
                a = {
                    required = true,
                    checker = {
                        ['type'] = 'dict',
                        min_length = 3,
                        max_length = 3,
                    },
                },
            },
            'InvalidLength',
        },
        {
            {a = {1, 2, foo = 'bar'}},
            {
                a = {
                    required = true,
                    checker = {
                        ['type'] = 'dict',
                        key_checker = {
                            {
                                ['type'] = 'integer',
                            },
                            {
                                ['type'] = 'string',
                            },
                        },
                        value_checker = {
                            {
                                ['type'] = 'integer',
                            },
                            {
                                ['type'] = 'string',
                            },
                        },
                    },
                },
            },
            nil,
        },
        {
            {a = {foo = 'bar'}},
            {
                a = {
                    required = true,
                    checker = {
                        ['type'] = 'dict',
                        sub_schema = {
                            foo = {
                                required = true,
                                checker = {
                                    ['type'] = 'float',
                                },
                            },
                        },
                    },
                },
            },
            'InvalidType',
        },
    }) do

        local _, err, errmsg = arg_schema_checker.check_arguments(args, schema)
        t:eq(exp_err, err, errmsg)
    end
end
