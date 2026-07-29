#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-$HOME/Pictures/wallpapers}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export ROOT_DIR SCRIPT_DIR

cd "$ROOT_DIR" 2>/dev/null || exit 0

gen_line() {
  local rel="$1" thumb
  thumb=$("$SCRIPT_DIR/wallpaper-thumbnail.sh" "$ROOT_DIR/$rel" 2>/dev/null) || return 0
  printf '%s\t%s\n' "$rel" "$thumb"
}
export -f gen_line

find . -mindepth 2 -maxdepth 2 -type f \
  \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
  -o -iname '*.bmp' -o -iname '*.tiff' -o -iname '*.gif' \
  -o -iname '*.webp' -o -iname '*.mp4' -o -iname '*.webm' \
  -o -iname '*.mkv' -o -iname '*.mov' \) |
  sed 's|^\./||' |
  xargs -d '\n' -r -P "$(nproc)" -I{} bash -c 'gen_line "$@"' _ {} |
  sort
