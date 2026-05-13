-- ~/.config/hypr/lua/keybinds.lua
local vars = require("lua.variables")
local mod = "SUPER"

-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃                     Core Applications                       ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
-- In v0.55, dispatchers return a table, so they are passed directly to the bind
hl.bind(mod .. " + RETURN", hl.dsp.exec_cmd(vars.apps.terminal))
hl.bind(mod .. " + E", hl.dsp.exec_cmd(vars.apps.filemanager))
hl.bind(mod .. " + B", hl.dsp.exec_cmd("xdg-open 'https://'"))
hl.bind(mod .. " + SHIFT + B", hl.dsp.exec_cmd("~/.config/hypr/scripts/toggle-work.sh"))
hl.bind(mod .. " + D", hl.dsp.exec_cmd("wofi --show drun --style ~/.config/wofi/style.css"))
hl.bind(mod .. " + W", hl.dsp.exec_cmd("waypaper"))
hl.bind(mod .. " + SHIFT + G", hl.dsp.exec_cmd("~/.config/hypr/scripts/gamemode.sh"))
hl.bind(mod .. " + N", hl.dsp.exec_cmd("nwg-displays"))
hl.bind(mod .. " + M", hl.dsp.exec_cmd("~/.config/hypr/scripts/toggle-music.sh"))
hl.bind(mod .. " + A", hl.dsp.exec_cmd("~/.config/hypr/scripts/gui_friday.sh"))

-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃                     Window Management                       ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
-- The new window object dispatchers
hl.bind(mod .. " + Q", hl.dsp.window.close())
hl.bind(mod .. " + SHIFT + F", hl.dsp.window.fullscreen())
hl.bind(mod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + Y", hl.dsp.window.pin())
hl.bind(mod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mod .. " + SHIFT + M", hl.dsp.exec_cmd('loginctl terminate-user ""'))

-- Grouping
hl.bind(mod .. " + K", hl.dsp.group.toggle())
hl.bind(mod .. " + Tab", hl.dsp.group.next())

-- Moving Focus
hl.bind(mod .. " + left", hl.dsp.focus({ direction = "l" }))
hl.bind(mod .. " + right", hl.dsp.focus({ direction = "r" }))
hl.bind(mod .. " + up", hl.dsp.focus({ direction = "u" }))
hl.bind(mod .. " + down", hl.dsp.focus({ direction = "d" }))

-- Moving Windows
hl.bind(mod .. " + CTRL + left", hl.dsp.window.move({ direction = "l" }))
hl.bind(mod .. " + CTRL + right", hl.dsp.window.move({ direction = "r" }))
hl.bind(mod .. " + CTRL + up", hl.dsp.window.move({ direction = "u" }))
hl.bind(mod .. " + CTRL + down", hl.dsp.window.move({ direction = "d" }))

-- Resizing Windows (using relative coordinates)
hl.bind(mod .. " + SHIFT + left", hl.dsp.window.resize({ x = -50, y = 0, relative = true }))
hl.bind(mod .. " + SHIFT + right", hl.dsp.window.resize({ x = 50, y = 0, relative = true }))
hl.bind(mod .. " + SHIFT + up", hl.dsp.window.resize({ x = 0, y = -50, relative = true }))
hl.bind(mod .. " + SHIFT + down", hl.dsp.window.resize({ x = 0, y = 50, relative = true }))

-- Mouse Binds (using the mouse flag)
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃                   Clipboard & Screenshots                   ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
hl.bind(mod .. " + SHIFT + code:201", hl.dsp.exec_cmd("~/.config/hypr/scripts/clipboard.sh"))
hl.bind("code:135", hl.dsp.exec_cmd("~/.config/hypr/scripts/clipboard.sh"))
hl.bind("PRINT", hl.dsp.exec_cmd('grim -g "$(slurp)" - | wl-copy'))
hl.bind("SHIFT + PRINT", hl.dsp.exec_cmd("grim - | wl-copy"))

-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃                     Media & Hardware                        ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
hl.bind(mod .. " + F2", hl.dsp.exec_cmd("hyprctl keyword monitor 'DP-3,disable'"))
hl.bind(mod .. " + F3", hl.dsp.exec_cmd("hyprctl keyword monitor 'DP-3,auto,0x0,1'"))

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --output-volume raise"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume lower"))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("swayosd-client --input-volume mute-toggle"), { locked = true })

hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("swayosd-client --brightness raise"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("swayosd-client --brightness lower"))

hl.bind(mod .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mod .. " + O", hl.dsp.exec_cmd("killall -SIGUSR2 waybar"))

-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃                 Workspaces & Submaps                        ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
for i = 1, 10 do
	local ws = tostring(i)
	local key = tostring(i % 10)
	-- Focus workspace
	hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = ws }))
	-- Move to workspace and follow
	hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = ws, follow = true }))
	-- Move to workspace silently
	hl.bind(mod .. " + CTRL + " .. key, hl.dsp.window.move({ workspace = ws, follow = false }))
end

hl.bind(mod .. " + PERIOD", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mod .. " + COMMA", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mod .. " + slash", hl.dsp.focus({ workspace = "previous" }))

hl.bind(mod .. " + minus", hl.dsp.window.move({ workspace = "special" }))
hl.bind(mod .. " + equal", hl.dsp.workspace.toggle_special("special"))
hl.bind(mod .. " + F1", hl.dsp.workspace.toggle_special("scratchpad"))
hl.bind(mod .. " + CTRL + F1", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))

-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃                     Config Overrides                        ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
hl.config({
	binds = {
		allow_workspace_cycles = true,
		workspace_back_and_forth = true,
		workspace_center_on = 1,
		movefocus_cycles_fullscreen = true,
		window_direction_monitor_fallback = true,
	},
})
