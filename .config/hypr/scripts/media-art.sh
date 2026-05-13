#!/bin/bash

ART_PATH="/tmp/cover.png"
DEFAULT_ART="$HOME/.config/hypr/assets/album_placeholder.png"
TEMP_ART="/tmp/temp_art_download"

# Ensure the fallback exists (creates a transparent 1x1 png if missing)
if [[ ! -f "$DEFAULT_ART" ]]; then
  mkdir -p "$(dirname "$DEFAULT_ART")"
  convert -size 500x500 xc:transparent "$DEFAULT_ART" 2>/dev/null || touch "$DEFAULT_ART"
fi

# Function to handle the Art update
update_art() {
  url="$1"

  if [[ "$url" == "No players found" ]]; then
    cp "$DEFAULT_ART" "$ART_PATH"
    return
  fi

  # Ignore empty strings to prevent overwriting the good art with ghost events
  if [[ -z "$url" ]]; then
    return
  fi

  if [[ "$url" == http* ]]; then
    # Extract YouTube video ID if present
    if [[ "$url" =~ /vi/([^/]+)/ ]]; then
      video_id="${BASH_REMATCH[1]}"
      hd_url="https://img.youtube.com/vi/${video_id}/maxresdefault.jpg"
    else
      hd_url="$url"
    fi

    # Download HD art
    curl -s -o "$TEMP_ART" "$hd_url"

    # If the file is too small (< 1500 bytes), fallback to the raw URL
    if [[ -f "$TEMP_ART" ]]; then
      filesize=$(stat -c%s "$TEMP_ART" 2>/dev/null || stat -f%z "$TEMP_ART" 2>/dev/null)
      if [[ -n "$filesize" ]] && [[ "$filesize" -lt 1500 ]]; then
        curl -s -o "$TEMP_ART" "$url"
      fi
    fi

    # Process with ImageMagick - Force 500x500 center crop
    magick "$TEMP_ART" -filter Lanczos -resize "500x500^" -gravity center -extent 500x500 -unsharp 0x1 "$ART_PATH"

  elif [[ "$url" == "file://"* ]]; then
    local_path="${url#file://}"
    # Apply the exact same center-crop logic to local files
    magick "$local_path" -filter Lanczos -resize "500x500^" -gravity center -extent 500x500 -unsharp 0x1 "$ART_PATH"

  else
    cp "$DEFAULT_ART" "$ART_PATH"
  fi
}

# Fetch the current art immediately on startup
initial_url=$(playerctl metadata mpris:artUrl 2>/dev/null)
update_art "$initial_url"

# Infinite loop to keep script alive
while true; do
  # 1. Listen for future changes
  playerctl metadata --format '{{ mpris:artUrl }}' --follow | while read -r url; do
    update_art "$url"
  done

  # 2. If we reach this line, it means playerctl died (no players left)
  # So we force the default art immediately
  cp "$DEFAULT_ART" "$ART_PATH"

  # 3. Wait 2 seconds before checking for new players to save CPU
  sleep 2
done
