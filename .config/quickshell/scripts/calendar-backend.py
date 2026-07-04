#!/usr/bin/env python3
import json
import urllib.request
import datetime
import os.path
import sys

from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build

SCOPES = ["https://www.googleapis.com/auth/calendar.readonly"]
CREDENTIALS_FILE = os.path.expanduser("~/.config/quickshell/scripts/credentials.json")
TOKEN_FILE = os.path.expanduser("~/.config/quickshell/scripts/token.json")


def get_weather(lat="41.02", lon="28.58"):
    url = f"https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}&current_weather=true"
    try:
        req = urllib.request.urlopen(url, timeout=3)
        data = json.loads(req.read())
        cw = data.get("current_weather", {})
        temp = round(cw.get("temperature", 0))
        code = cw.get("weathercode", 0)

        icon = "󰖙"
        if code in [1, 2, 3]:
            icon = "󰖕"
        elif code in [45, 48]:
            icon = "󰖑"
        elif code in [51, 53, 55, 56, 57, 61, 63, 65]:
            icon = "󰖗"
        elif code in [71, 73, 75, 77]:
            icon = "󰖘"
        elif code in [95, 96, 99]:
            icon = "󰖓"

        return {"temp": temp, "icon": icon}
    except Exception:
        return {"temp": "--", "icon": "󰖐"}


def get_calendar_events():
    creds = None
    if os.path.exists(TOKEN_FILE):
        creds = Credentials.from_authorized_user_file(TOKEN_FILE, SCOPES)

    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            if not os.path.exists(CREDENTIALS_FILE):
                return []
            flow = InstalledAppFlow.from_client_secrets_file(CREDENTIALS_FILE, SCOPES)
            creds = flow.run_local_server(port=0)
        with open(TOKEN_FILE, "w") as token:
            token.write(creds.to_json())

    try:
        service = build("calendar", "v3", credentials=creds)
        now = datetime.datetime.utcnow()
        start_of_month = (
            now.replace(day=1, hour=0, minute=0, second=0).isoformat() + "Z"
        )

        events_result = (
            service.events()
            .list(
                calendarId="primary",
                timeMin=start_of_month,
                maxResults=50,
                singleEvents=True,
                orderBy="startTime",
            )
            .execute()
        )

        events = events_result.get("items", [])
        formatted_events = []

        for event in events:
            start = event["start"].get("dateTime", event["start"].get("date"))
            date_key = start[:10]
            time_str = start[11:16] if "T" in start else "All Day"

            formatted_events.append(
                {
                    "date": date_key,
                    "title": event.get("summary", "Busy"),
                    "time": time_str,
                }
            )
        return formatted_events
    except Exception:
        return []


if __name__ == "__main__":
    lat = sys.argv[1] if len(sys.argv) > 1 else "41.02"
    lon = sys.argv[2] if len(sys.argv) > 2 else "28.58"

    output = {"weather": get_weather(lat, lon), "events": get_calendar_events()}
    print(json.dumps(output))
