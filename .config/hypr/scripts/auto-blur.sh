#!/bin/bash

BATTERY="BAT0"

LAST_STATE=""

while true; do
    STATUS=$(cat /sys/class/power_supply/$BATTERY/status)

    if [ "$STATUS" != "$LAST_STATE" ]; then
        if [ "$STATUS" == "Discharging" ]; then
            hyprctl keyword decoration:blur:enabled false
            notify-send -u low "Power Saver" "Blur disabled"
        else
            # 🔌 On AC: Enable Blur & Shadows for visuals
            hyprctl keyword decoration:blur:enabled true
            notify-send -u low "Performance" "Blur enabled"
        fi
        LAST_STATE="$STATUS"
    fi

    sleep 30
done
