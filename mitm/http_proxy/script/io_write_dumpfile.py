import sys
from mitmproxy import io

class Writer:
    def __init__(self, path):
        if path == "-":
            f = sys.stdout
        else:
            f = open(path, "ab")
        self.w = io.FlowWriter(f)

    def request(self, flow):
        if flow.request.method == 'POST':
            self.w.add(flow)

def start():
    if len(sys.argv) != 2:
        raise ValueError('Usage: -s "io_write_dumpfile.py filename"')
    return Writer(sys.argv[1])
