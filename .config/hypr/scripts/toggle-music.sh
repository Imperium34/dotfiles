#!/bin/bash

if ! hyprctl clients | grep -q "class: music"; then
  alacritty --class music -e yt &
  sleep 0.2
fi

hyprctl dispatch togglespecialworkspace music
