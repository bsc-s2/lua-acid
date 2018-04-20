import json
import types

import mock

awssign = mock.Mock()
http = mock.Mock()

utfjson = types.ModuleType('utfjson')


def dump(arg):
    return json.dumps(arg)


def load(arg):
    return json.loads(arg)


setattr(utfjson, 'dump', dump)
setattr(utfjson, 'load', load)
