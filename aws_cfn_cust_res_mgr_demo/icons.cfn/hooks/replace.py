from contextlib import contextmanager
from subprocess import check_call

import io
import os
import re

from distutils.version import LooseVersion
from runway.cfngin.session_cache import get_session
from runway.cfngin.hooks import utils
from runway.cfngin.lookups.handlers.rxref import RxrefLookup

xref_handler = RxrefLookup.handle

def string(provider, context, **kwargs):  # pylint: disable=W0613
    path = kwargs.get('path', 'undefined')
    file = kwargs.get('file', 'undefined')
    output_file = kwargs.get('output_file', 'undefined')
    key_word = kwargs.get('key_word', 'undefined')
    value_xref = kwargs.get('value_xref', 'undefined')

    value_xref_rendered = xref_handler(
        kwargs.get('value_xref'),
        provider=provider,
        context=context,
    )

    print("Reading %s to replace %s with %s."% (os.path.join(path, file), key_word, value_xref_rendered))

    f = open(os.path.join(path, file), 'r')
    content = f.read()
    f.close()
    new_fh = open(os.path.join(path, output_file), 'w')
    new_fh.write(content.replace(key_word, value_xref_rendered))
    new_fh.close()
    print("Wrote new content to: %s" % os.path.join(path, output_file))

    return True
