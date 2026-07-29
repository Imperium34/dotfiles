-- ~/.config/hypr/lua/autostart.lua
local vars = require("lua.variables")

hl.on("hyprland.start", function()
	-- System Environment & Authentication
	hl.exec_cmd("systemctl --user import-environment")
	hl.exec_cmd("bash -c 'hash dbus-update-activation-environment 2>/dev/null'")
	hl.exec_cmd("dbus-update-activation-environment --systemd")
	hl.exec_cmd("/usr/lib/hyprpolkitagent")

	-- Core UI Daemons
	hl.exec_cmd("quickshell -c bar")
	hl.exec_cmd("openrgb --server")

	-- Idle, Lock, and Wallpaper
	hl.exec_cmd("QS_START_LOCKED=1 quickshell -p ~/.config/quickshell/lockscreen/lock.qml")
	hl.exec_cmd(vars.apps.idlehandler)
	hl.exec_cmd("awww-daemon")
	hl.exec_cmd("~/.config/quickshell/scripts/video-wallpaper.sh resume")
	hl.exec_cmd("nice -n 19 ionice -c 3 ~/.config/quickshell/scripts/scan-wallpapers.sh > /dev/null")

	-- Clipboard Utilities
	hl.exec_cmd("wl-paste --type text --watch cliphist store")
	hl.exec_cmd("wl-paste --type image --watch cliphist store")

	-- Custom Background Scripts
	hl.exec_cmd("~/.config/hypr/scripts/auto-blur.sh")
end)
