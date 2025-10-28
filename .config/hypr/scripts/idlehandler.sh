#!/bin/bash

swayidle \
    timeout 300 'hyprlock' \
    timeout 600 'hyprctl dispatch dpms off' \
    resume 'hyprctl dispatch dpms on'
