-- ~/.config/hypr/lua/theme.lua
local c = require("lua.colors")

hl.config({
	general = {
		["col.active_border"] = { colors = { c.color7, c.color2 }, angle = 45 },
		["col.inactive_border"] = { colors = { c.color0 } },
		border_size = 3,
		gaps_in = 2,
		gaps_out = 2,
		layout = "dwindle",
		snap = { enabled = true },
	},
	decoration = {
		rounding = 10,
		active_opacity = 1.0,
		inactive_opacity = 1.0,
		fullscreen_opacity = 1.0,
		dim_inactive = false,
		dim_strength = 0.2,
		dim_special = 0.8,
		blur = {
			enabled = true,
			size = 6,
			passes = 2,
			ignore_opacity = true,
			new_optimizations = true,
			special = true,
			popups = true,
		},
		shadow = {
			enabled = false,
			range = 3,
			render_power = 1,
			color = c.color12,
			color_inactive = c.color10,
		},
	},
	group = {
		["col.border_active"] = { colors = { c.color7 } },
		["col.border_inactive"] = { colors = { c.color0 } },
		["col.border_locked_active"] = { colors = { c.color3 } },
		["col.border_locked_inactive"] = { colors = { c.color4 } },
		groupbar = {
			font_family = "Departure Mono",
			text_color = c.color7,
			["col.active"] = c.color7,
			["col.inactive"] = c.color0,
			["col.locked_active"] = c.color3,
			["col.locked_inactive"] = c.color4,
		},
	},
	dwindle = {
		special_scale_factor = 0.8,
		preserve_split = true,
	},
	master = {
		new_status = "master",
		special_scale_factor = 0.8,
	},
	misc = {
		font_family = "Departure Mono",
		splash_font_family = "Fira Sans",
		disable_hyprland_logo = true,
		["col.splash"] = c.color2,
		background_color = c.background,
		enable_swallow = true,
		swallow_regex = "^(nautilus|nemo|thunar|btrfs-assistant.)$",
		focus_on_activate = true,
	},
	render = {
		direct_scanout = true,
	},
})
