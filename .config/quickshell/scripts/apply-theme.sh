#!/bin/bash
set -euo pipefail

wallpaper="$1"
preset_config="${2:-}"   # optional: a preset's global-options-only toml.
                         # Empty = current default behavior (main wallust.toml).

if [ -z "$wallpaper" ]; then
  notify-send "Wallust" "No wallpaper path given" -u critical
  exit 1
fi

notify-send "Running Wallust"

run_config="$HOME/.config/wallust/wallust.toml"

if [ -n "$preset_config" ]; then
  # Merge the preset's color-generation mood with the REAL templates list,
  # so applying a preset still updates alacritty/gtk/hyprland/etc, exactly
  # like a normal wallpaper change does today. This keeps the templates
  # list defined in ONE place (your real wallust.toml) so it never drifts
  # out of sync with the presets.
  preset_opts=$(sed '/^\[templates\]/,$d' "$preset_config")
  real_templates=$(sed -n '/^\[templates\]/,$p' "$run_config")

  tmp_toml=$(mktemp --suffix=.toml)
  trap 'rm -f "$tmp_toml"' EXIT
  {
    echo "$preset_opts"
    echo
    echo "$real_templates"
  } > "$tmp_toml"

  run_config="$tmp_toml"
fi

if ! wallust run -C "$run_config" "$wallpaper"; then
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
