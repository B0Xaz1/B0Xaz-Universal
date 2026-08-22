local SETTINGS = {
	AUTOLOAD_FILE = "_autoload",
	DEFAULT_CONFIG_NAME = "Default",
	AUTOSAVE_INTERVAL = 1.5,
	DEFAULTS = {
		EXTRAS = {
			HITBOX = { Enabled = false, Size = 10 },
			SPINBOT = { Enabled = false, Speed = 20 },
			CROSSHAIR = {
				Visible = false,
				Size = 12,
				Gap = 4,
				Thickness = 2,
				Color = Color3.fromRGB(255, 255, 255),
			},
			STRETCH_RES = {
				Enabled = false,
				X = 1.333,
				Y = 1.0,
			},
		},
		THEME_PRESET = "Default Cyan",
		CFRAME_SPEED = 50,
		PHASE_TRANSPARENCY = 0.65,
	},
	SCALE_FACTORS = {
		PREDICTION = 200,
		TRIGGERBOT_DELAY = 100,
		STRETCH_RES = 100,
		PHASE_TRANSPARENCY = 100,
	},
	ERRORS = {
		EMPTY_NAME = "Empty name",
		OVERWRITE_DEFAULT = "Cannot overwrite Default configuration",
		DELETE_DEFAULT = "Default configuration cannot be deleted",
		DELETE_AUTOLOAD = "Cannot delete system autoload file",
		NOT_FOUND = "Not found",
		DEFAULT_UNAVAILABLE = "Default snapshot unavailable",
	},
}

return function(Context)
	local HttpService = game:GetService("HttpService")

	local FeatureConfig = (Context and Context.FeatureConfig) or {}
	local CONFIG = (Context and Context.CONFIG) or { FOLDER = "Configs", EXT = ".json" }
	local Utils = (Context and Context.Utils) or {}
	local UIRegistry = (Context and Context.UIRegistry) or {}
	local Theme = (Context and Context.Theme) or {}
	local ThemeManager = Context and Context.ThemeManager
	local State = (Context and Context.State) or {}
	local Connections = Context and Context.Connections

	local ConfigSystem = {
		Dirty = false,
		AutoloadFile = SETTINGS.AUTOLOAD_FILE,
		DefaultSnapshot = nil,
	}

	local function copyTable(source)
		if type(source) ~= "table" then
			return source
		end
		local clone = {}
		for key, val in pairs(source) do
			clone[key] = type(val) == "table" and copyTable(val) or val
		end
		return clone
	end

	local function getConfigPath(name)
		return string.format("%s/%s%s", CONFIG.FOLDER or "", name, CONFIG.EXT or "")
	end

	local function safeColorToTable(color)
		if typeof(color) == "Color3" and Utils.ColorToTable then
			return Utils.ColorToTable(color)
		end
		return color
	end

	local function safeTableToColor(data)
		if type(data) == "table" and Utils.TableToColor then
			return Utils.TableToColor(data)
		end
		return data
	end

	local function serializeKeybind(bind)
		if bind == nil then
			return nil
		end
		local bindType = typeof(bind)
		if bindType == "string" then
			return { kind = "string", value = bind }
		elseif bindType == "EnumItem" then
			if bind.EnumType == Enum.KeyCode or bind.EnumType == Enum.UserInputType then
				return { kind = bind.EnumType.Name, value = bind.Name }
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
		elseif data.kind == "KeyCode" then
			local success, result = pcall(function()
				return Enum.KeyCode[data.value]
			end)
			return success and result or nil
		elseif data.kind == "UserInputType" then
			local success, result = pcall(function()
				return Enum.UserInputType[data.value]
			end)
			return success and result or nil
		end
		return nil
	end

	local function getStretchResData()
		local stretch = FeatureConfig.Extras and FeatureConfig.Extras.StretchRes
		if type(stretch) ~= "table" then
			return copyTable(SETTINGS.DEFAULTS.EXTRAS.STRETCH_RES)
		end
		return {
			Enabled = stretch.Enabled == true,
			X = tonumber(stretch.X) or SETTINGS.DEFAULTS.EXTRAS.STRETCH_RES.X,
			Y = tonumber(stretch.Y) or SETTINGS.DEFAULTS.EXTRAS.STRETCH_RES.Y,
		}
	end

	function ConfigSystem.NotifyChange()
		ConfigSystem.Dirty = true
	end

	function ConfigSystem.Serialize()
		local themeData = {}
		for key, val in pairs(Theme) do
			if typeof(val) == "Color3" then
				themeData[key] = safeColorToTable(val)
			end
		end

		local extras = FeatureConfig.Extras or {}
		local hitbox = extras.Hitbox or SETTINGS.DEFAULTS.EXTRAS.HITBOX
		local spinBot = extras.SpinBot or SETTINGS.DEFAULTS.EXTRAS.SPINBOT
		local crosshair = extras.Crosshair or SETTINGS.DEFAULTS.EXTRAS.CROSSHAIR
		local aimbot = FeatureConfig.Aimbot or {}
		local movement = FeatureConfig.Movement or {}
		local esp = FeatureConfig.ESP or {}
		local chams = FeatureConfig.Chams or {}
		local camera = FeatureConfig.Camera or {}
		local visuals = FeatureConfig.Visuals or {}
		local perf = FeatureConfig.Performance or {}
		local gameMod = FeatureConfig.Game or {}

		return {
			Aimbot = {
				Enabled = aimbot.Enabled,
				Keybind = serializeKeybind(aimbot.Keybind),
				Hitpart = aimbot.Hitpart,
				AirHitpart = aimbot.AirHitpart,
				Smoothness = aimbot.Smoothness,
				LockMode = aimbot.LockMode,
				Prediction = copyTable(aimbot.Prediction or {}),
				TeamCheck = aimbot.TeamCheck,
				VisCheck = aimbot.VisCheck,
				MaxDistance = aimbot.MaxDistance,
				ShakeIntensity = aimbot.ShakeIntensity,
				LockNPC = aimbot.LockNPC,
				UnlockOnDeath = aimbot.UnlockOnDeath,
				BreakOnPull = aimbot.BreakOnPull,
				MaxLockRadius = aimbot.MaxLockRadius,
				Triggerbot = copyTable(aimbot.Triggerbot or {}),
				FOV = copyTable(aimbot.FOV or {}),
			},
			Movement = copyTable(movement),
			ESP = {
				Enabled = esp.Enabled,
				Box = esp.Box,
				Name = esp.Name,
				Health = esp.Health,
				Distance = esp.Distance,
				Tracers = esp.Tracers,
				Skeleton = esp.Skeleton,
				HeadDot = esp.HeadDot,
				LookDir = esp.LookDir,
				TeamCheck = esp.TeamCheck,
				MaxDist = esp.MaxDist,
				Color = safeColorToTable(esp.Color),
			},
			Chams = {
				Enabled = chams.Enabled,
				FillColor = safeColorToTable(chams.FillColor),
				OutlineColor = safeColorToTable(chams.OutlineColor),
			},
			Camera = {
				FOV = camera.FOV,
			},
			Visuals = {
				Fullbright = visuals.Fullbright,
			},
			Extras = {
				Hitbox = {
					Enabled = hitbox.Enabled == true,
					Size = tonumber(hitbox.Size) or SETTINGS.DEFAULTS.EXTRAS.HITBOX.Size,
				},
				SpinBot = {
					Enabled = spinBot.Enabled == true,
					Speed = tonumber(spinBot.Speed) or SETTINGS.DEFAULTS.EXTRAS.SPINBOT.Speed,
				},
				Crosshair = {
					Visible = crosshair.Visible == true,
					Size = tonumber(crosshair.Size) or SETTINGS.DEFAULTS.EXTRAS.CROSSHAIR.Size,
					Gap = tonumber(crosshair.Gap) or SETTINGS.DEFAULTS.EXTRAS.CROSSHAIR.Gap,
					Thickness = tonumber(crosshair.Thickness) or SETTINGS.DEFAULTS.EXTRAS.CROSSHAIR.Thickness,
					Color = safeColorToTable(crosshair.Color or SETTINGS.DEFAULTS.EXTRAS.CROSSHAIR.Color),
				},
				SpeedLines = extras.SpeedLines == true,
				Wallbang = extras.Wallbang == true,
				StretchRes = getStretchResData(),
			},
			Performance = copyTable(perf),
			Game = {
				DoorPhase = gameMod.DoorPhase,
				DoorGlow = gameMod.DoorGlow,
				GlowColor = safeColorToTable(gameMod.GlowColor),
				PhaseTransparency = gameMod.PhaseTransparency,
				NoSpread = gameMod.NoSpread,
				FastFire = gameMod.FastFire,
				ForceAuto = gameMod.ForceAuto,
				ForceRange = gameMod.ForceRange,
				FireRateValue = gameMod.FireRateValue,
				RangeValue = gameMod.RangeValue,
			},
			Theme = {
				PresetName = (ThemeManager and ThemeManager.ActivePreset) or SETTINGS.DEFAULTS.THEME_PRESET,
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

		if type(data.Aimbot) == "table" and FeatureConfig.Aimbot then
			for key, val in pairs(data.Aimbot) do
				if key == "Keybind" then
					FeatureConfig.Aimbot.Keybind = deserializeKeybind(val) or FeatureConfig.Aimbot.Keybind
				elseif (key == "Prediction" or key == "FOV" or key == "Triggerbot") and type(val) == "table" then
					FeatureConfig.Aimbot[key] = FeatureConfig.Aimbot[key] or {}
					for subKey, subVal in pairs(val) do
						FeatureConfig.Aimbot[key][subKey] = subVal
					end
				else
					FeatureConfig.Aimbot[key] = val
				end
			end
		end

		if type(data.Movement) == "table" and FeatureConfig.Movement then
			for key, val in pairs(data.Movement) do
				FeatureConfig.Movement[key] = val
			end
		end

		if type(data.ESP) == "table" and FeatureConfig.ESP then
			for key, val in pairs(data.ESP) do
				if key == "Color" then
					FeatureConfig.ESP.Color = safeTableToColor(val)
				else
					FeatureConfig.ESP[key] = val
				end
			end
		end

		if type(data.Chams) == "table" and FeatureConfig.Chams then
			for key, val in pairs(data.Chams) do
				if key == "FillColor" or key == "OutlineColor" then
					FeatureConfig.Chams[key] = safeTableToColor(val)
				else
					FeatureConfig.Chams[key] = val
				end
			end
		end

		if type(data.Camera) == "table" and type(data.Camera.FOV) == "number" and FeatureConfig.Camera then
			FeatureConfig.Camera.FOV = data.Camera.FOV
		end

		if type(data.Visuals) == "table" and data.Visuals.Fullbright ~= nil and FeatureConfig.Visuals then
			FeatureConfig.Visuals.Fullbright = data.Visuals.Fullbright
		end

		if type(data.Extras) == "table" and FeatureConfig.Extras then
			if type(data.Extras.Hitbox) == "table" and FeatureConfig.Extras.Hitbox then
				for key, val in pairs(data.Extras.Hitbox) do
					FeatureConfig.Extras.Hitbox[key] = val
				end
			end

			if type(data.Extras.SpinBot) == "table" and FeatureConfig.Extras.SpinBot then
				for key, val in pairs(data.Extras.SpinBot) do
					FeatureConfig.Extras.SpinBot[key] = val
				end
			end

			if type(data.Extras.Crosshair) == "table" and FeatureConfig.Extras.Crosshair then
				for key, val in pairs(data.Extras.Crosshair) do
					if key == "Color" then
						FeatureConfig.Extras.Crosshair.Color = safeTableToColor(val)
					else
						FeatureConfig.Extras.Crosshair[key] = val
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
				FeatureConfig.Extras.StretchRes = FeatureConfig.Extras.StretchRes or copyTable(SETTINGS.DEFAULTS.EXTRAS.STRETCH_RES)
				for key, val in pairs(data.Extras.StretchRes) do
					FeatureConfig.Extras.StretchRes[key] = val
				end
			end
		end

		if type(data.Performance) == "table" and FeatureConfig.Performance then
			for key, val in pairs(data.Performance) do
				FeatureConfig.Performance[key] = val
			end
		end

		if type(data.Game) == "table" and FeatureConfig.Game then
			for key, val in pairs(data.Game) do
				if key == "GlowColor" then
					FeatureConfig.Game.GlowColor = safeTableToColor(val)
				else
					FeatureConfig.Game[key] = val
				end
			end
		end

		if type(data.Theme) == "table" then
			if ThemeManager and data.Theme.PresetName then
				ThemeManager.ActivePreset = data.Theme.PresetName
			end
			if type(data.Theme.Colors) == "table" and Context.UI and Context.UI.SetTheme then
				local themeColors = {}
				for key, val in pairs(data.Theme.Colors) do
					themeColors[key] = safeTableToColor(val)
				end
				Context.UI:SetTheme(themeColors)
			end
		end

		if type(data.Settings) == "table" then
			State.MenuKeybind = deserializeKeybind(data.Settings.MenuKeybind) or State.MenuKeybind
			State.includeSelf = data.Settings.IncludeSelf or false
		end

		if FeatureConfig.Aimbot and not FeatureConfig.Aimbot.Enabled and Context.AimbotSystem then
			Context.AimbotSystem.LockOff()
		end
		if FeatureConfig.Movement and not FeatureConfig.Movement.FlyEnabled and Context.FlySystem then
			Context.FlySystem.Stop()
		end
		if FeatureConfig.Extras and FeatureConfig.Extras.Hitbox and not FeatureConfig.Extras.Hitbox.Enabled and Context.ResetHitboxes then
			Context.ResetHitboxes()
		end
	end

	function ConfigSystem.UpdateUI()
		local function set(key, value)
			local entry = UIRegistry[key]
			if entry and type(entry.Set) == "function" then
				entry.Set(value, true)
			end
		end

		local aimbot = FeatureConfig.Aimbot or {}
		local aimFov = aimbot.FOV or {}
		local aimPred = aimbot.Prediction or {}
		local aimTrigger = aimbot.Triggerbot or {}

		set("Aimbot_Enabled", aimbot.Enabled)
		set("Aimbot_Keybind", aimbot.Keybind)
		set("Aimbot_LockMode", aimbot.LockMode)
		set("Aimbot_Hitpart", aimbot.Hitpart)
		set("Aimbot_Smoothness", aimbot.Smoothness)
		set("Aimbot_ShakeIntensity", aimbot.ShakeIntensity)
		set("Aimbot_TeamCheck", aimbot.TeamCheck)
		set("Aimbot_VisCheck", aimbot.VisCheck)
		set("Aimbot_UnlockOnDeath", aimbot.UnlockOnDeath)
		set("Aimbot_BreakOnPull", aimbot.BreakOnPull)
		set("Aimbot_MaxLockRadius", aimbot.MaxLockRadius)
		set("Aimbot_MaxDistance", aimbot.MaxDistance)
		set("Aimbot_FOV_Show", aimFov.Show)
		set("Aimbot_FOV_Filled", aimFov.Filled)
		set("Aimbot_FOV_Rainbow", aimFov.Rainbow)
		set("Aimbot_FOV_Size", aimFov.Size)
		set("Aimbot_FOV_Thickness", aimFov.Thickness)
		set("Aimbot_Prediction_Horizontal", math.floor((aimPred.Horizontal or 0) * SETTINGS.SCALE_FACTORS.PREDICTION))
		set("Aimbot_Prediction_Vertical", math.floor((aimPred.Vertical or 0) * SETTINGS.SCALE_FACTORS.PREDICTION))
		set("Aimbot_Triggerbot_Enabled", aimTrigger.Enabled)
		set("Aimbot_Triggerbot_Delay", math.floor((aimTrigger.Delay or 0) * SETTINGS.SCALE_FACTORS.TRIGGERBOT_DELAY))

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
		set("Movement_CFrameSpeedValue", mov.CFrameSpeedValue or SETTINGS.DEFAULTS.CFRAME_SPEED)
		set("Movement_Bhop", mov.Bhop)

		local cam = FeatureConfig.Camera or {}
		set("Camera_FOV", cam.FOV)

		local ext = FeatureConfig.Extras or {}
		local extHitbox = ext.Hitbox or {}
		local extSpin = ext.SpinBot or {}
		local extCross = ext.Crosshair or {}
		local extStretch = ext.StretchRes or {}

		set("Extras_Hitbox_Enabled", extHitbox.Enabled)
		set("Extras_Hitbox_Size", extHitbox.Size)
		set("Extras_SpinBot_Enabled", extSpin.Enabled)
		set("Extras_SpinBot_Speed", extSpin.Speed)
		set("Extras_Crosshair_Visible", extCross.Visible)
		set("Extras_Crosshair_Size", extCross.Size)
		set("Extras_Crosshair_Gap", extCross.Gap)
		set("Extras_Crosshair_Thickness", extCross.Thickness)
		set("Extras_Crosshair_Color", extCross.Color)
		set("Extras_SpeedLines", ext.SpeedLines)
		set("Extras_Wallbang", ext.Wallbang)
		set("Extras_StretchRes_Enabled", extStretch.Enabled == true)
		set("Extras_StretchRes_X", math.floor((extStretch.X or SETTINGS.DEFAULTS.EXTRAS.STRETCH_RES.X) * SETTINGS.SCALE_FACTORS.STRETCH_RES))
		set("Extras_StretchRes_Y", math.floor((extStretch.Y or SETTINGS.DEFAULTS.EXTRAS.STRETCH_RES.Y) * SETTINGS.SCALE_FACTORS.STRETCH_RES))

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
		set("Game_PhaseTransparency", math.floor((gm.PhaseTransparency or SETTINGS.DEFAULTS.PHASE_TRANSPARENCY) * SETTINGS.SCALE_FACTORS.PHASE_TRANSPARENCY))
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
		local customNames = {}
		local fileList = (Utils.ListFiles and Utils.ListFiles(CONFIG.FOLDER)) or {}
		local extLen = #(CONFIG.EXT or "")

		for _, path in ipairs(fileList) do
			local fileName = path:match("[/\\]?([^/\\]+)$") or path
			if fileName:sub(-extLen) == CONFIG.EXT then
				local baseName = fileName:sub(1, -extLen - 1)
				if baseName ~= ConfigSystem.AutoloadFile and baseName:lower() ~= SETTINGS.DEFAULT_CONFIG_NAME:lower() then
					table.insert(customNames, baseName)
				end
			end
		end
		table.sort(customNames)

		local results = { SETTINGS.DEFAULT_CONFIG_NAME }
		for _, name in ipairs(customNames) do
			table.insert(results, name)
		end
		return results
	end

	function ConfigSystem.Save(name)
		if not name or #name == 0 then
			return false, SETTINGS.ERRORS.EMPTY_NAME
		end
		if name:lower() == SETTINGS.DEFAULT_CONFIG_NAME:lower() then
			return false, SETTINGS.ERRORS.OVERWRITE_DEFAULT
		end

		local encodeSuccess, encoded = pcall(function()
			return HttpService:JSONEncode(ConfigSystem.Serialize())
		end)
		if not encodeSuccess then
			return false, tostring(encoded)
		end

		if not Utils.WriteFile then
			return false, "WriteFile unavailable"
		end
		return Utils.WriteFile(getConfigPath(name), encoded)
	end

	function ConfigSystem.Load(name)
		if name == SETTINGS.DEFAULT_CONFIG_NAME then
			if ConfigSystem.DefaultSnapshot then
				ConfigSystem.Deserialize(ConfigSystem.DefaultSnapshot)
				ConfigSystem.UpdateUI()
				return true
			end
			return false, SETTINGS.ERRORS.DEFAULT_UNAVAILABLE
		end

		if not Utils.ReadFile then
			return false, "ReadFile unavailable"
		end
		local content = Utils.ReadFile(getConfigPath(name))
		if not content then
			return false, SETTINGS.ERRORS.NOT_FOUND
		end

		local decodeSuccess, decoded = pcall(function()
			return HttpService:JSONDecode(content)
		end)
		if not decodeSuccess then
			return false, tostring(decoded)
		end

		ConfigSystem.Deserialize(decoded)
		ConfigSystem.UpdateUI()
		return true
	end

	function ConfigSystem.Delete(name)
		if not name or name:lower() == SETTINGS.DEFAULT_CONFIG_NAME:lower() then
			return false, SETTINGS.ERRORS.DELETE_DEFAULT
		end
		if name:lower() == ConfigSystem.AutoloadFile:lower() then
			return false, SETTINGS.ERRORS.DELETE_AUTOLOAD
		end
		return pcall(function()
			delfile(getConfigPath(name))
		end)
	end

	function ConfigSystem.LoadAutoload()
		if not Utils.ReadFile then
			return false
		end
		local content = Utils.ReadFile(getConfigPath(ConfigSystem.AutoloadFile))
		if not content then
			return false
		end

		local decodeSuccess, decoded = pcall(function()
			return HttpService:JSONDecode(content)
		end)
		if decodeSuccess and type(decoded) == "table" then
			ConfigSystem.Deserialize(decoded)
			return true
		end
		return false
	end

	function ConfigSystem.StartAutosaveLoop()
		local isSaving = false
		local autoSaveThread = task.spawn(function()
			while true do
				task.wait(SETTINGS.AUTOSAVE_INTERVAL)
				if ConfigSystem.Dirty and not isSaving then
					ConfigSystem.Dirty = false
					isSaving = true
					pcall(function()
						local encodeSuccess, encoded = pcall(function()
							return HttpService:JSONEncode(ConfigSystem.Serialize())
						end)
						if encodeSuccess and Utils.WriteFile then
							Utils.WriteFile(getConfigPath(ConfigSystem.AutoloadFile), encoded)
						end
					end)
					isSaving = false
				end
			end
		end)

		if Connections and type(Connections.Track) == "function" then
			Connections.Track(autoSaveThread)
		end
	end

	ConfigSystem.DefaultSnapshot = ConfigSystem.Serialize()
	return ConfigSystem
end
