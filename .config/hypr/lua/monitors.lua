-- ~/.config/hypr/lua/monitors.lua

local home = os.getenv("HOME")

local m_file = io.open(home .. "/.config/hypr/monitors.conf", "r")
if m_file then
	for line in m_file:lines() do
		if line:match("^monitor=") then
			local data = line:gsub("^monitor=", "")
			local parts = {}
			for p in string.gmatch(data, "[^,]+") do
				table.insert(parts, p)
			end

			if #parts >= 4 then
				local rule = {
					output = parts[1],
					mode = parts[2],
					position = parts[3],
					scale = tonumber(parts[4]) or parts[4],
				}

				for i = 5, #parts, 2 do
					if parts[i] and parts[i + 1] then
						rule[parts[i]] = tonumber(parts[i + 1]) or parts[i + 1]
					end
				end
				hl.monitor(rule)
			end
		end
	end
	m_file:close()
end

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

local dp3_disabled = io.open(home .. "/.cache/hypr/dp3-disabled", "r")
if dp3_disabled then
	dp3_disabled:close()
	hl.monitor({ output = "DP-3", disable = true })
end

local w_file = io.open(home .. "/.config/hypr/workspaces.conf", "r")
if w_file then
	for line in w_file:lines() do
		if line:match("^workspace=") then
			local data = line:gsub("^workspace=", "")
			local parts = {}
			for p in string.gmatch(data, "[^,]+") do
				table.insert(parts, p)
			end

			if #parts >= 1 then
				local rule = { workspace = parts[1] }

				for i = 2, #parts do
					local k, v = parts[i]:match("([^:]+):(.*)")
					if k and v then
						if v == "true" then
							v = true
						elseif v == "false" then
							v = false
						elseif tonumber(v) then
							v = tonumber(v)
						end
						rule[k] = v
					end
				end
				hl.workspace_rule(rule)
			end
		end
	end
	w_file:close()
end

hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
