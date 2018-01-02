<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
#   Table of Content

- [Name](#name)
- [Status](#status)
- [Description](#description)
- [Methods](#methods)
  - [net.ip_to_binary](#netip_to_binary)
  - [net.binary_to_ip](#netbinary_to_ip)
  - [net.parse_cidr](#netparse_cidr)
  - [net.ip_in_cidr](#netip_in_cidr)
- [Author](#author)
- [Copyright and License](#copyright-and-license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->


#   Name

acid.net

#   Status

This library is considered production ready.

#   Description

Utility functions for network related operation.

#   Methods

##  net.ip_to_binary

**syntax**:
`net.ip_to_binary(ip)`

Return the number format of ip.

**arguments**:

-   `ip`:
    is a string.

**return**:
the number format of ip.

##  net.binary_to_ip

**syntax**:
`net.binary_to_ip(ip_binary)`

Return the string format of ip.

**arguments**:

-   `ip_binary`:
    is a number.

**return**:
the string format of ip.

##  net.parse_cidr

**syntax**:
`net.binary_to_ip(cidr)`

Return min and max number format ip of a cidr.

**arguments**:

-   `cidr`:
    is a string.

**return**:
the min and max ip of a cidr.

##  net.ip_in_cidr

**syntax**:
`net.ip_in_cidr(ip, cidrs)`

Return true if ip in cidrs otherwise false.

**arguments**:

-   `ip`:
    is a string.

-   `cidrs`:
    is a array table.

**return**:
true or false.

#   Author

Liu Tongwei(刘桐伟) <tongwei.liu@baishancloud.com>

#   Copyright and License

The MIT License (MIT)

Copyright (c) 2018 Liu Tongwei(刘桐伟) <tongwei.liu@baishancloud.com>
