#!/bin/bash

capacity=$(cat /sys/class/power_supply/BAT0/capacity)
status=$(cat /sys/class/power_supply/BAT0/status)

if [[ "$status" == "Charging" ]]; then
  icon=""
elif ((capacity > 90)); then
  icon=""
elif ((capacity > 50)); then
  icon=""
elif ((capacity > 20)); then
  icon=""
else
  icon=""
fi

echo "$icon  $capacity%"
