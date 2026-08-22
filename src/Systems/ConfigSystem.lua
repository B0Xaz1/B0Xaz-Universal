-- src/Systems/ConfigSystem.lua
return function(Context)
	local HttpService = game:GetService("HttpService")
	local FeatureConfig = Context.FeatureConfig
	local CONFIG = Context.CONFIG
	local Utils = Context.Utils
	local UIRegistry = Context.UIRegistry
	local Theme = Context.Theme
	local ThemeManager = Context.ThemeManager
	local State = Context.State
	local Connections = Context.Connections

	local ConfigSystem = {
		Dirty = false,
		AutoloadFile = "_autoload",
		DefaultSnapshot = nil,
	}

	local function serializeKeybind(k)
		if k == nil then
			return nil
		end
		if typeof(k) == "string" then
			return { kind = "string", value = k }
		elseif typeof(k) == "EnumItem" then
			if k.EnumType == Enum.KeyCode then
				return { kind = "KeyCode", value = k.Name }
			elseif k.EnumType == Enum.UserInputType then
				return { kind = "UserInputType", value = k.Name }
			end
		end
		return nil
	end

	local function deserializeKeybind(data)
		if type(data) ~= "table" then
			return data
		end
		if data.kind == "string" then
			return data.value
		end
		if data.kind == "KeyCode" then
			local ok, kc = pcall(function()
				return Enum.KeyCode[data.value]
			end)
			return ok and kc or nil
		end
		if data.kind == "UserInputType" then
			local ok, uit = pcall(function()
				return Enum.UserInputType[data.value]
			end)
			return ok and uit or nil
		end
		return nil
	end

	local function getStretchRes()
		local sr = FeatureConfig.Extras and FeatureConfig.Extras.StretchRes
		if type(sr) ~= "table" then
			return {
				Enabled = false,
				X = 1.333,
				Y = 1.0,
			}
		end
		return {
			Enabled = sr.Enabled == true,
			X = tonumber(sr.X) or 1.333,
			Y = tonumber(sr.Y) or 1.0,
		}
	end

	function ConfigSystem.NotifyChange()
		ConfigSystem.Dirty = true
	end

	function ConfigSystem.Serialize()
		local themeData = {}
		for k, v in pairs(Theme) do
			if typeof(v) == "Color3" then
				themeData[k] = Utils.ColorToTable(v)
			end
		end

		local extras = FeatureConfig.Extras or {}
		local hitbox = extras.Hitbox or { Enabled = false, Size = 10 }
		local spinBot = extras.SpinBot or { Enabled = false, Speed = 20 }
		local crosshair = extras.Crosshair or {
			Visible = false,
			Size = 12,
			Gap = 4,
			Thickness = 2,
			Color = Color3.fromRGB(255, 255, 255),
		}

		return {
			Aimbot = {
				Enabled = FeatureConfig.Aimbot.Enabled,
				Keybind = serializeKeybind(FeatureConfig.Aimbot.Keybind),
				Hitpart = FeatureConfig.Aimbot.Hitpart,
				AirHitpart = FeatureConfig.Aimbot.AirHitpart,
				Smoothness = FeatureConfig.Aimbot.Smoothness,
				LockMode = FeatureConfig.Aimbot.LockMode,
				Prediction = table.clone(FeatureConfig.Aimbot.Prediction),
				TeamCheck = FeatureConfig.Aimbot.TeamCheck,
				VisCheck = FeatureConfig.Aimbot.VisCheck,
				MaxDistance = FeatureConfig.Aimbot.MaxDistance,
				ShakeIntensity = FeatureConfig.Aimbot.ShakeIntensity,
				LockNPC = FeatureConfig.Aimbot.LockNPC,
				UnlockOnDeath = FeatureConfig.Aimbot.UnlockOnDeath,
				BreakOnPull = FeatureConfig.Aimbot.BreakOnPull,
				MaxLockRadius = FeatureConfig.Aimbot.MaxLockRadius,
				Triggerbot = table.clone(FeatureConfig.Aimbot.Triggerbot),
				FOV = table.clone(FeatureConfig.Aimbot.FOV),
			},
			Movement = table.clone(FeatureConfig.Movement),
			ESP = {
				Enabled = FeatureConfig.ESP.Enabled,
				Box = FeatureConfig.ESP.Box,
				Name = FeatureConfig.ESP.Name,
				Health = FeatureConfig.ESP.Health,
				Distance = FeatureConfig.ESP.Distance,
				Tracers = FeatureConfig.ESP.Tracers,
				Skeleton = FeatureConfig.ESP.Skeleton,
				HeadDot = FeatureConfig.ESP.HeadDot,
				LookDir = FeatureConfig.ESP.LookDir,
				TeamCheck = FeatureConfig.ESP.TeamCheck,
				MaxDist = FeatureConfig.ESP.MaxDist,
				Color = Utils.ColorToTable(FeatureConfig.ESP.Color),
			},
			Chams = {
				Enabled = FeatureConfig.Chams.Enabled,
				FillColor = Utils.ColorToTable(FeatureConfig.Chams.FillColor),
				OutlineColor = Utils.ColorToTable(FeatureConfig.Chams.OutlineColor),
			},
			Camera = {
				FOV = FeatureConfig.Camera.FOV,
			},
			Visuals = {
				Fullbright = FeatureConfig.Visuals.Fullbright,
			},
			Extras = {
				Hitbox = {
					Enabled = hitbox.Enabled == true,
					Size = tonumber(hitbox.Size) or 10,
				},
				SpinBot = {
					Enabled = spinBot.Enabled == true,
					Speed = tonumber(spinBot.Speed) or 20,
				},
				Crosshair = {
					Visible = crosshair.Visible == true,
					Size = tonumber(crosshair.Size) or 12,
					Gap = tonumber(crosshair.Gap) or 4,
					Thickness = tonumber(crosshair.Thickness) or 2,
					Color = Utils.ColorToTable(crosshair.Color or Color3.fromRGB(255, 255, 255)),
				},
				SpeedLines = extras.SpeedLines == true,
				Wallbang = extras.Wallbang == true,
				StretchRes = getStretchRes(),
			},
			Performance = table.clone(FeatureConfig.Performance),
			Game = {
				DoorPhase = FeatureConfig.Game.DoorPhase,
				DoorGlow = FeatureConfig.Game.DoorGlow,
				GlowColor = Utils.ColorToTable(FeatureConfig.Game.GlowColor),
				PhaseTransparency = FeatureConfig.Game.PhaseTransparency,
				NoSpread = FeatureConfig.Game.NoSpread,
				FastFire = FeatureConfig.Game.FastFire,
				ForceAuto = FeatureConfig.Game.ForceAuto,
				ForceRange = FeatureConfig.Game.ForceRange,
				FireRateValue = FeatureConfig.Game.FireRateValue,
				RangeValue = FeatureConfig.Game.RangeValue,
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
		if type(data) ~= "table" then
			return
		end

		if type(data.Aimbot) == "table" then
			for k, v in pairs(data.Aimbot) do
				if k == "Keybind" then
					FeatureConfig.Aimbot.Keybind = deserializeKeybind(v) or FeatureConfig.Aimbot.Keybind
				elseif (k == "Prediction" or k == "FOV" or k == "Triggerbot") and type(v) == "table" then
					for k2, v2 in pairs(v) do
						FeatureConfig.Aimbot[k][k2] = v2
					end
				else
					FeatureConfig.Aimbot[k] = v
				end
			end
		end

		if type(data.Movement) == "table" then
			for k, v in pairs(data.Movement) do
				FeatureConfig.Movement[k] = v
			end
		end

		if type(data.ESP) == "table" then
			for k, v in pairs(data.ESP) do
				if k == "Color" then
					FeatureConfig.ESP.Color = Utils.TableToColor(v)
				else
					FeatureConfig.ESP[k] = v
				end
			end
		end

		if type(data.Chams) == "table" then
			for k, v in pairs(data.Chams) do
				if k == "FillColor" or k == "OutlineColor" then
					FeatureConfig.Chams[k] = Utils.TableToColor(v)
				else
					FeatureConfig.Chams[k] = v
				end
			end
		end

		if type(data.Camera) == "table" and type(data.Camera.FOV) == "number" then
			FeatureConfig.Camera.FOV = data.Camera.FOV
		end

		if type(data.Visuals) == "table" and data.Visuals.Fullbright ~= nil then
			FeatureConfig.Visuals.Fullbright = data.Visuals.Fullbright
		end

		if type(data.Extras) == "table" then
			if type(data.Extras.Hitbox) == "table" then
				for k, v in pairs(data.Extras.Hitbox) do
					FeatureConfig.Extras.Hitbox[k] = v
				end
			end

			if type(data.Extras.SpinBot) == "table" then
				for k, v in pairs(data.Extras.SpinBot) do
					FeatureConfig.Extras.SpinBot[k] = v
				end
			end

			if type(data.Extras.Crosshair) == "table" then
				for k, v in pairs(data.Extras.Crosshair) do
					if k == "Color" then
						FeatureConfig.Extras.Crosshair.Color = Utils.TableToColor(v)
					else
						FeatureConfig.Extras.Crosshair[k] = v
					end
				end
			end

			if data.Extras.SpeedLines ~= nil then
				FeatureConfig.Extras.SpeedLines = data.Extras.SpeedLines
			end

			if data.Extras.Wallbang ~= nil then
				FeatureConfig.Extras.Wallbang = data.Extras.Wallbang
			end

			if type(data.Extras.StretchRes) == "table" then
				if type(FeatureConfig.Extras.StretchRes) ~= "table" then
					FeatureConfig.Extras.StretchRes = {
						Enabled = false,
						X = 1.333,
						Y = 1.0,
					}
				end
				for k, v in pairs(data.Extras.StretchRes) do
					FeatureConfig.Extras.StretchRes[k] = v
				end
			end
		end

		if type(data.Performance) == "table" then
			for k, v in pairs(data.Performance) do
				FeatureConfig.Performance[k] = v
			end
		end

		if type(data.Game) == "table" then
			for k, v in pairs(data.Game) do
				if k == "GlowColor" then
					FeatureConfig.Game.GlowColor = Utils.TableToColor(v)
				else
					FeatureConfig.Game[k] = v
				end
			end
		end

		if type(data.Theme) == "table" then
			if ThemeManager and data.Theme.PresetName then
				ThemeManager.ActivePreset = data.Theme.PresetName
			end
			if type(data.Theme.Colors) == "table" and Context.UI then
				local tColors = {}
				for k, v in pairs(data.Theme.Colors) do
					tColors[k] = Utils.TableToColor(v)
				end
				Context.UI:SetTheme(tColors)
			end
		end

		if type(data.Settings) == "table" then
			State.MenuKeybind = deserializeKeybind(data.Settings.MenuKeybind) or State.MenuKeybind
			State.includeSelf = data.Settings.IncludeSelf or false
		end

		if not FeatureConfig.Aimbot.Enabled and Context.AimbotSystem then
			Context.AimbotSystem.LockOff()
		end
		if not FeatureConfig.Movement.FlyEnabled and Context.FlySystem then
			Context.FlySystem.Stop()
		end
		if FeatureConfig.Extras.Hitbox and not FeatureConfig.Extras.Hitbox.Enabled and Context.ResetHitboxes then
			Context.ResetHitboxes()
		end
	end

	function ConfigSystem.UpdateUI()
		local function set(key, value)
			if UIRegistry[key] and UIRegistry[key].Set then
				UIRegistry[key].Set(value, true)
			end
		end

		set("Aimbot_Enabled", FeatureConfig.Aimbot.Enabled)
		set("Aimbot_Keybind", FeatureConfig.Aimbot.Keybind)
		set("Aimbot_LockMode", FeatureConfig.Aimbot.LockMode)
		set("Aimbot_Hitpart", FeatureConfig.Aimbot.Hitpart)
		set("Aimbot_Smoothness", FeatureConfig.Aimbot.Smoothness)
		set("Aimbot_ShakeIntensity", FeatureConfig.Aimbot.ShakeIntensity)
		set("Aimbot_TeamCheck", FeatureConfig.Aimbot.TeamCheck)
		set("Aimbot_VisCheck", FeatureConfig.Aimbot.VisCheck)
		set("Aimbot_UnlockOnDeath", FeatureConfig.Aimbot.UnlockOnDeath)
		set("Aimbot_BreakOnPull", FeatureConfig.Aimbot.BreakOnPull)
		set("Aimbot_MaxLockRadius", FeatureConfig.Aimbot.MaxLockRadius)
		set("Aimbot_MaxDistance", FeatureConfig.Aimbot.MaxDistance)
		set("Aimbot_FOV_Show", FeatureConfig.Aimbot.FOV.Show)
		set("Aimbot_FOV_Filled", FeatureConfig.Aimbot.FOV.Filled)
		set("Aimbot_FOV_Rainbow", FeatureConfig.Aimbot.FOV.Rainbow)
		set("Aimbot_FOV_Size", FeatureConfig.Aimbot.FOV.Size)
		set("Aimbot_FOV_Thickness", FeatureConfig.Aimbot.FOV.Thickness)
		set("Aimbot_Prediction_Horizontal", math.floor((FeatureConfig.Aimbot.Prediction.Horizontal or 0) * 200))
		set("Aimbot_Prediction_Vertical", math.floor((FeatureConfig.Aimbot.Prediction.Vertical or 0) * 200))
		set("Aimbot_Triggerbot_Enabled", FeatureConfig.Aimbot.Triggerbot.Enabled)
		set("Aimbot_Triggerbot_Delay", math.floor(FeatureConfig.Aimbot.Triggerbot.Delay * 100))

		set("ESP_Enabled", FeatureConfig.ESP.Enabled)
		set("ESP_Box", FeatureConfig.ESP.Box)
		set("ESP_Name", FeatureConfig.ESP.Name)
		set("ESP_Health", FeatureConfig.ESP.Health)
		set("ESP_Distance", FeatureConfig.ESP.Distance)
		set("ESP_Tracers", FeatureConfig.ESP.Tracers)
		set("ESP_Skeleton", FeatureConfig.ESP.Skeleton)
		set("ESP_HeadDot", FeatureConfig.ESP.HeadDot)
		set("ESP_LookDir", FeatureConfig.ESP.LookDir)
		set("ESP_TeamCheck", FeatureConfig.ESP.TeamCheck)
		set("ESP_MaxDist", FeatureConfig.ESP.MaxDist)
		set("ESP_Color", FeatureConfig.ESP.Color)
		set("ESP_Chams_Enabled", FeatureConfig.Chams.Enabled)
		set("ESP_Chams_FillColor", FeatureConfig.Chams.FillColor)
		set("ESP_Chams_OutlineColor", FeatureConfig.Chams.OutlineColor)

		set("Movement_Speed", FeatureConfig.Movement.Speed)
		set("Movement_JumpPower", FeatureConfig.Movement.JumpPower)
		set("Movement_SprintEnabled", FeatureConfig.Movement.SprintEnabled)
		set("Movement_SprintSpeed", FeatureConfig.Movement.SprintSpeed)
		set("Movement_InfJump", FeatureConfig.Movement.InfJump)
		set("Movement_FlySpeed", FeatureConfig.Movement.FlySpeed)
		set("Movement_FlyEnabled", FeatureConfig.Movement.FlyEnabled)
		set("Movement_CFrameSpeed", FeatureConfig.Movement.CFrameSpeed)
		set("Movement_CFrameSpeedValue", FeatureConfig.Movement.CFrameSpeedValue or 50)
		set("Movement_Bhop", FeatureConfig.Movement.Bhop)
		set("Camera_FOV", FeatureConfig.Camera.FOV)

		set("Extras_Hitbox_Enabled", FeatureConfig.Extras.Hitbox.Enabled)
		set("Extras_Hitbox_Size", FeatureConfig.Extras.Hitbox.Size)
		set("Extras_SpinBot_Enabled", FeatureConfig.Extras.SpinBot.Enabled)
		set("Extras_SpinBot_Speed", FeatureConfig.Extras.SpinBot.Speed)
		set("Extras_Crosshair_Visible", FeatureConfig.Extras.Crosshair.Visible)
		set("Extras_Crosshair_Size", FeatureConfig.Extras.Crosshair.Size)
		set("Extras_Crosshair_Gap", FeatureConfig.Extras.Crosshair.Gap)
		set("Extras_Crosshair_Thickness", FeatureConfig.Extras.Crosshair.Thickness)
		set("Extras_Crosshair_Color", FeatureConfig.Extras.Crosshair.Color)
		set("Extras_SpeedLines", FeatureConfig.Extras.SpeedLines)
		set("Extras_Wallbang", FeatureConfig.Extras.Wallbang)

		local sr = FeatureConfig.Extras.StretchRes or {}
		set("Extras_StretchRes_Enabled", sr.Enabled == true)
		set("Extras_StretchRes_X", math.floor((sr.X or 1.333) * 100))
		set("Extras_StretchRes_Y", math.floor((sr.Y or 1.0) * 100))

		set("Visuals_Fullbright", FeatureConfig.Visuals.Fullbright)

		set("Perf_NoTextures", FeatureConfig.Performance.NoTextures)
		set("Perf_LowMaterials", FeatureConfig.Performance.LowMaterials)
		set("Perf_OptimizeTerrain", FeatureConfig.Performance.OptimizeTerrain)
		set("Perf_NoPostProcessing", FeatureConfig.Performance.NoPostProcessing)
		set("Perf_NoShadows", FeatureConfig.Performance.NoShadows)
		set("Perf_NoParticles", FeatureConfig.Performance.NoParticles)

		set("Game_DoorPhase", FeatureConfig.Game.DoorPhase)
		set("Game_DoorGlow", FeatureConfig.Game.DoorGlow)
		set("Game_PhaseTransparency", math.floor((FeatureConfig.Game.PhaseTransparency or 0.65) * 100))
		set("Game_GlowColor", FeatureConfig.Game.GlowColor)
		set("Game_NoSpread", FeatureConfig.Game.NoSpread)
		set("Game_FastFire", FeatureConfig.Game.FastFire)
		set("Game_ForceAuto", FeatureConfig.Game.ForceAuto)
		set("Game_ForceRange", FeatureConfig.Game.ForceRange)

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
		local customNames = {}
		for _, path in ipairs(Utils.ListFiles(CONFIG.FOLDER)) do
			local name = path:match("[/\\]?([^/\\]+)$") or path
			if name:sub(-#CONFIG.EXT) == CONFIG.EXT then
				local finalName = name:sub(1, -#CONFIG.EXT - 1)
				if finalName ~= ConfigSystem.AutoloadFile and finalName:lower() ~= "default" then
					table.insert(customNames, finalName)
				end
			end
		end
		table.sort(customNames)

		local names = { "Default" }
		for _, n in ipairs(customNames) do
			table.insert(names, n)
		end
		return names
	end

	function ConfigSystem.Save(name)
		if not name or #name == 0 then
			return false, "Empty name"
		end
		if name:lower() == "default" then
			return false, "Cannot overwrite Default configuration"
		end

		local ok, encoded = pcall(function()
			return HttpService:JSONEncode(ConfigSystem.Serialize())
		end)
		if not ok then
			return false, tostring(encoded)
		end
		return Utils.WriteFile(CONFIG.FOLDER .. "/" .. name .. CONFIG.EXT, encoded)
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

		local content = Utils.ReadFile(CONFIG.FOLDER .. "/" .. name .. CONFIG.EXT)
		if not content then
			return false, "Not found"
		end

		local ok, data = pcall(function()
			return HttpService:JSONDecode(content)
		end)
		if not ok then
			return false, tostring(data)
		end

		ConfigSystem.Deserialize(data)
		ConfigSystem.UpdateUI()
		return true
	end

	function ConfigSystem.Delete(name)
		if not name or name:lower() == "default" then
			return false, "Default configuration cannot be deleted"
		end
		if name:lower() == ConfigSystem.AutoloadFile:lower() then
			return false, "Cannot delete system autoload file"
		end
		return pcall(function()
			delfile(CONFIG.FOLDER .. "/" .. name .. CONFIG.EXT)
		end)
	end

	function ConfigSystem.LoadAutoload()
		local content = Utils.ReadFile(CONFIG.FOLDER .. "/" .. ConfigSystem.AutoloadFile .. CONFIG.EXT)
		if not content then
			return false
		end

		local ok, data = pcall(function()
			return HttpService:JSONDecode(content)
		end)
		if ok and type(data) == "table" then
			ConfigSystem.Deserialize(data)
			return true
		end
		return false
	end

	function ConfigSystem.StartAutosaveLoop()
		local isSaving = false
		Connections.Track(task.spawn(function()
			while true do
				task.wait(1.5)
				if ConfigSystem.Dirty and not isSaving then
					ConfigSystem.Dirty = false
					isSaving = true
					pcall(function()
						local ok, encoded = pcall(function()
							return HttpService:JSONEncode(ConfigSystem.Serialize())
						end)
						if ok then
							Utils.WriteFile(CONFIG.FOLDER .. "/" .. ConfigSystem.AutoloadFile .. CONFIG.EXT, encoded)
						end
					end)
					isSaving = false
				end
			end
		end))
	end

	ConfigSystem.DefaultSnapshot = ConfigSystem.Serialize()
	return ConfigSystem
end
