#!/bin/bash
set -euo pipefail

wallpaper="$1"

if [ -z "$wallpaper" ]; then
  notify-send "Wallust" "No wallpaper path given" -u critical
  exit 1
fi

notify-send "Running Wallust"

if ! wallust run "$wallpaper"; then
  notify-send "Wallust failed" "Check the image format/path" -u critical
  exit 1
fi

if ! magick "$wallpaper" ~/Pictures/current.png; then
  notify-send "Wallust" "Theme updated but wallpaper copy failed" -u critical
  exit 1
fi

rm -rf ~/.cache/fastfetch/

notify-send "Reloading hypr apps..."
hyprctl reload
~/.config/hypr/scripts/set-blur.sh
if pgrep -x "openrgb" >/dev/null; then
  ~/.config/quickshell/scripts/update-rgb.sh
fi
notify-send "Colors updated successfully!"
