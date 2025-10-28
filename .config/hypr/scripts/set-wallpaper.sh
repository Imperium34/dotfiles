#!/bin/bash

# Check for wallpaper argument
if [ -z "$1" ]; then
  echo "Usage: $0 /path/to/wallpaper"
  exit 1
fi

WALLPAPER="$1"

# --- Option 2: Using waypaper ---
# This uses the waypaper CLI.
# Make sure the daemon is running! (exec-once = waypaper --daemonize)
#
waypaper --wallpaper "$WALLPAPER"

# ----------------------------------------
# (B) PYWAL: GENERATE AND APPLY COLORS
# ----------------------------------------

# 2. Generate colors with pywal
# -n = skip setting the wallpaper (our tool already did)
# -t = skip changing terminal colors
# -q = quiet
echo "Generating colors with pywal..."
wal -i "$WALLPAPER" -n -t -q

# 3. Reload Hyprland to apply new colors to borders, etc.
echo "Reloading Hyprland..."
hyprctl reload

# 4. Relaunch themed apps to pick up new pywal colors
echo "Relaunching themed apps..."
# killall dunst && dunst &

# Add any other apps you want to reload here (e.g., waybar)
killall waybar && waybar &

echo "Wallpaper and colors updated successfully."
