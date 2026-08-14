#!/bin/bash
# Finds the most vibrant colour from wallust and applies it to OpenRGB.
set -uo pipefail

WALLUST_JSON="$HOME/.config/wallust/wallust.json"

if [ ! -f "$WALLUST_JSON" ]; then
  echo "update-rgb: $WALLUST_JSON not found" >&2
  exit 1
fi

COLORS=$(jq -r '.colors.color1, .colors.color2, .colors.color3, .colors.color4, .colors.color5, .colors.color6' "$WALLUST_JSON")

BEST_COLOR=$(
  python3 - "$COLORS" <<'PY'
import sys
import re
import colorsys


def hex_to_rgb(hex_code):
    return tuple(int(hex_code[i:i + 2], 16) / 255.0 for i in (0, 2, 4))


candidates = []
for raw in sys.argv[1].splitlines():
    hex_code = raw.strip().lstrip('#')
    if not re.fullmatch(r'[0-9a-fA-F]{6}', hex_code):
        continue
    r, g, b = hex_to_rgb(hex_code)
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    candidates.append((hex_code, s, l))


def most_saturated(pool):
    best, best_s = None, -1
    for hex_code, s, l in pool:
        if s > best_s:
            best, best_s = hex_code, s
    return best


# Prefer saturated colours that aren't near-black or near-white -- those read
# as washed out or barely visible on RGB hardware even at high saturation.
mid_range = [c for c in candidates if 0.15 <= c[2] <= 0.85]
best_color = most_saturated(mid_range) if mid_range else most_saturated(candidates)

if best_color:
    print(best_color)
PY
)

if [ -z "$BEST_COLOR" ]; then
  echo "update-rgb: could not determine a colour from wallust" >&2
  exit 1
fi

echo "Most vibrant color found: #$BEST_COLOR"

if ! openrgb --mode static --color "$BEST_COLOR"; then
  echo "update-rgb: openrgb failed" >&2
  exit 1
fi

echo "OpenRGB colors updated."
