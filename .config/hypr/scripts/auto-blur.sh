#!/bin/bash

apply_power_settings() {
  if grep -q "Discharging" /sys/class/power_supply/BAT0/status; then
    hyprctl keyword decoration:blur:enabled false
    notify-send -u low "Power Saver" "Blur disabled"
  else
    hyprctl keyword decoration:blur:enabled true
    notify-send -u low "Performance" "Visuals restored"
  fi
}

# Run once on startup
apply_power_settings

# Listen for AC adapter events
acpi_listen | while read -r event; do
  if [[ "$event" == "ac_adapter"* ]]; then
    sleep 1
    apply_power_settings
  fi
done
