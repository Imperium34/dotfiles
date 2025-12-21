#!/usr/bin/env python3
import subprocess
import sys
import os
import re
import json
import textwrap

# Define paths
ART_DEST = "/tmp/album_art.png"
FALLBACK_ART = os.path.expanduser("~/.config/hypr/assets/fallback.png")


def get_metadata():
    try:
        # Run RAW command (Robust)
        cmd = "playerctl metadata"
        output = subprocess.check_output(cmd, shell=True).decode("utf-8").strip()
    except Exception:
        return None

    if not output:
        return None

    # Default Data
    data = {
        "title": "Unknown",
        "artist": "",
        "length": 0,
        "position": 0,
        "art_url": "",
        "status": "Stopped",
        "player": "Unknown",
    }

    try:
        pos_cmd = "playerctl position"
        pos_output = (
            subprocess.check_output(pos_cmd, shell=True).decode("utf-8").strip()
        )
        if pos_output:
            data["position"] = int(float(pos_output) * 1000000)
    except:
        pass

    try:
        status_cmd = "playerctl status"
        status_output = (
            subprocess.check_output(status_cmd, shell=True).decode("utf-8").strip()
        )
        if status_output:
            data["status"] = status_output
    except:
        pass

    for line in output.split("\n"):
        parts = line.split(maxsplit=2)
        if len(parts) < 3:
            continue

        data["player"] = parts[0]
        key = parts[1]
        value = parts[2]

        if "xesam:title" in key:
            data["title"] = value
        elif "xesam:artist" in key:
            data["artist"] = value
        elif "mpris:artUrl" in key:
            data["art_url"] = value
        elif "mpris:length" in key:
            try:
                data["length"] = int(value)
            except:
                pass
        elif "status" in key:
            data["status"] = value

    return data


def format_time(microseconds):
    seconds = microseconds // 1000000
    return f"{seconds // 60:02}:{seconds % 60:02}"


def draw_bar(percent, width=10):
    if percent > 1:
        percent = percent / 100
    percent = max(0.0, min(1.0, percent))
    filled = int(width * percent)
    return "━" * filled + "●" + "─" * (width - filled - 1)


def truncate(text, limit=20):
    if not text:
        return ""
    return text[:limit] + "..." if len(text) > limit else text


def main():
    data = get_metadata()

    if not data:
        if len(sys.argv) > 1 and sys.argv[1] == "--waybar":
            print(json.dumps({"text": "", "alt": "stopped", "class": "stopped"}))
        else:
            print("")
        return

    # --- Mode 1: Waybar (JSON) ---
    if len(sys.argv) > 1 and sys.argv[1] == "--waybar":
        percent = 0
        percent_float = 0.0
        if data["length"] > 0:
            raw_percent = float(data["position"]) / float(data["length"])
            percent = int(raw_percent * 100)
            percent_float = raw_percent

        player_name = data["player"].lower()
        if "spotify" in player_name:
            icon = ""
        elif "firefox" in player_name or "zen" in player_name:
            icon = ""
        elif "mpv" in player_name or "mps-youtube" in player_name:
            icon = ""
        else:
            icon = ""

        if data["artist"]:
            text = (
                f"{icon}  {truncate(data['title'], 10)} - {truncate(data['artist'], 5)}"
            )
        else:
            text = f"{icon}  {truncate(data['title'], 20)}"

        tooltip_bar = draw_bar(percent_float, width=25)
        wrapped_title = textwrap.fill(data["title"], width=40)
        wrapped_artist = textwrap.fill(data["artist"], width=40)
        tooltip_text = f"{wrapped_title}\n{wrapped_artist}\n\n{format_time(data['position'])} {tooltip_bar} {format_time(data['length'])}"

        out = {
            "text": text,
            "tooltip": tooltip_text,
            "class": data["status"],
            "alt": data["player"],
            "percentage": percent,
        }
        print(json.dumps(out))
        return

    # --- Mode 2: Hyprlock / Art ---
    if len(sys.argv) > 1 and sys.argv[1] == "--art":
        try:
            raw_url = subprocess.check_output(
                ["playerctl", "metadata", "mpris:artUrl"], text=True
            ).strip()
        except:
            raw_url = ""

        target_file = "/tmp/album_art.png"
        temp_file = "/tmp/temp_art_download"

        video_id_match = re.search(r"/vi/([^/]+)/", raw_url)

        hd_url = raw_url
        if video_id_match:
            video_id = video_id_match.group(1)
            hd_url = f"https://img.youtube.com/vi/{video_id}/maxresdefault.jpg"

        final_url = raw_url

        if raw_url.startswith("http"):
            subprocess.run(["curl", "-s", "-o", temp_file, hd_url])

            if os.path.getsize(temp_file) < 1500:
                subprocess.run(["curl", "-s", "-o", temp_file, raw_url])

            subprocess.run(
                [
                    "magick",
                    temp_file,
                    "-filter",
                    "Lanczos",
                    "-resize",
                    "500x500^",
                    "-gravity",
                    "center",
                    "-extent",
                    "500x500",
                    "-unsharp",
                    "0x1",
                    target_file,
                ]
            )

        elif raw_url.startswith("file://"):
            local_path = raw_url.replace("file://", "")
            subprocess.run(["magick", local_path, "-resize", "500x500^", target_file])

        else:
            subprocess.run(
                ["convert", "-size", "500x500", "xc:transparent", target_file]
            )

        print(target_file)
        sys.exit(0)

    # --- Mode 3: Text Info (Hyprlock) ---
    if len(sys.argv) > 1:
        if sys.argv[1] == "--title":
            print(truncate(data["title"], 30))
        elif sys.argv[1] == "--artist":
            print(truncate(data["artist"], 20))
        elif sys.argv[1] == "--bar":
            length = data["length"]
            if length > 0:
                percent = max(0, min(1, data.get("position", 0) / length))
                print(
                    f"{format_time(data.get('position', 0))} {draw_bar(percent, 30)} {format_time(length)}"
                )
            else:
                print("   LIVE 🔴   ")


if __name__ == "__main__":
    main()
