-- // src/Systems/ConfigSystem.lua
return function(Context)
	local HttpService = game:GetService("HttpService")

	local FeatureConfig = Context.FeatureConfig or {}
	local CONFIG = Context.CONFIG or { FOLDER = "B0XazUniversal", EXT = ".json" }
	local Utils = Context.Utils or {}
	local UIRegistry = Context.UIRegistry or {}
	local Theme = Context.Theme or {}
	local ThemeManager = Context.ThemeManager
	local State = Context.State or {}
	local Connections = Context.Connections

	local ConfigSystem = {
		Dirty = false,
		AutoloadFile = "_autoload",
		DefaultSnapshot = nil,
	}

	local function copyTable(src)
		if type(src) ~= "table" then return src end
		local out = {}
		for k, v in pairs(src) do
			out[k] = type(v) == "table" and copyTable(v) or v
		end
		return out
	end

	local function getPath(name)
		return string.format("%s/%s%s", CONFIG.FOLDER or "B0XazUniversal", name, CONFIG.EXT or ".json")
	end

	local function colorToTable(c)
		if typeof(c) == "Color3" then
			if Utils.ColorToTable then return Utils.ColorToTable(c) end
			return { r = c.R, g = c.G, b = c.B }
		end
		return c
	end

	local function tableToColor(t)
		if type(t) == "table" then
			if Utils.TableToColor then return Utils.TableToColor(t) end
			if t.r and t.g and t.b then return Color3.new(t.r, t.g, t.b) end
		end
		return t
	end

	----------------------------------------------------------------
	-- FIXED keybind serialize/deserialize
	-- Enum objects (Enum.KeyCode / Enum.UserInputType) do NOT have .Name
	-- Only EnumItem objects do. Use typeof checks + tostring fallback.
	----------------------------------------------------------------
	local function serializeKeybind(bind)
		if bind == nil then return nil end
		local t = typeof(bind)

		if t == "string" then
			return { kind = "string", value = bind }
		end

		if t == "EnumItem" then
			-- bind.EnumType is an Enum (no .Name). Compare by identity.
			if bind.EnumType == Enum.KeyCode then
				return { kind = "KeyCode", value = bind.Name }
			elseif bind.EnumType == Enum.UserInputType then
				return { kind = "UserInputType", value = bind.Name }
			end
			-- Generic EnumItem fallback
			return { kind = "EnumItem", value = bind.Name }
		end

		return nil
	end

	local function deserializeKeybind(data)
		if type(data) ~= "table" then return data end

		if data.kind == "string" then
			return data.value
		end

		if data.kind == "KeyCode" and type(data.value) == "string" then
			local ok, result = pcall(function() return Enum.KeyCode[data.value] end)
			if ok and typeof(result) == "EnumItem" then return result end
		end

		if data.kind == "UserInputType" and type(data.value) == "string" then
			local ok, result = pcall(function() return Enum.UserInputType[data.value] end)
			if ok and typeof(result) == "EnumItem" then return result end
		end

		return nil
	end

	function ConfigSystem.NotifyChange()
		ConfigSystem.Dirty = true
	end

	function ConfigSystem.Serialize()
		local themeData = {}
		for k, v in pairs(Theme) do
			if typeof(v) == "Color3" then
				themeData[k] = colorToTable(v)
			end
		end

		local aim = FeatureConfig.Aimbot or {}
		local mov = FeatureConfig.Movement or {}
		local esp = FeatureConfig.ESP or {}
		local chams = FeatureConfig.Chams or {}
		local cam = FeatureConfig.Camera or {}
		local vis = FeatureConfig.Visuals or {}
		local extras = FeatureConfig.Extras or {}
		local perf = FeatureConfig.Performance or {}
		local gameMod = FeatureConfig.Game or {}
		local hitbox = extras.Hitbox or {}
		local spin = extras.SpinBot or {}
		local cross = extras.Crosshair or {}

		return {
			Aimbot = {
				Enabled = aim.Enabled,
				Keybind = serializeKeybind(aim.Keybind),
				Hitpart = aim.Hitpart,
				Smoothness = aim.Smoothness,
				LockMode = aim.LockMode,
				Prediction = copyTable(aim.Prediction or {}),
				TeamCheck = aim.TeamCheck,
				VisCheck = aim.VisCheck,
				MaxDistance = aim.MaxDistance,
				ShakeIntensity = aim.ShakeIntensity,
				UnlockOnDeath = aim.UnlockOnDeath,
				BreakOnPull = aim.BreakOnPull,
				MaxLockRadius = aim.MaxLockRadius,
				Triggerbot = copyTable(aim.Triggerbot or {}),
				FOV = copyTable(aim.FOV or {}),
			},
			Movement = copyTable(mov),
			ESP = {
				Enabled = esp.Enabled, Box = esp.Box, Name = esp.Name,
				Health = esp.Health, Distance = esp.Distance, Tracers = esp.Tracers,
				Skeleton = esp.Skeleton, HeadDot = esp.HeadDot, LookDir = esp.LookDir,
				TeamCheck = esp.TeamCheck, MaxDist = esp.MaxDist,
				Color = colorToTable(esp.Color),
			},
			Chams = {
				Enabled = chams.Enabled,
				FillColor = colorToTable(chams.FillColor),
				OutlineColor = colorToTable(chams.OutlineColor),
			},
			Camera = { FOV = cam.FOV },
			Visuals = { Fullbright = vis.Fullbright },
			Extras = {
				Hitbox = { Enabled = hitbox.Enabled == true, Size = tonumber(hitbox.Size) or 10 },
				SpinBot = { Enabled = spin.Enabled == true, Speed = tonumber(spin.Speed) or 20 },
				Crosshair = {
					Visible = cross.Visible == true,
					Size = tonumber(cross.Size) or 12,
					Gap = tonumber(cross.Gap) or 4,
					Thickness = tonumber(cross.Thickness) or 2,
					Color = colorToTable(cross.Color or Color3.new(1, 1, 1)),
				},
				SpeedLines = extras.SpeedLines == true,
				Wallbang = extras.Wallbang == true,
			},
			Performance = copyTable(perf),
			Game = {
				DoorPhase = gameMod.DoorPhase,
				DoorGlow = gameMod.DoorGlow,
				GlowColor = colorToTable(gameMod.GlowColor),
				PhaseTransparency = gameMod.PhaseTransparency,
				NoSpread = gameMod.NoSpread,
				FastFire = gameMod.FastFire,
				ForceAuto = gameMod.ForceAuto,
				ForceRange = gameMod.ForceRange,
			},
			Theme = {
				PresetName = (ThemeManager and ThemeManager.ActivePreset) or "Default Cyan",
				Colors = themeData,
			},
			Settings = {
				MenuKeybind = serializeKeybind(State.MenuKeybind),
				IncludeSelf = State.includeSelf or false,
			},
		}
	end

	function ConfigSystem.Deserialize(data)
		if type(data) ~= "table" then return end

		if type(data.Aimbot) == "table" and FeatureConfig.Aimbot then
			for k, v in pairs(data.Aimbot) do
				if k == "Keybind" then
					FeatureConfig.Aimbot.Keybind = deserializeKeybind(v) or FeatureConfig.Aimbot.Keybind
				elseif (k == "Prediction" or k == "FOV" or k == "Triggerbot") and type(v) == "table" then
					FeatureConfig.Aimbot[k] = FeatureConfig.Aimbot[k] or {}
					for sk, sv in pairs(v) do FeatureConfig.Aimbot[k][sk] = sv end
				else
					FeatureConfig.Aimbot[k] = v
				end
			end
		end

		if type(data.Movement) == "table" and FeatureConfig.Movement then
			for k, v in pairs(data.Movement) do FeatureConfig.Movement[k] = v end
		end

		if type(data.ESP) == "table" and FeatureConfig.ESP then
			for k, v in pairs(data.ESP) do
				FeatureConfig.ESP[k] = (k == "Color") and tableToColor(v) or v
			end
		end

		if type(data.Chams) == "table" and FeatureConfig.Chams then
			for k, v in pairs(data.Chams) do
				if k == "FillColor" or k == "OutlineColor" then
					FeatureConfig.Chams[k] = tableToColor(v)
				else
					FeatureConfig.Chams[k] = v
				end
			end
		end

		if type(data.Camera) == "table" and FeatureConfig.Camera and type(data.Camera.FOV) == "number" then
			FeatureConfig.Camera.FOV = data.Camera.FOV
		end

		if type(data.Visuals) == "table" and FeatureConfig.Visuals and data.Visuals.Fullbright ~= nil then
			FeatureConfig.Visuals.Fullbright = data.Visuals.Fullbright
		end

		if type(data.Extras) == "table" and FeatureConfig.Extras then
			if type(data.Extras.Hitbox) == "table" and FeatureConfig.Extras.Hitbox then
				for k, v in pairs(data.Extras.Hitbox) do FeatureConfig.Extras.Hitbox[k] = v end
			end
			if type(data.Extras.SpinBot) == "table" and FeatureConfig.Extras.SpinBot then
				for k, v in pairs(data.Extras.SpinBot) do FeatureConfig.Extras.SpinBot[k] = v end
			end
			if type(data.Extras.Crosshair) == "table" and FeatureConfig.Extras.Crosshair then
				for k, v in pairs(data.Extras.Crosshair) do
					FeatureConfig.Extras.Crosshair[k] = (k == "Color") and tableToColor(v) or v
				end
			end
			if data.Extras.SpeedLines ~= nil then FeatureConfig.Extras.SpeedLines = data.Extras.SpeedLines end
			if data.Extras.Wallbang ~= nil then FeatureConfig.Extras.Wallbang = data.Extras.Wallbang end
		end

		if type(data.Performance) == "table" and FeatureConfig.Performance then
			for k, v in pairs(data.Performance) do FeatureConfig.Performance[k] = v end
		end

		if type(data.Game) == "table" and FeatureConfig.Game then
			for k, v in pairs(data.Game) do
				FeatureConfig.Game[k] = (k == "GlowColor") and tableToColor(v) or v
			end
		end

		if type(data.Theme) == "table" then
			if ThemeManager and data.Theme.PresetName then
				ThemeManager.ActivePreset = data.Theme.PresetName
			end
			if type(data.Theme.Colors) == "table" and Context.UI and Context.UI.SetTheme then
				local colors = {}
				for k, v in pairs(data.Theme.Colors) do colors[k] = tableToColor(v) end
				Context.UI:SetTheme(colors)
			end
		end

		if type(data.Settings) == "table" then
			State.MenuKeybind = deserializeKeybind(data.Settings.MenuKeybind) or State.MenuKeybind
			State.includeSelf = data.Settings.IncludeSelf or false
		end

		if FeatureConfig.Aimbot and not FeatureConfig.Aimbot.Enabled and Context.AimbotSystem then
			pcall(function() Context.AimbotSystem.LockOff() end)
		end
		if FeatureConfig.Movement and not FeatureConfig.Movement.FlyEnabled and Context.FlySystem then
			pcall(function() Context.FlySystem.Stop() end)
		end
		if FeatureConfig.Extras and FeatureConfig.Extras.Hitbox and not FeatureConfig.Extras.Hitbox.Enabled and Context.ResetHitboxes then
			pcall(Context.ResetHitboxes)
		end
	end

	function ConfigSystem.UpdateUI()
		local function set(key, value)
			local entry = UIRegistry[key]
			if entry and type(entry.Set) == "function" then
				entry.Set(value, true)
			end
		end

		local aim = FeatureConfig.Aimbot or {}
		local fov = aim.FOV or {}
		local pred = aim.Prediction or {}
		local trig = aim.Triggerbot or {}

		set("Aimbot_Enabled", aim.Enabled)
		set("Aimbot_Keybind", aim.Keybind)
		set("Aimbot_LockMode", aim.LockMode)
		set("Aimbot_Hitpart", aim.Hitpart)
		set("Aimbot_Smoothness", aim.Smoothness)
		set("Aimbot_ShakeIntensity", aim.ShakeIntensity)
		set("Aimbot_TeamCheck", aim.TeamCheck)
		set("Aimbot_VisCheck", aim.VisCheck)
		set("Aimbot_UnlockOnDeath", aim.UnlockOnDeath)
		set("Aimbot_BreakOnPull", aim.BreakOnPull)
		set("Aimbot_MaxLockRadius", aim.MaxLockRadius)
		set("Aimbot_MaxDistance", aim.MaxDistance)
		set("Aimbot_FOV_Show", fov.Show)
		set("Aimbot_FOV_Filled", fov.Filled)
		set("Aimbot_FOV_Rainbow", fov.Rainbow)
		set("Aimbot_FOV_Size", fov.Size)
		set("Aimbot_FOV_Thickness", fov.Thickness)
		set("Aimbot_Prediction_Horizontal", math.floor((pred.Horizontal or 0) * 200))
		set("Aimbot_Prediction_Vertical", math.floor((pred.Vertical or 0) * 200))
		set("Aimbot_Triggerbot_Enabled", trig.Enabled)
		set("Aimbot_Triggerbot_Delay", math.floor((trig.Delay or 0) * 100))

		local esp = FeatureConfig.ESP or {}
		local chams = FeatureConfig.Chams or {}
		set("ESP_Enabled", esp.Enabled)
		set("ESP_Box", esp.Box)
		set("ESP_Name", esp.Name)
		set("ESP_Health", esp.Health)
		set("ESP_Distance", esp.Distance)
		set("ESP_Tracers", esp.Tracers)
		set("ESP_Skeleton", esp.Skeleton)
		set("ESP_HeadDot", esp.HeadDot)
		set("ESP_LookDir", esp.LookDir)
		set("ESP_TeamCheck", esp.TeamCheck)
		set("ESP_MaxDist", esp.MaxDist)
		set("ESP_Color", esp.Color)
		set("ESP_Chams_Enabled", chams.Enabled)
		set("ESP_Chams_FillColor", chams.FillColor)
		set("ESP_Chams_OutlineColor", chams.OutlineColor)

		local mov = FeatureConfig.Movement or {}
		set("Movement_Speed", mov.Speed)
		set("Movement_JumpPower", mov.JumpPower)
		set("Movement_SprintEnabled", mov.SprintEnabled)
		set("Movement_SprintSpeed", mov.SprintSpeed)
		set("Movement_InfJump", mov.InfJump)
		set("Movement_FlySpeed", mov.FlySpeed)
		set("Movement_FlyEnabled", mov.FlyEnabled)
		set("Movement_CFrameSpeed", mov.CFrameSpeed)
		set("Movement_CFrameSpeedValue", mov.CFrameSpeedValue or 50)
		set("Movement_Bhop", mov.Bhop)

		local cam = FeatureConfig.Camera or {}
		set("Camera_FOV", cam.FOV)

		local ext = FeatureConfig.Extras or {}
		local hb = ext.Hitbox or {}
		local sp = ext.SpinBot or {}
		local cr = ext.Crosshair or {}
		set("Extras_Hitbox_Enabled", hb.Enabled)
		set("Extras_Hitbox_Size", hb.Size)
		set("Extras_SpinBot_Enabled", sp.Enabled)
		set("Extras_SpinBot_Speed", sp.Speed)
		set("Extras_Crosshair_Visible", cr.Visible)
		set("Extras_Crosshair_Size", cr.Size)
		set("Extras_Crosshair_Gap", cr.Gap)
		set("Extras_Crosshair_Thickness", cr.Thickness)
		set("Extras_Crosshair_Color", cr.Color)
		set("Extras_SpeedLines", ext.SpeedLines)
		set("Extras_Wallbang", ext.Wallbang)

		local vis = FeatureConfig.Visuals or {}
		set("Visuals_Fullbright", vis.Fullbright)

		local perf = FeatureConfig.Performance or {}
		set("Perf_NoTextures", perf.NoTextures)
		set("Perf_LowMaterials", perf.LowMaterials)
		set("Perf_OptimizeTerrain", perf.OptimizeTerrain)
		set("Perf_NoPostProcessing", perf.NoPostProcessing)
		set("Perf_NoShadows", perf.NoShadows)
		set("Perf_NoParticles", perf.NoParticles)

		local gm = FeatureConfig.Game or {}
		set("Game_DoorPhase", gm.DoorPhase)
		set("Game_DoorGlow", gm.DoorGlow)
		set("Game_PhaseTransparency", math.floor((gm.PhaseTransparency or 0.65) * 100))
		set("Game_GlowColor", gm.GlowColor)
		set("Game_NoSpread", gm.NoSpread)
		set("Game_FastFire", gm.FastFire)
		set("Game_ForceAuto", gm.ForceAuto)
		set("Game_ForceRange", gm.ForceRange)

		set("Theme_Accent", Theme.Accent)
		set("Theme_Bg", Theme.Bg)
		set("Theme_Panel", Theme.Panel)
		set("Theme_Elem", Theme.Elem)
		set("Theme_Side", Theme.Side)
		set("Theme_Text", Theme.Text)
		set("Theme_Border", Theme.Border)
		set("Theme_ToggleOn", Theme.ToggleOn)
		set("Players_IncludeSelf", State.includeSelf)
	end

	function ConfigSystem.GetSavedNames()
		local names = {}
		local folder = CONFIG.FOLDER or "B0XazUniversal"
		local files = (Utils.ListFiles and Utils.ListFiles(folder)) or {}
		local ext = CONFIG.EXT or ".json"
		local extLen = #ext

		for _, path in ipairs(files) do
			local fileName = path:match("[/\\]?([^/\\]+)$") or path
			if fileName:sub(-extLen) == ext then
				local base = fileName:sub(1, -extLen - 1)
				if base ~= ConfigSystem.AutoloadFile and base:lower() ~= "default" then
					table.insert(names, base)
				end
			end
		end
		table.sort(names)

		local result = { "Default" }
		for _, n in ipairs(names) do table.insert(result, n) end
		return result
	end

	function ConfigSystem.Save(name)
		if not name or #name == 0 then return false, "Empty name" end
		if name:lower() == "default" then return false, "Cannot overwrite Default" end

		local ok, encoded = pcall(function()
			return HttpService:JSONEncode(ConfigSystem.Serialize())
		end)
		if not ok then return false, tostring(encoded) end
		if not Utils.WriteFile then return false, "WriteFile unavailable" end
		return Utils.WriteFile(getPath(name), encoded)
	end

	function ConfigSystem.Load(name)
		if name == "Default" then
			if ConfigSystem.DefaultSnapshot then
				ConfigSystem.Deserialize(ConfigSystem.DefaultSnapshot)
				ConfigSystem.UpdateUI()
				return true
			end
			return false, "Default snapshot unavailable"
		end

		if not Utils.ReadFile then return false, "ReadFile unavailable" end
		local content = Utils.ReadFile(getPath(name))
		if not content then return false, "Not found" end

		local ok, decoded = pcall(function() return HttpService:JSONDecode(content) end)
		if not ok then return false, tostring(decoded) end

		ConfigSystem.Deserialize(decoded)
		ConfigSystem.UpdateUI()
		return true
	end

	function ConfigSystem.Delete(name)
		if not name or name:lower() == "default" then return false, "Cannot delete Default" end
		if name:lower() == ConfigSystem.AutoloadFile:lower() then return false, "Cannot delete autoload" end
		return pcall(function()
			if delfile then delfile(getPath(name)) end
		end)
	end

	function ConfigSystem.LoadAutoload()
		if not Utils.ReadFile then return false end
		local content = Utils.ReadFile(getPath(ConfigSystem.AutoloadFile))
		if not content then return false end
		local ok, decoded = pcall(function() return HttpService:JSONDecode(content) end)
		if ok and type(decoded) == "table" then
			ConfigSystem.Deserialize(decoded)
			return true
		end
		return false
	end

	function ConfigSystem.StartAutosaveLoop()
		local saving = false
		local thread = task.spawn(function()
			while true do
				task.wait(1.5)
				if ConfigSystem.Dirty and not saving then
					ConfigSystem.Dirty = false
					saving = true
					pcall(function()
						local ok, encoded = pcall(function()
							return HttpService:JSONEncode(ConfigSystem.Serialize())
						end)
						if ok and Utils.WriteFile then
							Utils.WriteFile(getPath(ConfigSystem.AutoloadFile), encoded)
						end
					end)
					saving = false
				end
			end
		end)
		if Connections and Connections.Track then
			Connections.Track(thread)
		end
	end

	-- Safe snapshot — serializeKeybind no longer crashes on Enum.UserInputType
	local snapOk, snap = pcall(ConfigSystem.Serialize)
	ConfigSystem.DefaultSnapshot = snapOk and snap or {}

	return ConfigSystem
end
