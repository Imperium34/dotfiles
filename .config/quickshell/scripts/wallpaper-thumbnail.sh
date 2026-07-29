#!/usr/bin/env bash
# wallpaper-thumbnail.sh <source>
# Prints a path to a small cached PNG preview.
#
# Always downscales. Never passes the source through, even for images.
# The point is keeping full-res decodes out of the picker: a 4K PNG costs
# ~35MB in memory regardless of the size it's drawn at.
#
# NOT the same artifact as derive-still.sh. That one must be frame 0
# (it's what awww shows under mpvpaper at handoff); this one seeks past
# the fade-in so the thumbnail isn't black.
set -euo pipefail

src="${1:?usage: wallpaper-thumbnail.sh <source>}"
[ -f "$src" ] || exit 1

width="${WALLPAPER_THUMB_WIDTH:-400}"
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/thumbs"
mkdir -p "$cache_dir"

mtime=$(stat -c %Y "$src" 2>/dev/null || echo 0)
key=$(printf '%s|%s|%s' "$src" "$mtime" "$width" | md5sum | cut -d' ' -f1)
out="$cache_dir/$key.png"

[ -s "$out" ] && {
  printf '%s\n' "$out"
  exit 0
}

tmp="$cache_dir/.tmp.$$.$key.png"
trap 'rm -f "$tmp"' EXIT

case "${src,,}" in
*.mp4 | *.webm | *.mkv | *.mov)
  ffmpeg -y -loglevel error -ss 1 -i "$src" -frames:v 1 \
    -vf "scale=$width:-1" -update 1 "$tmp" 2>/dev/null ||
    ffmpeg -y -loglevel error -i "$src" -frames:v 1 \
      -vf "scale=$width:-1" -update 1 "$tmp" 2>/dev/null ||
    exit 1
  ;;
*)
  magick "$src[0]" -resize "${width}x" -strip "$tmp" 2>/dev/null || exit 1
  ;;
esac

[ -s "$tmp" ] || exit 1
mv "$tmp" "$out"
printf '%s\n' "$out"
