#!/bin/bash

# --- This script finds the most vibrant color from wallust and applies it to OpenRGB ---

set -uo pipefail

COLORS=$(jq -r '.colors.color1, .colors.color2, .colors.color3, .colors.color4, .colors.color5, .colors.color6' ~/.config/wallust/wallust.json)

BEST_COLOR=$(
  echo "$COLORS" | python3 - <<'PY'
import sys, colorsys

def hex_to_rgb(hex_code):
    hex_code = hex_code.lstrip('#')
    if len(hex_code) != 6: return (0,0,0)
    return tuple(int(hex_code[i:i+2], 16) / 255.0 for i in (0, 2, 4))

candidates = []
for hex_code in sys.stdin:
    hex_code = hex_code.strip()
    if not hex_code: continue
    r, g, b = hex_to_rgb(hex_code)
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    candidates.append((hex_code, s, l))

def most_saturated(pool):
    best, best_s = None, -1
    for hex_code, s, l in pool:
        if s > best_s:
            best, best_s = hex_code, s
    return best

# Prefer saturated colors that aren't near-black or near-white — those read
# as washed out or barely visible on RGB hardware even at high saturation.
mid_range = [c for c in candidates if 0.15 <= c[2] <= 0.85]
best_color = most_saturated(mid_range) if mid_range else most_saturated(candidates)

if best_color:
    print(best_color.lstrip('#'))
PY
)

if [ -z "$BEST_COLOR" ]; then
  echo "Error: Could not determine the best color from wallust."
  exit 1
fi

echo "Most vibrant color found: #$BEST_COLOR"

openrgb --mode static --color "$BEST_COLOR"

echo "OpenRGB colors updated."
