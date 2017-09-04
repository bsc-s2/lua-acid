local utf8 = require('acid.utf8')
local strutil = require('acid.strutil')


function test.basic(t)
    for _, code_points, desc in t:case_iter(1, {
        { {                                                 } },
        { {0                                                } },
        { {0x80                                             } },
        { {25105, 0x80                                      } },
        { {4444, 33, 0x10FFFF                               } },
        { {00, 01, 4444, 22, 4312, 127, 128, 129            } },
        { {255, 256, 254, 0xFF, 0xFFFE, 0x80, 0x7FF, 0xFFFF } },
    }) do

        local utf8_str, err, errmsg = utf8.char(code_points)
        test.dd(utf8_str)
        t:eq(nil, err, errmsg)
        t:eq(nil, errmsg, desc)

        local points, err, errmsg = utf8.code_point(utf8_str)
        test.dd(points)
        t:eq(nil, err, errmsg)
        t:eq(nil, errmsg, desc)
        t:eqdict(code_points, points, desc)
    end
end


function test.char(t)
    for _, code_points, utf8_hex, desc in t:case_iter(2, {
        { {0                  }, '00' },
        { {127                }, '7F' },
        { {0x2A700            }, 'F0AA9C80' },
        { {0x2A7DD            }, 'F0AA9F9D' },
        { {0x010D, 0x01E3     }, 'C48DC7A3' },
        { {0x0600, 0x09FF     }, 'D880E0A7BF' },
        { {0x0980, 0x0D7F     }, 'E0A680E0B5BF' },
        { {0x100001, 0x1003FF }, 'F4808081F4808FBF' },
    }) do

        local utf8_str, err, errmsg = utf8.char(code_points)
        t:eq(nil, err, errmsg)
        t:eq(nil, errmsg, desc)

        t:eq(utf8_hex, strutil.tohex(utf8_str), desc)
    end
end


function test.invalid_utf8(t)
    for _, utf8_hex, desc in t:case_iter(1, {
        { '80'       },
        { 'C080'     },
        { 'E08080'   },
        { 'F0808080' },
        { 'FFFF'     },
        { 'DDDD'     },
    }) do

        local utf8_str = strutil.fromhex(utf8_hex)
        local _, err, errmsg = utf8.code_point(utf8_str)
        test.dd(err)
        test.dd(errmsg)
        t:neq(nil, err, errmsg)
        t:neq(nil, errmsg, desc)
    end
end


function test.invalid_code_point(t)
    for _, code_points, desc in t:case_iter(1, {
        { {0x110000 } },
        { {-1       } },

    }) do

        local _, err, errmsg = utf8.char(code_points)
        test.dd(err)
        test.dd(errmsg)
        t:neq(nil, err, errmsg)
        t:neq(nil, errmsg, desc)
    end
end
