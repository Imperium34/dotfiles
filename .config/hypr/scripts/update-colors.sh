#!/bin/bash

notify-send "Running Wallust"
wallust run $1
convert $1 ~/Pictures/current.png

notify-send "Reloading hypr apps..."
hyprctl reload
killall mako && mako &
killall waybar && waybar &
if pgrep -x "openrgb" > /dev/null; then
	~/.config/hypr/scripts/update-rgb.sh
fi

notify-send "Colors updated successfully!"
