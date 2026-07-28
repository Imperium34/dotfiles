#!/bin/bash
# Generates a preview theme.json for one wallust preset, WITHOUT touching
# any real app config (alacritty/gtk/hyprland/etc). Reuses the existing
# quickshell-theme.json.hbs template but points it at a scratch file.
set -euo pipefail

wallpaper="$1"     # path to the currently selected wallpaper
preset_config="$2" # e.g. ~/.config/quickshell/wallust-presets/vibrant.toml
# (only needs the global options: backend/color_space/
# palette/saturation/check_contrast — no [templates])
out_json="$3" # e.g. /tmp/wallust-preview-vibrant.json

if [ -z "$wallpaper" ] || [ -z "$preset_config" ] || [ -z "$out_json" ]; then
  echo "usage: preview-theme.sh <wallpaper> <preset.toml> <out.json>" >&2
  exit 1
fi

# Pull just the global options out of the preset, in case it has its own
# [templates] section left in by mistake — we don't want that here.
global_opts=$(sed '/^\[templates\]/,$d' "$preset_config")

tmp_toml=$(mktemp --suffix=.toml)
trap 'rm -f "$tmp_toml" "$out_json.tmp"' EXIT

{
  echo "$global_opts"
  echo
  echo "[templates]"
  echo "preview = { template = 'quickshell-theme.json.hbs', target = '$out_json.tmp' }"
} >"$tmp_toml"

wallust run -s -q -C "$tmp_toml" "$wallpaper"
mv "$out_json.tmp" "$out_json"
