"""
Headless Spotify backend for the Quickshell bar.

Usage:
    spotify-backend.py search "<query>"
    spotify-backend.py playlists
    spotify-backend.py playlist <playlist_id>
    spotify-backend.py devices
    spotify-backend.py queue <track_uri> <device_id>

Never runs an interactive flow -- run spotify-auth.py once by hand first.
This only ever refreshes the token silently, same contract as
calendar-backend.py.
"""

import json
import os
import sys
import time
import urllib.parse
import urllib.error
import urllib.request

CONFIG_DIR = os.path.expanduser("~/.config/quickshell/scripts")
TOKEN_FILE = os.path.join(CONFIG_DIR, "spotify_token.json")

API_BASE = "https://api.spotify.com/v1"

PAGE_LIMIT = 10
MAX_ITEMS = 200


def load_token():
    """Return a valid access token, refreshing if needed. Never prompts."""
    if not os.path.exists(TOKEN_FILE):
        return None

    try:
        with open(TOKEN_FILE) as f:
            data = json.load(f)
    except Exception:
        return None

    if data.get("obtained_at", 0) + data.get("expires_in", 0) - 60 > time.time():
        return data["access_token"]

    try:
        resp = urllib.request.urlopen(
            urllib.request.Request(
                "https://accounts.spotify.com/api/token",
                data=urllib.parse.urlencode(
                    {
                        "grant_type": "refresh_token",
                        "refresh_token": data["refresh_token"],
                        "client_id": data["client_id"],
                        "client_secret": data["client_secret"],
                    }
                ).encode(),
                method="POST",
            )
        )
        new_data = json.loads(resp.read())
    except Exception:
        return None

    data["access_token"] = new_data["access_token"]
    data["expires_in"] = new_data.get("expires_in", 3600)
    data["obtained_at"] = time.time()
    if "refresh_token" in new_data:
        data["refresh_token"] = new_data["refresh_token"]

    try:
        with open(TOKEN_FILE, "w") as f:
            json.dump(data, f)
    except OSError:
        pass

    return data["access_token"]


def api_get(path, token, params=None):
    url = API_BASE + path
    if params:
        url += "?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {token}"})
    try:
        with urllib.request.urlopen(req, timeout=8) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"{e.code} {e.reason}: {body}") from None


def api_post(path, token, params=None):
    url = API_BASE + path
    if params:
        url += "?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(
        url, headers={"Authorization": f"Bearer {token}"}, method="POST"
    )
    try:
        urllib.request.urlopen(req, timeout=8)
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"{e.code} {e.reason}: {body}") from None


def api_put(path, token, body=None):
    url = API_BASE + path
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(
        url,
        data=data,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
        method="PUT",
    )
    try:
        with urllib.request.urlopen(req, timeout=8) as resp:
            return resp.read()
    except urllib.error.HTTPError as e:
        body_text = e.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"{e.code} {e.reason}: {body_text}") from None


def transfer_playback(token, device_id, start_playing=True):
    api_put("/me/player", token, {"device_ids": [device_id], "play": start_playing})


def search(token, query):
    data = api_get("/search", token, {"q": query, "type": "track", "limit": 10})
    tracks = data.get("tracks", {}).get("items", [])
    return [
        {
            "uri": t["uri"],
            "title": t["name"],
            "artist": ", ".join(a["name"] for a in t["artists"]),
            "durationMs": t["duration_ms"],
            "thumbnail": (
                t["album"]["images"][-1]["url"] if t["album"]["images"] else ""
            ),
        }
        for t in tracks
    ]


def fetch_paged(path, token, extra_params=None, max_items=MAX_ITEMS):
    items = []
    offset = 0
    while len(items) < max_items:
        params = dict(extra_params or {})
        params.update({"limit": PAGE_LIMIT, "offset": offset})
        data = api_get(path, token, params)

        page = data.get("items") or []
        items.extend(page)

        if len(page) < PAGE_LIMIT:
            break
        offset += PAGE_LIMIT

    return items[:max_items]


def get_queue(token):
    data = api_get("/me/player/queue", token)
    current = data.get("currently_playing")
    upcoming = data.get("queue") or []

    def to_track(t):
        if not t:
            return None
        artists = t.get("artists") or []
        album = t.get("album") or {}
        images = album.get("images") or []
        return {
            "uri": t.get("uri", ""),
            "title": t.get("name", "Unknown title"),
            "artist": ", ".join(a.get("name", "") for a in artists)
            if artists
            else "Unknown artist",
            "durationMs": t.get("duration_ms", 0),
            "thumbnail": images[-1]["url"] if images else "",
        }

    return {
        "current": to_track(current),
        "upcoming": [t for t in (to_track(x) for x in upcoming) if t],
    }


def get_playlists(token):
    raw = fetch_paged("/me/playlists", token)
    playlists = []
    for p in raw:
        if not p:
            continue
        playlists.append(
            {
                "id": p.get("id", ""),
                "name": p.get("name", "Untitled"),
                "thumbnail": (p["images"][0]["url"] if p.get("images") else ""),
                "trackCount": (p.get("tracks") or {}).get("total", 0),
            }
        )
    return playlists


def get_playlist_tracks(token, playlist_id):
    raw = fetch_paged(f"/playlists/{playlist_id}/items", token)
    tracks = []
    for entry in raw:
        t = entry.get("item")
        if not t:
            continue

        artists = t.get("artists") or []
        album = t.get("album") or {}
        images = album.get("images") or []

        tracks.append(
            {
                "uri": t.get("uri", ""),
                "title": t.get("name", "Unknown title"),
                "artist": ", ".join(a.get("name", "") for a in artists)
                if artists
                else "Unknown artist",
                "durationMs": t.get("duration_ms", 0),
                "thumbnail": images[-1]["url"] if images else "",
            }
        )
    return tracks


def get_devices(token):
    data = api_get("/me/player/devices", token)
    return data.get("devices", [])


def queue_track(token, uri, device_id):
    api_post("/me/player/queue", token, {"uri": uri, "device_id": device_id})


def main():
    token = load_token()
    if token is None:
        print(json.dumps({"ok": False, "error": "no-auth"}))
        return 0

    args = sys.argv[1:]
    if not args:
        print(json.dumps({"ok": False, "error": "no-command"}))
        return 0

    try:
        if args[0] == "search":
            print(json.dumps({"ok": True, "results": search(token, args[1])}))
        elif args[0] == "playlists":
            print(json.dumps({"ok": True, "playlists": get_playlists(token)}))
        elif args[0] == "playlist":
            print(
                json.dumps({"ok": True, "tracks": get_playlist_tracks(token, args[1])})
            )
        elif args[0] == "activate":
            transfer_playback(token, args[1], start_playing=False)
            print(json.dumps({"ok": True}))
        elif args[0] == "devices":
            print(json.dumps({"ok": True, "devices": get_devices(token)}))
        elif args[0] == "queue":
            queue_track(token, args[1], args[2])
            print(json.dumps({"ok": True}))
        elif args[0] == "queue_state":
            print(json.dumps({"ok": True, **get_queue(token)}))
        else:
            print(json.dumps({"ok": False, "error": "unknown-command"}))
    except Exception as exc:
        print(json.dumps({"ok": False, "error": str(exc)[:200]}))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
