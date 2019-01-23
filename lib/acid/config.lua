local ok, acidconf = pcall(require, 'acidconf')

if not ok or acidconf.inner_ip_patterns == nil then
    acidconf = {
        inner_ip_patterns = {
            '^172[.]1[6-9][.]',
            '^172[.]2[0-9][.]',
            '^172[.]3[0-1][.]',
            '^10[.]',
            '^192[.]168[.]',
        }
    }
end

return acidconf
