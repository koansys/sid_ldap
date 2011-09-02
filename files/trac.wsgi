import os

os.environ['TRAC_PARENT_ENV'] = '/tmp/trac'
os.environ['PYTHON_EGG_CACHE'] = '/tmp'

import trac.web.main
application = trac.web.main.dispatch_request