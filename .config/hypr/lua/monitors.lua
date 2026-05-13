-- ~/.config/hypr/lua/monitors.lua

-- hl.monitor MUST be a table with these exact keys
hl.monitor({
	output = "", -- Fallback
	mode = "preferred",
	position = "auto",
	scale = 1,
})

hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- hl.source doesn't exist. We use the dispatcher to run the legacy source command.
hl.dispatch(hl.dsp.exec_cmd("hyprctl source ~/.config/hypr/monitors.conf"))
hl.dispatch(hl.dsp.exec_cmd("hyprctl source ~/.config/hypr/workspaces.conf"))
