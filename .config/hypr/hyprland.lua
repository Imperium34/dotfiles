-- ~/.config/hypr/hyprland.lua
local vars = require("lua.variables")

local ok, c = pcall(require, "lua.colors") -- Wallust colors
if not ok then
	c = require("lua.colors_default") -- Fallback if wallust hasn't run yet
end

require("lua.theme") -- Aesthetics
require("lua.machine") -- Hardware (Laptop/Desktop)
require("lua.input") -- Keyboard/Mouse
require("lua.monitors") -- Display bridge
require("lua.windowrules") -- Window Rules
require("lua.keybinds") -- The Keyboard Shortcuts
require("lua.autostart") -- Startup scripts
