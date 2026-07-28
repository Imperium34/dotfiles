#!/bin/bash
# Generates preview JSON for every theme preset in parallel instead of one
# at a time, and skips presets that are already cached for this exact
# wallpaper + preset-config combo.
#
# Cache key = md5(wallpaper path + preset .toml mtime), so:
#   - revisiting a wallpaper you've already previewed costs nothing
#   - editing a preset's .toml (mtime changes) invalidates just that preset
#
# usage: generate-presets.sh <wallpaper> <presets_dir> <out_dir> <preset1> [preset2 ...]
# stdout: one "<preset>:<json_path>" line per known preset, for the caller
# to build a preset -> preview-file map. Missing/failed presets are omitted.
set -euo pipefail

# If this script gets killed (e.g. the picker restarts generation because the
# wallpaper changed again before the previous batch finished), make sure any
# already-backgrounded preview-theme.sh jobs get killed too instead of running
# on as orphans.
cleanup() {
  jobs -p | xargs -r kill 2>/dev/null || true
}
trap cleanup EXIT TERM INT

wallpaper="$1"
shift
presets_dir="$1"
shift
out_dir="$1"
shift

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

declare -A outfiles
pids=()

for preset in "$@"; do
  preset_toml="$presets_dir/$preset.toml"
  [ -f "$preset_toml" ] || continue

  wp_mtime=$(stat -c %Y "$wallpaper" 2>/dev/null || echo 0)
  toml_mtime=$(stat -c %Y "$preset_toml" 2>/dev/null || echo 0)
  key=$(printf '%s' "$wallpaper:$wp_mtime:$toml_mtime" | md5sum | cut -d' ' -f1)
  out_json="$out_dir/wallust-preview-${preset}-${key}.json"
  outfiles["$preset"]="$out_json"

  if [ -f "$out_json" ]; then
    continue # already generated for this exact wallpaper+config, skip
  fi

  "$script_dir/preview-theme.sh" "$wallpaper" "$preset_toml" "$out_json" &
  pids+=("$!")
done

# Wait for all backgrounded generations; don't let one failure kill the rest
for pid in "${pids[@]:-}"; do
  [ -n "$pid" ] && wait "$pid" || true
done

printf '#wallpaper:%s\n' "$wallpaper"

for preset in "$@"; do
  out="${outfiles[$preset]:-}"
  [ -n "$out" ] && [ -s "$out" ] && echo "$preset:$out"
done
