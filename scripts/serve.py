#!/usr/bin/env python3
"""
Simple HTTP server to preview the Stencil Studio Web Workbench locally.
"""

import http.server
import socketserver
import os
import sys

PORT = 8080
DIRECTORY = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "web")

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def log_message(self, format, *args):
        # Suppress noisy request logs
        pass

def run():
    port = PORT
    for attempt in range(10):
        try:
            with socketserver.TCPServer(("", port), Handler) as httpd:
                print("==========================================================")
                print(f" Stencil Studio running at http://localhost:{port}")
                print(" Press Ctrl+C to terminate the server.")
                print("==========================================================")
                httpd.serve_forever()
        except OSError as e:
            if "Address already in use" in str(e):
                port += 1
            else:
                raise

if __name__ == "__main__":
    try:
        run()
    except KeyboardInterrupt:
        print("\nServer stopped.")
        sys.exit(0)
