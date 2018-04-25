#!/usr/bin/env python2
# coding: utf-8

import copy
import logging
import time

from pykit import awssign
from pykit import http
from pykit import utfjson

logger = logging.getLogger(__name__)


class DbagentError(Exception):
    pass


class RequestError(DbagentError):
    pass


class InvalidResponseError(DbagentError):
    pass


class DecodeResponseBodyError(DbagentError):
    pass


class OperationError(DbagentError):
    pass


class WriteIgnored(DbagentError):
    pass


def to_int(value):
    return int(value)


CONVERT_FUNC = {
    'to_int': to_int,
}


class Client(object):

    def __init__(self, ips, port, timeout=5, api_version='v1',
                 shard_header_prefix='x-acid-', timeout_ratio=1.5,
                 retry_sleep=0.01, access_key=None, secret_key=None,
                 user_agent='unknown', to_convert=None):

        self.api_version = api_version
        self.shard_header_prefix = shard_header_prefix
        self.user_agent = user_agent
        self.ips = ips
        self.port = port
        self.timeout = timeout
        self.timeout_ratio = timeout_ratio
        self.retry_sleep = retry_sleep
        self.access_key = access_key
        self.secret_key = secret_key
        self.to_convert = to_convert

    def __getattr__(self, subject_name):
        logger.info('about to build subject: ' + subject_name)

        kwargs = {
            'api_version': self.api_version,
            'shard_header_prefix': self.shard_header_prefix,
            'user_agent': self.user_agent,
            'timeout': self.timeout,
            'timeout_ratio': self.timeout_ratio,
            'retry_sleep': self.retry_sleep,
            'access_key': self.access_key,
            'secret_key': self.secret_key,
            'to_convert': (self.to_convert or {}).get(subject_name),
        }

        subject_object = Subject(subject_name, self.ips, self.port, **kwargs)
        setattr(self, subject_name, subject_object)

        return subject_object


class Subject(object):

    def __init__(self, subject_name, ips, port, timeout=5, api_version='v1',
                 shard_header_prefix='x-acid-', timeout_ratio=1.5,
                 retry_sleep=0.01, access_key=None, secret_key=None,
                 user_agent='unknown', to_convert=None):

        self.api_version = api_version
        self.shard_header_prefix = shard_header_prefix
        self.user_agent = user_agent
        self.subject = subject_name
        self.ips = ips
        self.port = port
        self.timeout = timeout
        self.timeout_ratio = timeout_ratio
        self.retry_sleep = retry_sleep
        self.to_convert = to_convert
        self.allow_write_ignored = False
        self.retry_n = len(self.ips)
        self.sess = {}
        self.signer = None

        if self.access_key is not None and self.secret_key is not None:
            self.signer = awssign.Signer(access_key, secret_key)

    def __getattr__(self, action_name):
        logger.info('about to build action: ' + action_name)

        def _action_req(args):
            return self._req(action_name, args)

        setattr(self, action_name, _action_req)

        return _action_req

    def retry(self, n):
        if n > len(self.ips):
            n = len(self.ips)

        self.retry_n = n
        return self

    def ignore(self):
        self.allow_write_ignored = True
        return self

    def _request_one_ip(self, ip, request, timeout):
        request_copy = copy.deepcopy(request)
        request_copy['headers']['Host'] = ip

        if self.signer is not None:
            self.signer.add_auth(request_copy, sign_payload=True)

        h = http.Client(ip, self.port, timeout=timeout)
        h.send_request(request_copy['uri'],
                       request_copy['verb'],
                       request_copy['headers'])
        h.send_body(request_copy['body'])

        resp_status, resp_headers = h.read_response()

        bufs = []
        while True:
            buf = h.read_body(1024 * 1024 * 100)
            if buf == '':
                break

            bufs.append(buf)

        resp_body = ''.join(bufs)

        return resp_status, resp_body, resp_headers

    def _do_request(self, request):
        last_err = None
        timeout = self.timeout

        for i in range(self.retry_n):
            ip = self.ips[i]

            try:
                status, body, headers = self._request_one_ip(
                    ip, request, timeout)

                if status == 200:
                    return body, headers

                last_err = InvalidResponseError(
                    'status: %s is not 200, %s' % (status, body))

                if self.retry_sleep > 0:
                    time.sleep(self.retry_sleep)

                timeout *= self.timeout_ratio

            except Exception as e:
                logger.exception('failed to reqeuest dbagent: %s, %s, %s' %
                                 (ip, repr(request), repr(e)))
                last_err = RequestError(ip, repr(request), repr(e))

                if self.retry_sleep > 0:
                    time.sleep(self.retry_sleep)

                timeout *= self.timeout_ratio

        logger.error('failed to request all dbagent: %s, %s' %
                     (repr(request), repr(last_err)))

        raise last_err

    def parse_response_body(self, body):
        try:
            result = utfjson.load(body)
        except ValueError:
            raise DecodeResponseBodyError(body)

        if not isinstance(result, dict):
            raise InvalidResponseError('response: %s is not a dict'
                                       % repr(result))

        if 'error_code' in result:
            raise OperationError(body)

        result = result.get('value')

        if result is None:
            return result

        if isinstance(result, dict):
            if (result.get('affected_rows') == 0 and
                    self.allow_write_ignored == False):
                raise WriteIgnored(body)

        return result

    def convert_field(self, result):
        if result is None:
            return

        result_list = result
        if not isinstance(result_list, list):
            result_list = [result_list]

        for field_name, convert_method in (self.to_convert or {}).iteritems():
            convert_func = CONVERT_FUNC[convert_method]

            for row in result_list:
                if field_name in row:
                    row[field_name] = convert_func(row[field_name])
        return

    def _load_shard(self, headers):
        header_current = self.shard_header_prefix + 'shard-current'
        header_next = self.shard_header_prefix + 'shard-next'
        header_fields = self.shard_header_prefix + 'shard-fields'
        shard = {
            'shard_current': headers[header_current],
            'shard_next': headers[header_next],
            'shard_fields': headers[header_fields],
        }

        for name, value in shard.items():
            if value is not None:
                try:
                    self.sess[name] = utfjson.load(value)
                except ValueError:
                    pass

    def _req(self, action, args):
        request = {
            'verb': 'POST',
            'uri': '/api/%s/%s/%s' % (self.api_version,
                                      self.subject, action),
            'args': {},
            'headers': {
                'Host': '',
                'Content-Length': 0,
                'User-Agent': self.user_agent,
            },
            'body': '',
        }

        request['body'] = utfjson.dump(args)
        request['headers'][
            'Content-Length'] = len(request['body'])

        body, headers = self._do_request(request)

        result = self.parse_response_body(body)

        self.convert_field(result)

        self._load_shard(headers)

        return result
