#!/bin/bash

GENERATOR="$HOME/.config/hypr/scripts/media-player.py"
ART_FILE="/tmp/album_art.png"

playerctl metadata --format '{{ mpris:artUrl }}' --follow | while read -r url; do
  python3 "$GENERATOR" --art
done
