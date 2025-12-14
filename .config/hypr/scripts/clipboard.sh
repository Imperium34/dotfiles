#!/bin/bash

CLEAR_BTN="🗑️ Clear History"

selected=$(echo -e "$CLEAR_BTN\n$(cliphist list)" | wofi --dmenu --style ~/.config/wofi/style.css --prompt "Clipboard" --show dmenu)

if [[ "$selected" == "$CLEAR_BTN" ]]; then
  cliphist wipe
  notify-send "Clipboard" "History cleared successfully"
  wl-copy ""
elif [[ -n "$selected" ]]; then
  echo "$selected" | cliphist decode | wl-copy
fi
