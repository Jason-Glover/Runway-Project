from contextlib import contextmanager
from subprocess import check_call

import io
import os

from runway.cfngin.lookups.handlers.rxref import RxrefLookup
xref_handler = RxrefLookup.handle

def print_xref_msg(provider, context, **kwargs):  # pylint: disable=W0613
    xref_output = kwargs.get('xref_output', 'undefined')
    msg = kwargs.get('msg', 'undefined')

    output_string = xref_handler(
        kwargs.get('xref_output'),
        provider=provider,
        context=context,
    )

    print("%s %s" % (msg, output_string))
    return True
