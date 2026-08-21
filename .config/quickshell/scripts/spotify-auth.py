"""
One-time interactive Spotify OAuth setup.

Usage:
    spotify-auth.py

Run this by hand once. It opens a browser, you log in and approve, and it
mints token.json. After that, spotify-backend.py refreshes silently forever
and never opens a browser -- same split as calendar-auth.py/calendar-backend.py.
"""

import json
import os
import urllib.parse
import urllib.request
import webbrowser
from http.server import BaseHTTPRequestHandler, HTTPServer

CONFIG_DIR = os.path.expanduser("~/.config/quickshell/scripts")
CREDENTIALS_FILE = os.path.join(CONFIG_DIR, "spotify_credentials.json")
TOKEN_FILE = os.path.join(CONFIG_DIR, "spotify_token.json")

REDIRECT_URI = "http://127.0.0.1:8888/callback"
SCOPES = "user-read-playback-state user-modify-playback-state playlist-read-private"

_auth_code = {}


class CallbackHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        params = urllib.parse.parse_qs(parsed.query)
        if "code" in params:
            _auth_code["code"] = params["code"][0]
            body = b"<html><body>Done, you can close this tab.</body></html>"
        else:
            body = b"<html><body>No code received.</body></html>"
        self.send_response(200)
        self.send_header("Content-Type", "text/html")
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *args):
        pass


def main():
    with open(CREDENTIALS_FILE) as f:
        creds = json.load(f)
    client_id = creds["client_id"]
    client_secret = creds["client_secret"]

    auth_url = "https://accounts.spotify.com/authorize?" + urllib.parse.urlencode(
        {
            "client_id": client_id,
            "response_type": "code",
            "redirect_uri": REDIRECT_URI,
            "scope": SCOPES,
        }
    )

    print("Opening browser for Spotify login...")
    webbrowser.open(auth_url)

    server = HTTPServer(("127.0.0.1", 8888), CallbackHandler)
    while "code" not in _auth_code:
        server.handle_request()

    token_resp = urllib.request.urlopen(
        urllib.request.Request(
            "https://accounts.spotify.com/api/token",
            data=urllib.parse.urlencode(
                {
                    "grant_type": "authorization_code",
                    "code": _auth_code["code"],
                    "redirect_uri": REDIRECT_URI,
                    "client_id": client_id,
                    "client_secret": client_secret,
                }
            ).encode(),
            method="POST",
        )
    )
    token_data = json.loads(token_resp.read())
    token_data["client_id"] = client_id
    token_data["client_secret"] = client_secret

    os.makedirs(CONFIG_DIR, exist_ok=True)
    with open(TOKEN_FILE, "w") as f:
        json.dump(token_data, f)

    print("Saved token to", TOKEN_FILE)


if __name__ == "__main__":
    main()
