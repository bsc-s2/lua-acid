#!/usr/bin/env python2.6
# coding: utf-8

import unittest

import dbagent_client


class MySubject(dbagent_client.Subject):

    def _do_request(self, request):
        self.request = request
        return self.response


class TestDbagentClient(unittest.TestCase):

    dummy_headers = {
        'x-acid-shard-current': None,
        'x-acid-shard-next': None,
        'x-acid-shard-fields': None,
    }

    def test_request(self):
        cases = (
            (
                {},
                {
                    'verb': 'POST',
                    'uri': '/api/v1/test_subject/action_foo',
                    'body': '{}',
                },
            ),
            (
                {'foo': 'bar'},
                {
                    'verb': 'POST',
                    'uri': '/api/v1/test_subject/action_foo',
                    'body': '{"foo": "bar"}',
                },
            ),
            (
                {'foo': None},
                {
                    'verb': 'POST',
                    'uri': '/api/v1/test_subject/action_foo',
                    'body': '{"foo": null}',
                },
            ),
        )

        for args, exp in cases:
            subject = MySubject('test_subject', ['1.2.3.4'], 1234)

            dummy_body = '{"value": null}'
            setattr(subject, 'response', (dummy_body, self.dummy_headers))

            subject.action_foo(args)

            self.assertDictContainsSubset(exp, subject.request)

    def test_response(self):
        cases = (
            (
                {},
                ('{"value": null}', self.dummy_headers),
                None,
            ),
            (
                {},
                ('{}', self.dummy_headers),
                None,
            ),
            (
                {},
                ('{"value": []}', self.dummy_headers),
                [],
            ),
            (
                {
                    'to_convert': {
                        'foo': 'to_int',
                    },
                },
                ('{"value": {"foo": "1234","bar": "1234"}}', self.dummy_headers),
                {
                    'foo': 1234,
                    'bar': '1234',
                },
            ),
        )

        for kwargs, response, exp in cases:
            subject = MySubject('test_subject', ['1.2.3.4'], 1234, **kwargs)

            setattr(subject, 'response', response)

            r = subject.action_foo({})

            self.assertEqual(exp, r)

    def test_allow_write_ignored(self):
        subject = MySubject('test_subject', ['1.2.3.4'], 1234)

        response_body = '{"value": {"affected_rows": 0}}'
        setattr(subject, 'response', (response_body, self.dummy_headers))

        with self.assertRaises(dbagent_client.WriteIgnored):
            subject.action_foo({})

        r = subject.ignore().action_foo({})

        self.assertEqual({'affected_rows': 0}, r)

    def test_exception(self):
        cases = (
            (
                ('', self.dummy_headers),
                dbagent_client.DecodeResponseBodyError,
            ),
            (
                ('[]', self.dummy_headers),
                dbagent_client.InvalidResponseError,
            ),
            (
                ('{"error_code": "test", "error_message": "test"}',
                 self.dummy_headers),
                dbagent_client.OperationError,
            ),
        )

        for response, exp_exception in cases:
            subject = MySubject('test_subject', ['1.2.3.4'], 1234)

            setattr(subject, 'response', response)

            with self.assertRaises(exp_exception):
                subject.action_foo({})


if __name__ == "__main__":
    unittest.main()
