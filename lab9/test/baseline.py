# baseline.py: Simple Python single-threaded HTTP server
import http.server
import socketserver
import os

PORT = 8080
WEBROOT = "./www"
os.chdir(WEBROOT)

Handler = http.server.SimpleHTTPRequestHandler

class ReusableTCPServer(socketserver.TCPServer):
    allow_reuse_address = True

with ReusableTCPServer(("", PORT), Handler) as httpd:
    print(f"Serving at http://localhost:{PORT}")
    httpd.serve_forever()
