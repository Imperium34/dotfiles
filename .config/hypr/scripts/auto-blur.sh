#!/bin/bash

# Automatically find the battery (BAT0, BAT1, or BATT)
BAT_PATH=$(find /sys/class/power_supply -name "BAT*" | head -n 1)

apply_power_settings() {
  # Read status, force to uppercase to handle differences
  STATUS=$(cat "$BAT_PATH/status" | tr '[:lower:]' '[:upper:]')

  if [[ "$STATUS" == *"DISCHARGING"* ]]; then
    hyprctl keyword decoration:blur:enabled false
    notify-send -u low -a "Power Manager" "Power Saver" "Blur disabled"
  else
    hyprctl keyword decoration:blur:enabled true
    notify-send -u low -a "Power Manager" "Performance" "Visuals restored"
  fi
}

# Run once on startup
apply_power_settings

# Listen for AC adapter events
acpi_listen | while read -r event; do
  # Check if the event starts with "ac_adapter"
  if [[ "$event" == "ac_adapter"* ]]; then
    sleep 1 # Wait for kernel to update status
    apply_power_settings
  fi
done
