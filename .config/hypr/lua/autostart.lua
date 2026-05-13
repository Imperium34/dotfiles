-- ~/.config/hypr/lua/autostart.lua
local vars = require("lua.variables")

hl.on("hyprland.start", function()
	-- System Environment & Authentication
	hl.exec_cmd("systemctl --user import-environment")
	hl.exec_cmd("hash dbus-update-activation-environment 2>/dev/null")
	hl.exec_cmd("dbus-update-activation-environment --systemd")
	hl.exec_cmd("/usr/lib/hyprpolkitagent")

	-- Core UI Daemons
	hl.exec_cmd("waybar")
	hl.exec_cmd("swaync")
	hl.exec_cmd("swayosd-server")
	hl.exec_cmd("openrgb --server")

	-- Idle, Lock, and Wallpaper
	hl.exec_cmd("hyprlock")
	hl.exec_cmd(vars.apps.idlehandler)
	hl.exec_cmd("waypaper --restore")

	-- Clipboard Utilities
	hl.exec_cmd("wl-paste --type text --watch cliphist store")
	hl.exec_cmd("wl-paste --type image --watch cliphist store")

	-- Custom Background Scripts
	hl.exec_cmd("~/.config/hypr/scripts/media-art.sh")
	hl.exec_cmd("~/.config/hypr/scripts/auto-blur.sh")
end)
