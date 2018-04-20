<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
#   Table of Content

- [Name](#name)
- [Status](#status)
- [Description](#description)
- [Synopsis](#synopsis)
- [Exceptions](#exceptions)
  - [RequestError](#requesterror)
  - [InvalidResponseError](#invalidresponseerror)
  - [DecodeResponseBodyError](#decoderesponsebodyerror)
  - [OperationError](#operationerror)
  - [WriteIgnored](#writeignored)
- [Classes](#classes)
  - [Client](#client)
- [Methods](#methods)
  - [Client.Subject.action](#clientsubjectaction)
  - [Client.Subject.retry](#clientsubjectretry)
  - [Client.Subject.ignore](#clientsubjectignore)
- [Author](#author)
- [Copyright and License](#copyright-and-license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

#   Name

dbagent_client.py

#   Status

This library is considered production ready.

#   Description

This is the python binding of dbagent, it provides easy access to
dbagent service with python.

#   Synopsis

``` python
import dbagent_client

client = dbagent_client.Client(['1.2.3.4', '5.6.7.8'], 1234)

r = client.subject_foo.action_bar({'foo': 'bar'})

# or
r = client.subject_foo.ignore().action_bar({'foo': 'bar'})

# or
r = client.subject_foo.retry(3).action_bar({'foo': 'bar'})
```

#   Exceptions

## RequestError

Raises when failed to request dbagent service.

## InvalidResponseError

Raises when dbagent service response status is not 200 or the
json decoded dbagent service response is not a dict.

## DecodeResponseBodyError

Raises when failed to json decode dbagent service response body.

## OperationError

Raises when dbagent service response contains error, which means the
operations did not succeed.

## WriteIgnored

Raises when the affected rows is 0 and `allow_write_ignored` is `False`.

#   Classes

## Client

**syntax**
`client = dbagent_client.Client(ips, port, timeout=5, api_version='v1',
                 shard_header_prefix='x-acid-', timeout_ratio=1.5,
                 retry_sleep=0.01, access_key='', secret_key='',
                 user_agent='unknown', to_convert=None)`

**arguments**

-   `ips`:
    is a list, specify the ips of dbagent service. Required.

-   `port`:
    is an integer, specify the port of dbagent service. Required.

-   `timeout`:
    specify socket operations timeout in seconds. The default is 5.

-   `api_version`:
    specify the api version of dbagent service. The default is 'v1'.

-   `shard_header_prefix`:
    specify the shard header prefix used by dbagent service.
    The default is 'x-acid-'.

-   `timeout_ratio`:
    specify the raising ratio of `timeout` when retry on failure.
    The default is 1.5.

-   `retry_sleep`:
    specify the time to sleep in seconds when retry on failure.
    The default is 0.01.

-   `access_key`:
    specify the access key used for adding signature.
    The default is `None`, mean not add signature.

-   `secret_key`:
    specify the secret key used for adding signature.
    The default is `None`, mean not add signature.

-   `user_agent`:
    specify the value of user agent header. The default is 'unknown'.

-   `to_convert`:
    is a dict, used to specify which table fields need to be converted,
    such as convert string to number. Following is an example, and
    supported conversions are:

    -   `to_int`:
        convert a string number to an integer.

``` python
to_convert = {
    'subject_a': {
        'field_foo': 'to_int',
        'field_bar': 'to_int',
        ...
    },
    'subject_b': {
        ...
    },
    ...
}
```

#   Methods

## Client.Subject.action

**syntax**:
`r = client.<subject_name>.<action_name>(args)`

Request the api corresponding to specific `subject_name`
and `action_name`.

**arguments**:

-   `args`:
    is a dict, the allowed keys is determined by specific
    `subject_name` and and `action_name`.

**return**:
The json decoded api response, some conversions may also be performed.

## Client.Subject.retry

**syntax**:
`r = client.<subject_name>.retry(n)`

Specify how many times to retry.

**arguments**:

-   `n`:
    is a number, it should not bigger than the number of ip addresses.

**return**:
The Subject object.

## Client.Subject.ignore

**syntax**:
`r = client.<subject_name>.ignore()`

Set `allow_write_ignored` to `True`, by default, `allow_write_ignored`
is `False`.

**arguments**:

No arguments.

**return**:
The Subject object.

#   Author

Renzhi (任稚) <zhi.ren@baishancloud.com>

#   Copyright and License

The MIT License (MIT)

Copyright (c) 2015 Renzhi (任稚) <zhi.ren@baishancloud.com>
