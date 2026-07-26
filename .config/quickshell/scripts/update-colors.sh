#!/bin/bash
set -euo pipefail

wallpaper="$1"

if [ -z "$wallpaper" ]; then
  notify-send "Wallust" "No wallpaper path given" -u critical
  exit 1
fi

notify-send "Running Wallust"

if ! wallust run "$wallpaper"; then
  notify-send "Wallust failed" "Check the image format/path" -u critical
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/post-apply.sh"
post_apply "$wallpaper"
