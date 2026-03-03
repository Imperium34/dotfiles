#!/bin/bash
sleep 3
~/.config/hypr/scripts/set-blur.sh # Run once on boot

acpi_listen | while read -r event; do
  if [[ "$event" == "ac_adapter"* ]]; then
    sleep 1
    ~/.config/hypr/scripts/set-blur.sh
  fi
done
