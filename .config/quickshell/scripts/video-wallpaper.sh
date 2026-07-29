#!/bin/bash
# Owns the mpvpaper layer. Keeps a record of which video *should* be
# playing so it can be stopped and resumed (battery) independently of
# which wallpaper is applied.
#
#   start <src> [delay]  record + launch after delay
#   stop                 kill, keep the record (resumable)
#   resume               relaunch from the record, if any
#   clear                kill + forget
set -euo pipefail

state_dir="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell"
record="$state_dir/video-wallpaper"
mkdir -p "$state_dir"

MPV_OPTS="--loop-file=inf --no-audio --hwdec=auto --panscan=1.0"

launch() {
  pkill -x mpvpaper 2>/dev/null || true
  setsid mpvpaper -f -s -o "$MPV_OPTS" '*' "$1" >/dev/null 2>&1 &
}

case "${1:-}" in
start)
  src="${2:-}"
  delay="${3:-0}"
  [ -n "$src" ] || exit 1
  printf '%s\n' "$src" >"$record"
  setsid "$0" _delayed "$src" "$delay" >/dev/null 2>&1 &
  ;;
_delayed)
  sleep "$3"
  [ -s "$record" ] && [ "$(cat "$record")" = "$2" ] || exit 0
  launch "$2"
  ;;
stop) pkill -x mpvpaper 2>/dev/null || true ;;
resume) [ -s "$record" ] && launch "$(cat "$record")" || true ;;
clear)
  rm -f "$record"
  pkill -x mpvpaper 2>/dev/null || true
  ;;
*)
  echo "usage: video-wallpaper.sh <start|stop|resume|clear> [src] [delay]" >&2
  exit 1
  ;;
esac
