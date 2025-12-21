#!/bin/bash

notify-send "Running Wallust"
wallust run $1
convert $1 ~/Pictures/current.png
magick ~/Pictures/current.png -fill black -colorize 50% ~/Pictures/current-dark.png
rm -rf ~/.cache/fastfetch/

notify-send "Reloading hypr apps..."
hyprctl reload
swaync-client -rs
killall waybar && waybar &
if pgrep -x "openrgb" >/dev/null; then
  ~/.config/hypr/scripts/update-rgb.sh
fi

notify-send "Colors updated successfully!"
