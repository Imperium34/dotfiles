#!/bin/bash
# usage: set-blur.sh [on|off]
#
#   on|off   explicit -- used by Quickshell's PowerActions, which is the
#            authoritative source for power-reactive state
#   no arg   auto-detect from battery status. Still needed by post-apply.sh,
#            which calls this after `hyprctl reload` re-applies machine.lua's
#            static blur default and wipes whatever was set at runtime.
set -euo pipefail

mode="${1:-auto}"

if [[ "$mode" == "auto" ]]; then
  BAT_PATH=$(find /sys/class/power_supply -name "BAT*" | head -n 1)
  [[ -n "$BAT_PATH" ]] || exit 0 # no battery (desktop): nothing to do

  STATUS=$(tr '[:lower:]' '[:upper:]' <"$BAT_PATH/status")
  if [[ "$STATUS" == *"DISCHARGING"* ]]; then
    mode="off"
  else
    mode="on"
  fi
fi

case "$mode" in
on) hyprctl eval "hl.config({ decoration = { blur = { enabled = true } } })" ;;
off) hyprctl eval "hl.config({ decoration = { blur = { enabled = false } } })" ;;
*)
  echo "usage: set-blur.sh [on|off]" >&2
  exit 1
  ;;
esac
