#!/bin/bash
# Top layer: puts a wallpaper on screen AND regenerates colors.
# Colour-only changes (preset switching) call apply-theme.sh directly so
# they don't re-trigger a display transition.
#
# usage: apply-wallpaper.sh <source> [preset.toml]
set -euo pipefail

source_img="${1:-}"
preset_config="${2:-}"

if [ -z "$source_img" ]; then
  notify-send "Wallpaper" "No wallpaper path given" -u critical
  exit 1
fi

TRANS_TYPE="${AWWW_TRANSITION_TYPE:-grow}"
TRANS_POS="${AWWW_TRANSITION_POS:-center}"
TRANS_DUR="${AWWW_TRANSITION_DURATION:-0.7}"
TRANS_FPS="${AWWW_TRANSITION_FPS:-144}"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
still=$("$script_dir/derive-still.sh" "$source_img")

# Drop any existing video layer first so awww's transition is visible.
"$script_dir/video-wallpaper.sh" clear

awww_args=(--transition-type "$TRANS_TYPE" --transition-pos "$TRANS_POS"
  --transition-duration "$TRANS_DUR" --transition-fps "$TRANS_FPS")

case "${source_img,,}" in
*.mp4 | *.webm | *.mkv | *.mov)
  awww img "$still" "${awww_args[@]}"
  "$script_dir/video-wallpaper.sh" start "$source_img" "$TRANS_DUR"
  ;;
*)
  awww img "$source_img" "${awww_args[@]}"
  ;;
esac

"$script_dir/apply-theme.sh" "$source_img" "$preset_config"
