#!/bin/bash

xdg-open "https://" &
sleep 0.8

alacritty --class "sidebar_top" -e btop &
sleep 0.5

alacritty --class "sidebar_bottom" -e yazi &
