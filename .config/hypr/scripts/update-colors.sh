#!/bin/bash

notify-send "Running Wallust"
wallust run $1
convert $1 ~/Pictures/current.png
rm -rf ~/.cache/fastfetch/

notify-send "Reloading hypr apps..."
hyprctl reload
~/.config/hypr/scripts/set-blur.sh
if pgrep -x "openrgb" >/dev/null; then
  ~/.config/hypr/scripts/update-rgb.sh
fi

notify-send "Colors updated successfully!"
