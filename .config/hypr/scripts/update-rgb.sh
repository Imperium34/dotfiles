#!/bin/bash

# --- This script finds the most vibrant color from wallust and applies it to OpenRGB ---

# 1. Get the list of accent colors from wallust
COLORS=$(jq -r '.colors.color1, .colors.color2, .colors.color3, .colors.color4, .colors.color5, .colors.color6' ~/.config/wallust/wallust.json)

# 2. Use Python to find the most saturated (vibrant) color
#    This passes the list of colors into the Python script.
BEST_COLOR=$(echo "$COLORS" | python -c "
import sys, colorsys

# Function to convert a hex string '#RRGGBB' to an (R, G, B) tuple
def hex_to_rgb(hex_code):
    hex_code = hex_code.lstrip('#')
    if len(hex_code) != 6: return (0,0,0)
    # Convert to 0-1.0 scale
    return tuple(int(hex_code[i:i+2], 16) / 255.0 for i in (0, 2, 4))

best_color = None
max_saturation = -1

# Read each hex code from the input
for hex_code in sys.stdin:
    hex_code = hex_code.strip()
    if not hex_code: continue
    
    r, g, b = hex_to_rgb(hex_code)
    # Convert RGB to HLS (Hue, Lightness, Saturation)
    # We are looking for the highest Saturation (s)
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    
    # Check if this color is more saturated than the previous max
    if s > max_saturation:
        max_saturation = s
        best_color = hex_code

# Print the winning color without the '#'
if best_color:
    print(best_color.lstrip('#'))
")

if [ -z "$BEST_COLOR" ]; then
    echo "Error: Could not determine the best color from wallust."
    exit 1
fi

echo "Most vibrant color found: #$BEST_COLOR"

# 4. Apply the color to your OpenRGB devices
# (Make sure 'openrgb --server' is running first!)
openrgb --mode static --color "$BEST_COLOR"

# Add your RAM (device 0 and 1) if you want
# openrgb --device 0 --mode static --color "$BEST_COLOR"
# openrgb --device 1 --mode static --color "$BEST_COLOR"

echo "OpenRGB colors updated."
