#!/bin/bash
STATE_FILE="$HOME/.cache/hypr/dp3-disabled"

if [ -f "$STATE_FILE" ]; then
  rm "$STATE_FILE"
  hyprctl keyword monitor "DP-3,auto,0x0,1"
  notify-send "DP-3 enabled"
else
  mkdir -p "$(dirname "$STATE_FILE")"
  touch "$STATE_FILE"
  hyprctl keyword monitor "DP-3,disable"
  notify-send "DP-3 disabled"
fi
