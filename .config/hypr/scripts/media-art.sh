#!/bin/bash

ART_PATH="/tmp/cover.png"
DEFAULT_ART="$HOME/.config/hypr/assets/album_placeholder.png"

# Ensure the fallback exists (creates a transparent 1x1 png if missing)
if [[ ! -f "$DEFAULT_ART" ]]; then
  mkdir -p "$(dirname "$DEFAULT_ART")"
  convert -size 500x500 xc:transparent "$DEFAULT_ART" 2>/dev/null || touch "$DEFAULT_ART"
fi

# Function to handle the Art update
update_art() {
  url="$1"
  if [[ -z "$url" ]] || [[ "$url" == "No players found" ]]; then
    cp "$DEFAULT_ART" "$ART_PATH"
  elif [[ "$url" == "file://"* ]]; then
    cp "${url#file://}" "$ART_PATH"
  else
    curl -s -o "$ART_PATH" "$url"
  fi
}

# Infinite loop to keep script alive
while true; do
  # 1. Listen for changes
  playerctl metadata --format '{{ mpris:artUrl }}' --follow | while read -r url; do
    update_art "$url"
  done

  # 2. If we reach this line, it means playerctl died (no players left)
  # So we force the default art immediately
  cp "$DEFAULT_ART" "$ART_PATH"

  # 3. Wait 2 seconds before checking for new players to save CPU
  sleep 2
done
