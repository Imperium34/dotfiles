#!/bin/bash
BAT_PATH=$(find /sys/class/power_supply -name "BAT*" | head -n 1)
STATUS=$(tr '[:lower:]' '[:upper:]' <"$BAT_PATH/status")

if [[ "$STATUS" == *"DISCHARGING"* ]]; then
  hyprctl keyword decoration:blur:enabled false
else
  hyprctl keyword decoration:blur:enabled true
fi
