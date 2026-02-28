#!/bin/bash
USER_INPUT=$(echo "" | wofi --dmenu --style ~/.config/wofi/style.css --prompt "Ask Friday:")

if [ -n "$USER_INPUT" ]; then
  fish -c "friday $USER_INPUT" &
  notify-send -t 2000 "Friday" "Processing..."
fi
