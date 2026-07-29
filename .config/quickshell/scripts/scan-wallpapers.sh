#!/bin/bash
# Lists wallpapers with a renderable thumbnail for each.
# Output: <relpath>\t<thumb-abs-path>
#
# Video sources get their derived still, since QML's Image can't decode
# them. Everything else points at itself. Qt renders frame 0 of a GIF
# or WebP fine, and we want the picker showing the real file.
set -euo pipefail

root_dir="${1:-$HOME/Pictures/wallpapers}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "$root_dir" 2>/dev/null || exit 0

find . -mindepth 2 -maxdepth 2 -type f | sed 's|^\./||' | sort | while IFS= read -r f; do
  case "${f,,}" in
  *.jpg | *.jpeg | *.png | *.bmp | *.tiff | *.gif | *.webp)
    printf '%s\t%s/%s\n' "$f" "$root_dir" "$f"
    ;;
  *.mp4 | *.webm | *.mkv | *.mov)
    still=$("$script_dir/derive-still.sh" "$root_dir/$f" 2>/dev/null) || continue
    printf '%s\t%s\n' "$f" "$still"
    ;;
  esac
done
