local unicode = require('acid.unicode')

local char = string.char


function test.from_utf8(t)
    for _, utf8_str, expected, desc in t:case_iter(2, {
        {char('0xF0','0x9F','0xBF','0xAE'), {131054   }},
        {char('0xE2','0x82','0xAC'),        {8364     }},
        {char('0xC2','0xA2'),               {162      }},
        {char('0x44'),                      {68       }},
        {char('0x44','0xC2','0xA2'),        {68, 162  }},
        {char('0xC2','0xA2','0x44'),        {162, 68  }},
        {char('0x44','0xE2','0x82','0xAC'), {68, 8364 }},
    }) do

        local points, err, errmsg = unicode.from_utf8(utf8_str)
        t:eq(nil, err, desc)
        t:eq(nil, errmsg, desc)
        for i, code_point in ipairs(expected) do
            t:eq(code_point, points[i], desc)
        end
    end
end


function test.from_utf8_invalid_input(t)
    for _, utf8_str, desc in t:case_iter(1, {
        {char('0xF0','0x44')},
        {char('0x44','0xFF')},
    }) do

        local points, err, errmsg = unicode.from_utf8(utf8_str)
        t:eq(nil, points, desc)
        t:neq(nil, err, desc)
        t:neq(nil, errmsg, desc)
    end
end


function test.xml_dec(t)
    for _, xml_str, expected, desc in t:case_iter(2, {
        {'&lt;', '<'      },
        {'&amp;', '&'     },
        {'&#38;', '&'     },
        {'&lt;', '<'      },
        {'&#60;', '<'     },
        {'&gt;', '>'      },
        {'&#62;', '>'     },
        {'&quot;', '"'    },
        {'&#34;', '"'     },
        {'&apos;', "'"    },
        {'&#39;', "'"     },
        {'&#40;', '&#40;' },

    }) do

        local r, err, errmsg = unicode.xml_dec(xml_str)
        t:eq(expected, r, desc)
        t:eq(nil, err, desc)
        t:eq(nil, errmsg, desc)
    end
end


function test.xml_enc(t)
    local r, err, errmsg = unicode.xml_enc(
            {38, 40, 60, 62, 34, 39, 0x80, 65537})
    t:eq('&amp;(&lt;&gt;&quot;&apos;&#128;&#65537;', r)
    t:eq(nil, err)
    t:eq(nil, errmsg)
end


function test.xml_enc_character_reference(t)
    for _, str, expected, desc in t:case_iter(2, {
        {'ab c',              'ab c'    },
        {char('0x00'),        '&#x0;'   },
        {char('0x7F'),        '&#x7f;'  },
        {char('0x80'),        '&#x80;'  },
        {"'",                 '&apos;'  },
        {char('0x21','0xFF'), '!&#xff;' },
    }) do

        local r, err, errmsg = unicode.xml_enc_character_reference(str)
        t:eq(expected, r, desc)
        t:eq(nil, err, desc)
        t:eq(nil, errmsg, desc)
    end
end
