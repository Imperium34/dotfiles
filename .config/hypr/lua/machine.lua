-- ~/.config/hypr/lua/machine.lua
local is_laptop = io.open("/sys/class/power_supply/BAT0", "r") ~= nil

if is_laptop then
	hl.config({
		general = { gaps_in = 3, gaps_out = 5, border_size = 2 },
		decoration = { rounding = 5, blur = { enabled = false } },
		misc = { vrr = 0, force_default_wallpaper = 0 },
		debug = { vfr = true },
	})
	hl.curve("fastEase", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
	hl.animation({ leaf = "windows", enabled = true, speed = 3, bezier = "fastEase" })
	hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "fastEase", style = "popin 80%" })
	hl.animation({ leaf = "border", enabled = true, speed = 2, bezier = "default" })
	hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "default" })
	hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "fastEase" })

	hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })
	hl.gesture({ fingers = 3, direction = "down", action = "close" })
	hl.gesture({ fingers = 3, direction = "up", action = "fullscreen" })
	hl.gesture({ fingers = 3, direction = "left", action = "float" })
	hl.env("LIBVA_DRIVER_NAME", "iHD")
	hl.env("__GLX_VENDOR_LIBRARY_NAME", "iHD")
else
	hl.config({
		general = { gaps_in = 5, gaps_out = 10, border_size = 3 },
		decoration = { blur = { enabled = true } },
		misc = { vrr = 1, force_default_wallpaper = 0 },
		debug = { vfr = true },
		cursor = { no_hardware_cursors = 2 },
	})
	hl.curve("myBezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
	hl.animation({ leaf = "windows", enabled = true, speed = 7, bezier = "myBezier" })
	hl.animation({ leaf = "windowsOut", enabled = true, speed = 7, bezier = "default", style = "popin 80%" })
	hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "default" })
	hl.animation({ leaf = "borderangle", enabled = true, speed = 8, bezier = "default" })
	hl.animation({ leaf = "fade", enabled = true, speed = 7, bezier = "default" })
	hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "default" })
	hl.env("LIBVA_DRIVER_NAME", "nvidia")
	hl.env("GBM_BACKEND", "nvidia-drm")
	hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
end
