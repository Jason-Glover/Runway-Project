from contextlib import contextmanager
from subprocess import check_call

import io
import os

from distutils.version import LooseVersion
from runway.cfngin.session_cache import get_session
from runway.cfngin.hooks import utils
from runway.cfngin.lookups.handlers.rxref import RxrefLookup
xref_handler = RxrefLookup.handle

def upload(provider, context, **kwargs):  # pylint: disable=W0613
    s3_file_key = kwargs.get('s3_file_key', 'common')
    local_path = kwargs.get('local_path', 'undefined')
    local_file = kwargs.get('local_file', 'undefined')

    bucket = xref_handler(
        kwargs.get('bucket_xref'),
        provider=provider,
        context=context,
    )

    session = get_session(provider.region)
    client = session.client('s3')

    print("Uploading %s/%s to bucket: s3://%s/" % (local_path, local_file, bucket))
    client.put_object(Body=open(os.path.join(local_path, local_file), 'rb'),
                      Bucket=bucket,
                      Key='%s' % (s3_file_key),
                      ContentType='text/html'
                      )
    return True
