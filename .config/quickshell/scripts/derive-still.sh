#!/bin/bash
# Prints the path to a single-frame, decodable image for a wallpaper source.
# Pass-through for still images; frame 0 into a content-keyed cache otherwise.
#
# Everything downstream that needs PIXELS goes through this — wallust,
# current.png, preset previews. Only the display dispatcher cares about
# the original format. Identity stays with the source path everywhere.
#
# usage: derive-still.sh <source>   → stdout: path to a still image
set -euo pipefail

src="${1:-}"
[ -n "$src" ] || {
  echo "usage: derive-still.sh <source>" >&2
  exit 1
}
[ -f "$src" ] || {
  echo "derive-still: no such file: $src" >&2
  exit 1
}

case "${src,,}" in
*.png | *.jpg | *.jpeg | *.bmp | *.tiff)
  printf '%s\n' "$src"
  exit 0
  ;;
esac

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/stills"
mkdir -p "$cache_dir"

mtime=$(stat -c %Y "$src" 2>/dev/null || echo 0)
key=$(printf '%s' "$src:$mtime" | md5sum | cut -d' ' -f1)
out="$cache_dir/$key.png"

[ -s "$out" ] && {
  printf '%s\n' "$out"
  exit 0
}

tmp="$cache_dir/.tmp.$$.$key.png"
trap 'rm -f "$tmp"' EXIT

case "${src,,}" in
*.gif | *.webp)
  magick "$src[0]" "$tmp"
  ;;
*.mp4 | *.webm | *.mkv | *.mov)
  ffmpeg -loglevel error -i "$src" -frames:v 1 -y "$tmp"
  ;;
*)
  echo "derive-still: unsupported format: $src" >&2
  exit 1
  ;;
esac

mv "$tmp" "$out"
printf '%s\n' "$out"
