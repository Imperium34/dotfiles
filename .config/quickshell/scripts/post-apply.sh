#!/bin/bash
# Shared post-processing that runs after `wallust run` succeeds: swaps the
# wallpaper cache, clears fastfetch's cache, reloads hyprland, reapplies blur,
# and syncs RGB if openrgb is running. Sourced by apply-theme.sh and
# update-colors.sh so this sequence only has to be edited in one place.
set -euo pipefail

post_apply() {
  local wallpaper="$1"

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
}
