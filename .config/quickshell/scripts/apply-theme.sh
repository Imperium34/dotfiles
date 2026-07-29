#!/bin/bash
set -euo pipefail

wallpaper="${1:-}"
preset_config="${2:-}" # optional: a preset's global-options-only toml.
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
  } >"$tmp_toml"

  run_config="$tmp_toml"
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

lock_dir="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell"
mkdir -p "$lock_dir"
exec 9>"$lock_dir/apply.lock"
flock 9

still=$("$script_dir/derive-still.sh" "$wallpaper")

if ! wallust run -C "$run_config" "$still"; then
  notify-send "Wallust failed" "Check the image format/path" -u critical
  exit 1
fi

source "$script_dir/post-apply.sh"
post_apply "$wallpaper" "$still"
