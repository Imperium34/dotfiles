#!/bin/bash

CLASS="com.github.th_ch.youtube_music"

window_exists() {
  hyprctl clients | grep -q "class: $CLASS"
}

process_running() {
  pgrep -f youtube-music >/dev/null 2>&1
}

if ! window_exists && ! process_running; then
  youtube-music &

  for _ in $(seq 1 20); do
    window_exists && break
    sleep 0.5
  done
fi

hyprctl dispatch 'hl.dsp.workspace.toggle_special("music")'
