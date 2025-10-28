#!/bin/bash

#notify-send "Running Wallust"
wallust run $1
convert $1 /home/ali/Pictures/current.png

# 5. Reload Hyprland and Dunst
#notify-send "Reloading hypr apps..."
hyprctl reload
killall mako && mako &
killall waybar && waybar &

notify-send "Colors updated successfully!"
