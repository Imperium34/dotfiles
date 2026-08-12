#!/bin/bash
BAT_PATH=$(find /sys/class/power_supply -name "BAT*" | head -n 1)
[[ -z "$BAT_PATH" ]] && exit 0

STATUS=$(tr '[:lower:]' '[:upper:]' <"$BAT_PATH/status")

if [[ "$STATUS" == *"DISCHARGING"* ]]; then
  hyprctl eval "hl.config({ decoration = { blur = { enabled = false } } })"
else
  hyprctl eval "hl.config({ decoration = { blur = { enabled = true } } })"
fi
