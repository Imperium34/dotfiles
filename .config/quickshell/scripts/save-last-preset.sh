#!/bin/bash
# Records which preset was last applied to a given wallpaper, so the picker
# can pre-highlight it next time. Called with plain argv (not string-
# interpolated into a shell command) so wallpaper paths with spaces/special
# characters are handled safely.
#
# usage: save-last-preset.sh <wallpaper> <preset> <state_file>
set -euo pipefail

wallpaper="$1"
preset="$2"
state_file="$3"

mkdir -p "$(dirname "$state_file")"
[ -f "$state_file" ] || echo '{}' >"$state_file"

tmp=$(mktemp -p "$(dirname "$state_file")")
trap 'rm -f "$tmp"' EXIT

if jq --arg k "$wallpaper" --arg v "$preset" '.[$k] = $v' "$state_file" >"$tmp"; then
  mv "$tmp" "$state_file"
fi
