#!/bin/bash

# --- This script finds the most vibrant color from wallust and applies it to OpenRGB ---

COLORS=$(jq -r '.colors.color1, .colors.color2, .colors.color3, .colors.color4, .colors.color5, .colors.color6' ~/.config/wallust/wallust.json)

BEST_COLOR=$(echo "$COLORS" | python -c "
import sys, colorsys

def hex_to_rgb(hex_code):
    hex_code = hex_code.lstrip('#')
    if len(hex_code) != 6: return (0,0,0)
    return tuple(int(hex_code[i:i+2], 16) / 255.0 for i in (0, 2, 4))

best_color = None
max_saturation = -1

for hex_code in sys.stdin:
    hex_code = hex_code.strip()
    if not hex_code: continue
    
    r, g, b = hex_to_rgb(hex_code)
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    
    if s > max_saturation:
        max_saturation = s
        best_color = hex_code

if best_color:
    print(best_color.lstrip('#'))
")

if [ -z "$BEST_COLOR" ]; then
    echo "Error: Could not determine the best color from wallust."
    exit 1
fi

echo "Most vibrant color found: #$BEST_COLOR"

openrgb --mode static --color "$BEST_COLOR"

echo "OpenRGB colors updated."
