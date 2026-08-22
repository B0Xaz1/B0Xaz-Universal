-- // src/UI/BuildUI.lua
local SETTINGS = {
	TITLE = "B0Xaz Universal",
	DEFAULT_CONFIG_NAME = "Default",
	DEFAULT_IMPORT_NAME = "ImportedConfig",
	URLS = {
		ROBLOX_SERVERS = "https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100",
	},
	LIMITS = {
		SERVER_HOP_COOLDOWN = 3.0,
		REFRESH_PLAYERS_COOLDOWN = 0.5,
		REFRESH_CONFIGS_COOLDOWN = 0.5,
		PREDICTION_SCALE = 200,
		TRIGGER_DELAY_SCALE = 100,
		MAX_FPS_UNLOCK = 999,
		FPS_60 = 60,
		FPS_144 = 144,
		STATUS_POLL_INTERVAL = 0.5,
		REJOIN_WAIT = 2.0,
		WALLBANG_TRANSPARENCY = 0.85,
	},
	RANGES = {
		AIMBOT_SMOOTHNESS = { MIN = 1, MAX = 20 },
		AIMBOT_SHAKE = { MIN = 0, MAX = 10 },
		AIMBOT_LOCK_RADIUS = { MIN = 50, MAX = 500 },
		AIMBOT_MAX_DIST = { MIN = 50, MAX = 2000 },
		AIMBOT_FOV_SIZE = { MIN = 10, MAX = 600 },
		AIMBOT_FOV_THICKNESS = { MIN = 1, MAX = 10 },
		AIMBOT_PRED = { MIN = 0, MAX = 100 },
		AIMBOT_TRIGGER_DELAY = { MIN = 0, MAX = 50 },
		ESP_MAX_DIST = { MIN = 100, MAX = 2000 },
		CROSSHAIR_SIZE = { MIN = 4, MAX = 40 },
		CROSSHAIR_GAP = { MIN = 0, MAX = 20 },
		CROSSHAIR_THICKNESS = { MIN = 1, MAX = 6 },
		LIGHTING_CLOCK = { MIN = 0, MAX = 24 },
		WALK_SPEED = { MIN = 16, MAX = 500 },
		JUMP_POWER = { MIN = 50, MAX = 500 },
		SPRINT_SPEED = { MIN = 16, MAX = 500 },
		CFRAME_SPEED = { MIN = 1, MAX = 500 },
		FLY_SPEED = { MIN = 10, MAX = 500 },
		GRAVITY = { MIN = 0, MAX = 300 },
		HIP_HEIGHT = { MIN = 0, MAX = 48 },
		CAMERA_FOV = { MIN = 70, MAX = 120 },
		MAX_CAMERA_ZOOM = { MIN = 10, MAX = 1000 },
		HITBOX_SIZE = { MIN = 4, MAX = 60 },
		SPIN_SPEED = { MIN = 1, MAX = 500 },
	},
	HITPARTS = { "Head", "Torso", "Root", "LeftArm", "RightArm", "LeftLeg", "RightLeg" },
	LOCK_MODES = { "Hold", "Toggle" },
	THEME_KEYS = { "Accent", "Bg", "Panel", "Elem", "Side", "Text", "Border", "ToggleOn" },
	DEFAULT_PRESET = "Default Cyan",
}

return function(Context)
	local Players = game:GetService("Players")
	local Workspace = game:GetService("Workspace")
	local Lighting = game:GetService("Lighting")
	local UserInputService = game:GetService("UserInputService")
	local HttpService = game:GetService("HttpService")
	local TeleportService = game:GetService("TeleportService")
	local VirtualUser = game:GetService("VirtualUser")

	local LocalPlayer = Players.LocalPlayer
	local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

	local Theme = (Context and Context.Theme) or {}
	local ThemeManager = Context and Context.ThemeManager
	local FeatureConfig = (Context and Context.FeatureConfig) or {}
	local State = (Context and Context.State) or {}
	local StatsConfig = (Context and Context.StatsConfig) or {}
	local UIRegistry = (Context and Context.UIRegistry) or {}
	local Utils = (Context and Context.Utils) or {}
	local Connections = (Context and Context.Connections) or {}
	local DefaultLighting = (Context and Context.DefaultLighting) or {}

	local AimbotSystem = Context and Context.AimbotSystem
	local ESPSystem = Context and Context.ESPSystem
	local FlySystem = Context and Context.FlySystem
	local ConfigSystem = Context and Context.ConfigSystem
	local OverlayManager = Context and Context.OverlayManager
	local PerfSystem = Context and Context.PerformanceSystem
	local PlayersSystem = Context and Context.PlayersSystem
	local KeySystem = Context and Context.KeySystem

	local UI = Context.UIEngine.new(SETTINGS.TITLE)
	Context.UI = UI
	getgenv().B0XazLibrary = UI

	local isListeningForMenuKey = false
	local lastServerHopTime = 0
	local lastPlayerRefreshTime = 0
	local lastConfigRefreshTime = 0

	local function safeNotify(title, message, duration, color)
		if UI and UI.Notify then
			UI:Notify(title, message, duration, color)
		end
	end

	local function safeSetClipboard(text)
		if setclipboard then
			pcall(setclipboard, text)
			return true
		end
		return false
	end

	local function safeSetFpsCap(cap)
		if setfpscap then
			pcall(setfpscap, cap)
		end
	end

	local function updateCustomPickers(presetTheme)
		if type(presetTheme) ~= "table" then return end
		for key, val in pairs(presetTheme) do
			local registryKey = "Theme_" .. key
			if UIRegistry[registryKey] and type(UIRegistry[registryKey].Set) == "function" then
				UIRegistry[registryKey].Set(val, true)
			end
		end
	end

	if Connections and Connections.Add then
		Connections.Add(UserInputService.InputBegan:Connect(function(input, processed)
			if isListeningForMenuKey or processed then return end
			if State.MenuKeybind and input.KeyCode == State.MenuKeybind then
				State.MenuVisible = not State.MenuVisible
				if UI.Main then
					UI.Main.Visible = State.MenuVisible
				end
			end
		end))
	end

	local combatTab = UI:AddTab("Combat", 3)
	local aimMain = combatTab:AddSection("Aimbot Controls")

	UIRegistry.Aimbot_Enabled = aimMain:AddToggle("Aimbot Enabled", FeatureConfig.Aimbot.Enabled, function(v)
		FeatureConfig.Aimbot.Enabled = v
		if not v and AimbotSystem then
			AimbotSystem.LockOff()
		end
	end)

	UIRegistry.Aimbot_Keybind = aimMain:AddKeybind("Activation Bind", FeatureConfig.Aimbot.Keybind, function(k)
		FeatureConfig.Aimbot.Keybind = k
		safeNotify("Aimbot", "Bind updated", nil, Theme.Success)
	end)

	UIRegistry.Aimbot_LockMode = aimMain:AddDropdown("Lock Mode", SETTINGS.LOCK_MODES, function(v)
		FeatureConfig.Aimbot.LockMode = v
		if AimbotSystem then
			AimbotSystem.LockOff()
		end
	end, FeatureConfig.Aimbot.LockMode)

	UIRegistry.Aimbot_Hitpart = aimMain:AddDropdown("Hit Part", SETTINGS.HITPARTS, function(v)
		FeatureConfig.Aimbot.Hitpart = v
	end, FeatureConfig.Aimbot.Hitpart)

	UIRegistry.Aimbot_Smoothness = aimMain:AddSlider(
		"Smoothness",
		FeatureConfig.Aimbot.Smoothness,
		SETTINGS.RANGES.AIMBOT_SMOOTHNESS.MIN,
		SETTINGS.RANGES.AIMBOT_SMOOTHNESS.MAX,
		function(v) FeatureConfig.Aimbot.Smoothness = v end
	)

	UIRegistry.Aimbot_ShakeIntensity = aimMain:AddSlider(
		"Shake Intensity",
		FeatureConfig.Aimbot.ShakeIntensity,
		SETTINGS.RANGES.AIMBOT_SHAKE.MIN,
		SETTINGS.RANGES.AIMBOT_SHAKE.MAX,
		function(v) FeatureConfig.Aimbot.ShakeIntensity = v end
	)

	local aimCheck = combatTab:AddSection("Target Settings")
	UIRegistry.Aimbot_TeamCheck = aimCheck:AddToggle("Team Check", FeatureConfig.Aimbot.TeamCheck, function(v)
		FeatureConfig.Aimbot.TeamCheck = v
	end)
	UIRegistry.Aimbot_VisCheck = aimCheck:AddToggle("Visibility Check", FeatureConfig.Aimbot.VisCheck, function(v)
		FeatureConfig.Aimbot.VisCheck = v
	end)
	UIRegistry.Aimbot_UnlockOnDeath = aimCheck:AddToggle("Unlock On Death", FeatureConfig.Aimbot.UnlockOnDeath, function(v)
		FeatureConfig.Aimbot.UnlockOnDeath = v
	end)
	UIRegistry.Aimbot_BreakOnPull = aimCheck:AddToggle("Break on Mouse Pull", FeatureConfig.Aimbot.BreakOnPull, function(v)
		FeatureConfig.Aimbot.BreakOnPull = v
	end)
	UIRegistry.Aimbot_MaxLockRadius = aimCheck:AddSlider(
		"Max Lock Radius",
		FeatureConfig.Aimbot.MaxLockRadius or 200,
		SETTINGS.RANGES.AIMBOT_LOCK_RADIUS.MIN,
		SETTINGS.RANGES.AIMBOT_LOCK_RADIUS.MAX,
		function(v) FeatureConfig.Aimbot.MaxLockRadius = v end,
		" px"
	)
	UIRegistry.Aimbot_MaxDistance = aimCheck:AddSlider(
		"Max Target Distance",
		FeatureConfig.Aimbot.MaxDistance,
		SETTINGS.RANGES.AIMBOT_MAX_DIST.MIN,
		SETTINGS.RANGES.AIMBOT_MAX_DIST.MAX,
		function(v) FeatureConfig.Aimbot.MaxDistance = v end,
		" studs"
	)

	local aimFov = combatTab:AddSection("Aimbot FOV")
	UIRegistry.Aimbot_FOV_Show = aimFov:AddToggle("Show FOV Circle", FeatureConfig.Aimbot.FOV.Show, function(v)
		FeatureConfig.Aimbot.FOV.Show = v
	end)
	UIRegistry.Aimbot_FOV_Filled = aimFov:AddToggle("Filled Circle", FeatureConfig.Aimbot.FOV.Filled, function(v)
		FeatureConfig.Aimbot.FOV.Filled = v
	end)
	UIRegistry.Aimbot_FOV_Rainbow = aimFov:AddToggle("Rainbow FOV", FeatureConfig.Aimbot.FOV.Rainbow, function(v)
		FeatureConfig.Aimbot.FOV.Rainbow = v
	end)
	UIRegistry.Aimbot_FOV_Size = aimFov:AddSlider(
		"FOV Radius",
		FeatureConfig.Aimbot.FOV.Size,
		SETTINGS.RANGES.AIMBOT_FOV_SIZE.MIN,
		SETTINGS.RANGES.AIMBOT_FOV_SIZE.MAX,
		function(v) FeatureConfig.Aimbot.FOV.Size = v end,
		" px"
	)
	UIRegistry.Aimbot_FOV_Thickness = aimFov:AddSlider(
		"Line Thickness",
		FeatureConfig.Aimbot.FOV.Thickness,
		SETTINGS.RANGES.AIMBOT_FOV_THICKNESS.MIN,
		SETTINGS.RANGES.AIMBOT_FOV_THICKNESS.MAX,
		function(v) FeatureConfig.Aimbot.FOV.Thickness = v end
	)

	local aimPred = combatTab:AddSection("Prediction & Triggerbot")
	UIRegistry.Aimbot_Prediction_Horizontal = aimPred:AddSlider(
		"Horizontal Prediction",
		math.floor((FeatureConfig.Aimbot.Prediction.Horizontal or 0) * SETTINGS.LIMITS.PREDICTION_SCALE),
		SETTINGS.RANGES.AIMBOT_PRED.MIN,
		SETTINGS.RANGES.AIMBOT_PRED.MAX,
		function(v) FeatureConfig.Aimbot.Prediction.Horizontal = v / SETTINGS.LIMITS.PREDICTION_SCALE end
	)
	UIRegistry.Aimbot_Prediction_Vertical = aimPred:AddSlider(
		"Vertical Prediction",
		math.floor((FeatureConfig.Aimbot.Prediction.Vertical or 0) * SETTINGS.LIMITS.PREDICTION_SCALE),
		SETTINGS.RANGES.AIMBOT_PRED.MIN,
		SETTINGS.RANGES.AIMBOT_PRED.MAX,
		function(v) FeatureConfig.Aimbot.Prediction.Vertical = v / SETTINGS.LIMITS.PREDICTION_SCALE end
	)
	aimPred:AddButton("Reset Prediction", function()
		FeatureConfig.Aimbot.Prediction.Horizontal = 0
		FeatureConfig.Aimbot.Prediction.Vertical = 0
		if UIRegistry.Aimbot_Prediction_Horizontal then UIRegistry.Aimbot_Prediction_Horizontal.Set(0, true) end
		if UIRegistry.Aimbot_Prediction_Vertical then UIRegistry.Aimbot_Prediction_Vertical.Set(0, true) end
		safeNotify("Prediction", "Reset to zero", nil, Theme.Success)
	end)
	UIRegistry.Aimbot_Triggerbot_Enabled = aimPred:AddToggle("Enable Triggerbot", FeatureConfig.Aimbot.Triggerbot.Enabled, function(v)
		FeatureConfig.Aimbot.Triggerbot.Enabled = v
	end)
	UIRegistry.Aimbot_Triggerbot_Delay = aimPred:AddSlider(
		"Trigger Delay",
		math.floor((FeatureConfig.Aimbot.Triggerbot.Delay or 0) * SETTINGS.LIMITS.TRIGGER_DELAY_SCALE),
		SETTINGS.RANGES.AIMBOT_TRIGGER_DELAY.MIN,
		SETTINGS.RANGES.AIMBOT_TRIGGER_DELAY.MAX,
		function(v) FeatureConfig.Aimbot.Triggerbot.Delay = v / SETTINGS.LIMITS.TRIGGER_DELAY_SCALE end,
		" ms"
	)

	local visualsTab = UI:AddTab("Visuals", 2)
	local espMain = visualsTab:AddSection("Player ESP")

	UIRegistry.ESP_Enabled = espMain:AddToggle("Enable ESP", FeatureConfig.ESP.Enabled, function(v) FeatureConfig.ESP.Enabled = v end)
	UIRegistry.ESP_Box = espMain:AddToggle("Draw Boxes", FeatureConfig.ESP.Box, function(v) FeatureConfig.ESP.Box = v end)
	UIRegistry.ESP_Name = espMain:AddToggle("Show Names", FeatureConfig.ESP.Name, function(v) FeatureConfig.ESP.Name = v end)
	UIRegistry.ESP_Health = espMain:AddToggle("Show Health", FeatureConfig.ESP.Health, function(v) FeatureConfig.ESP.Health = v end)
	UIRegistry.ESP_Distance = espMain:AddToggle("Show Distance", FeatureConfig.ESP.Distance, function(v) FeatureConfig.ESP.Distance = v end)
	UIRegistry.ESP_Tracers = espMain:AddToggle("Show Tracers", FeatureConfig.ESP.Tracers, function(v) FeatureConfig.ESP.Tracers = v end)
	UIRegistry.ESP_Skeleton = espMain:AddToggle("Show Skeletons", FeatureConfig.ESP.Skeleton, function(v) FeatureConfig.ESP.Skeleton = v end)
	UIRegistry.ESP_HeadDot = espMain:AddToggle("Draw Head Dot", FeatureConfig.ESP.HeadDot, function(v) FeatureConfig.ESP.HeadDot = v end)
	UIRegistry.ESP_LookDir = espMain:AddToggle("Look Vector Lines", FeatureConfig.ESP.LookDir, function(v) FeatureConfig.ESP.LookDir = v end)
	UIRegistry.ESP_TeamCheck = espMain:AddToggle("Team Check", FeatureConfig.ESP.TeamCheck, function(v) FeatureConfig.ESP.TeamCheck = v end)

	local espSet = visualsTab:AddSection("ESP Configuration")
	UIRegistry.ESP_MaxDist = espSet:AddSlider(
		"Max Render Distance",
		FeatureConfig.ESP.MaxDist,
		SETTINGS.RANGES.ESP_MAX_DIST.MIN,
		SETTINGS.RANGES.ESP_MAX_DIST.MAX,
		function(v) FeatureConfig.ESP.MaxDist = v end,
		" studs"
	)
	UIRegistry.ESP_Color = espSet:AddColorPicker("ESP Global Color", FeatureConfig.ESP.Color, function(c)
		FeatureConfig.ESP.Color = c
	end)

	local chamsSec = visualsTab:AddSection("Player Chams")
	UIRegistry.ESP_Chams_Enabled = chamsSec:AddToggle("Enable Highlights", FeatureConfig.Chams.Enabled, function(v)
		FeatureConfig.Chams.Enabled = v
		if not ESPSystem then return end
		if v then
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= LocalPlayer and Utils.IsAlive and Utils.IsAlive(p) and not (FeatureConfig.ESP.TeamCheck and Utils.SameTeam and Utils.SameTeam(p)) then
					ESPSystem.RemoveHighlight(p)
					ESPSystem.AddHighlight(p)
				end
			end
		else
			for _, p in ipairs(Players:GetPlayers()) do
				ESPSystem.RemoveHighlight(p)
			end
		end
	end)
	UIRegistry.ESP_Chams_FillColor = chamsSec:AddColorPicker("Chams Fill Color", FeatureConfig.Chams.FillColor, function(c)
		FeatureConfig.Chams.FillColor = c
	end)
	UIRegistry.ESP_Chams_OutlineColor = chamsSec:AddColorPicker("Chams Outline Color", FeatureConfig.Chams.OutlineColor, function(c)
		FeatureConfig.Chams.OutlineColor = c
	end)

	local crossSec = visualsTab:AddSection("Custom Crosshair")
	UIRegistry.Extras_Crosshair_Visible = crossSec:AddToggle("Display Crosshair", false, function(v)
		FeatureConfig.Extras.Crosshair.Visible = v
	end)
	UIRegistry.Extras_Crosshair_Size = crossSec:AddSlider(
		"Crosshair Size",
		FeatureConfig.Extras.Crosshair.Size,
		SETTINGS.RANGES.CROSSHAIR_SIZE.MIN,
		SETTINGS.RANGES.CROSSHAIR_SIZE.MAX,
		function(v) FeatureConfig.Extras.Crosshair.Size = v end
	)
	UIRegistry.Extras_Crosshair_Gap = crossSec:AddSlider(
		"Crosshair Gap",
		FeatureConfig.Extras.Crosshair.Gap,
		SETTINGS.RANGES.CROSSHAIR_GAP.MIN,
		SETTINGS.RANGES.CROSSHAIR_GAP.MAX,
		function(v) FeatureConfig.Extras.Crosshair.Gap = v end
	)
	UIRegistry.Extras_Crosshair_Thickness = crossSec:AddSlider(
		"Crosshair Thickness",
		FeatureConfig.Extras.Crosshair.Thickness,
		SETTINGS.RANGES.CROSSHAIR_THICKNESS.MIN,
		SETTINGS.RANGES.CROSSHAIR_THICKNESS.MAX,
		function(v) FeatureConfig.Extras.Crosshair.Thickness = v end
	)
	UIRegistry.Extras_Crosshair_Color = crossSec:AddColorPicker("Crosshair Color", FeatureConfig.Extras.Crosshair.Color, function(c)
		FeatureConfig.Extras.Crosshair.Color = c
	end)

	local lightSec = visualsTab:AddSection("World Lighting")
	UIRegistry.Visuals_Fullbright = lightSec:AddToggle("Enable Fullbright", false, function(v)
		FeatureConfig.Visuals.Fullbright = v
		if not v and DefaultLighting then
			Lighting.Ambient = DefaultLighting.Ambient
			Lighting.OutdoorAmbient = DefaultLighting.OutdoorAmbient
			Lighting.Brightness = DefaultLighting.Brightness
			Lighting.GlobalShadows = DefaultLighting.GlobalShadows
		end
	end)
	lightSec:AddSlider("Time of Day", math.floor(Lighting.ClockTime), SETTINGS.RANGES.LIGHTING_CLOCK.MIN, SETTINGS.RANGES.LIGHTING_CLOCK.MAX, function(v)
		Lighting.ClockTime = v
	end)
	lightSec:AddButton("Reset World Lighting", function()
		if DefaultLighting then
			for k, v in pairs(DefaultLighting) do
				pcall(function() Lighting[k] = v end)
			end
		end
		safeNotify("Lighting", "Reset", nil, Theme.Success)
	end)

	local visEffectsSec = visualsTab:AddSection("Visual Effects")
	UIRegistry.Extras_SpeedLines = visEffectsSec:AddToggle("Draw Speed Lines", false, function(v)
		FeatureConfig.Extras.SpeedLines = v
	end)
	UIRegistry.Extras_Wallbang = visEffectsSec:AddToggle("Transparent Materials", false, function(v)
		FeatureConfig.Extras.Wallbang = v
		local myChar = Utils.GetCharacter and Utils.GetCharacter()
		for _, obj in ipairs(Workspace:GetDescendants()) do
			if obj:IsA("BasePart") and (not myChar or not obj:IsDescendantOf(myChar)) then
				if v then
					if not obj:GetAttribute("B0XazOrigT") then
						obj:SetAttribute("B0XazOrigT", obj.Transparency)
					end
					obj.Transparency = math.max(obj.Transparency, SETTINGS.LIMITS.WALLBANG_TRANSPARENCY)
				else
					local original = obj:GetAttribute("B0XazOrigT")
					if original ~= nil then
						obj.Transparency = original
						obj:SetAttribute("B0XazOrigT", nil)
					end
				end
			end
		end
	end)

	local moveTab = UI:AddTab("Movement", 1)
	local charSec = moveTab:AddSection("Character Speed & Jump")

	UIRegistry.Movement_Speed = charSec:AddSlider(
		"Walk Speed",
		FeatureConfig.Movement.Speed,
		SETTINGS.RANGES.WALK_SPEED.MIN,
		SETTINGS.RANGES.WALK_SPEED.MAX,
		function(v)
			FeatureConfig.Movement.Speed = v
			local hum = Utils.GetHumanoid and Utils.GetHumanoid()
			if hum then hum.WalkSpeed = v end
		end,
		" ws"
	)
	UIRegistry.Movement_JumpPower = charSec:AddSlider(
		"Jump Power",
		FeatureConfig.Movement.JumpPower,
		SETTINGS.RANGES.JUMP_POWER.MIN,
		SETTINGS.RANGES.JUMP_POWER.MAX,
		function(v)
			FeatureConfig.Movement.JumpPower = v
			local hum = Utils.GetHumanoid and Utils.GetHumanoid()
			if hum then
				hum.UseJumpPower = true
				hum.JumpPower = v
			end
		end,
		" jp"
	)
	UIRegistry.Movement_SprintEnabled = charSec:AddToggle("Enable Shift-Sprint", FeatureConfig.Movement.SprintEnabled, function(v)
		FeatureConfig.Movement.SprintEnabled = v
		if not v then
			local hum = Utils.GetHumanoid and Utils.GetHumanoid()
			if hum then hum.WalkSpeed = FeatureConfig.Movement.Speed end
		end
	end)
	UIRegistry.Movement_SprintSpeed = charSec:AddSlider(
		"Sprint Walk Speed",
		FeatureConfig.Movement.SprintSpeed or 30,
		SETTINGS.RANGES.SPRINT_SPEED.MIN,
		SETTINGS.RANGES.SPRINT_SPEED.MAX,
		function(v) FeatureConfig.Movement.SprintSpeed = v end,
		" ws"
	)
	UIRegistry.Movement_InfJump = charSec:AddToggle("Infinite Air Jump", FeatureConfig.Movement.InfJump, function(v)
		FeatureConfig.Movement.InfJump = v
	end)
	UIRegistry.Movement_CFrameSpeed = charSec:AddToggle("CFrame Teleport Move", FeatureConfig.Movement.CFrameSpeed, function(v)
		FeatureConfig.Movement.CFrameSpeed = v
	end)
	UIRegistry.Movement_CFrameSpeedValue = charSec:AddSlider(
		"CFrame Velocity Speed",
		FeatureConfig.Movement.CFrameSpeedValue or 50,
		SETTINGS.RANGES.CFRAME_SPEED.MIN,
		SETTINGS.RANGES.CFRAME_SPEED.MAX,
		function(v) FeatureConfig.Movement.CFrameSpeedValue = v end,
		" sps"
	)
	UIRegistry.Movement_Bhop = charSec:AddToggle("Bunny Hop (AutoJump)", FeatureConfig.Movement.Bhop, function(v)
		FeatureConfig.Movement.Bhop = v
	end)
	charSec:AddToggle("Freeze Anchor Position", false, function(v)
		local hum = Utils.GetHumanoid and Utils.GetHumanoid()
		local root = Utils.GetRootPart and Utils.GetRootPart()
		if hum then hum.PlatformStand = v end
		if root then root.Anchored = v end
	end)

	local flySec = moveTab:AddSection("Flight Configuration")
	UIRegistry.Movement_FlySpeed = flySec:AddSlider(
		"Fly Speed",
		FeatureConfig.Movement.FlySpeed,
		SETTINGS.RANGES.FLY_SPEED.MIN,
		SETTINGS.RANGES.FLY_SPEED.MAX,
		function(v) FeatureConfig.Movement.FlySpeed = v end
	)
	UIRegistry.Movement_FlyEnabled = flySec:AddToggle("Enable Fly Mode", FeatureConfig.Movement.FlyEnabled, function(v)
		if not FlySystem then return end
		if v then FlySystem.Start() else FlySystem.Stop() end
	end)
	if not isMobile then
		flySec:AddKeybind("Fly Hotkey", Enum.KeyCode.F, function()
			if not FlySystem then return end
			if FeatureConfig.Movement.FlyEnabled then FlySystem.Stop() else FlySystem.Start() end
		end)
	end

	local worldSec = moveTab:AddSection("World Adjustments")
	worldSec:AddSlider(
		"World Gravity",
		math.floor(Workspace.Gravity),
		SETTINGS.RANGES.GRAVITY.MIN,
		SETTINGS.RANGES.GRAVITY.MAX,
		function(v) Workspace.Gravity = v end
	)
	worldSec:AddSlider(
		"Humanoid Hip Height",
		0,
		SETTINGS.RANGES.HIP_HEIGHT.MIN,
		SETTINGS.RANGES.HIP_HEIGHT.MAX,
		function(v)
			local hum = Utils.GetHumanoid and Utils.GetHumanoid()
			if hum then hum.HipHeight = v + 2 end
		end
	)
	UIRegistry.Camera_FOV = worldSec:AddSlider(
		"Camera FOV Zoom",
		FeatureConfig.Camera.FOV,
		SETTINGS.RANGES.CAMERA_FOV.MIN,
		SETTINGS.RANGES.CAMERA_FOV.MAX,
		function(v) FeatureConfig.Camera.FOV = v end
	)
	worldSec:AddSlider(
		"Max Camera Zoom",
		400,
		SETTINGS.RANGES.MAX_CAMERA_ZOOM.MIN,
		SETTINGS.RANGES.MAX_CAMERA_ZOOM.MAX,
		function(v)
			if LocalPlayer then LocalPlayer.CameraMaxZoomDistance = v end
		end
	)

	local tpSec = moveTab:AddSection("Position Teleports")
	tpSec:AddButton("Save Current Position", function()
		local root = Utils.GetRootPart and Utils.GetRootPart()
		if not root then
			safeNotify("Position", "No character root found", nil, Theme.Danger)
			return
		end
		State.SavedPosition = root.CFrame
		safeNotify("Position", "Saved Current CFrame", nil, Theme.Success)
	end)
	tpSec:AddButton("Teleport to Saved", function()
		local root = Utils.GetRootPart and Utils.GetRootPart()
		if root and State.SavedPosition then
			root.CFrame = State.SavedPosition
			safeNotify("Position", "Teleported to CFrame", nil, Theme.Success)
		else
			safeNotify("Position", "No position saved", nil, Theme.Danger)
		end
	end)
	tpSec:AddToggle(isMobile and "Tap-to-Teleport" or "TP to Click (Ctrl+Click)", false, function(v)
		State.TpToMouse = v
	end)

	local playersTab = UI:AddTab("Players", 1)
	local plSelectSec = playersTab:AddSection("Target Selection")
	local plActionsSec = playersTab:AddSection("Actions")
	local plStatusSec = playersTab:AddSection("States")

	local selectedName = nil
	local playerDropdown = nil
	local includeSelf = false

	local function getUpdatedPlayerList()
		local list = (Utils.GetPlayerNameList and Utils.GetPlayerNameList(not includeSelf)) or {}
		return #list == 0 and { "No Players Found" } or list
	end

	local function onPlayerSelected(v)
		selectedName = (v == "No Players Found" or v == "None" or v == "") and nil or v
		State.SelectedPlayer = selectedName
	end

	local initialList = getUpdatedPlayerList()
	selectedName = (initialList[1] ~= "No Players Found") and initialList[1] or nil
	State.SelectedPlayer = selectedName

	playerDropdown = plSelectSec:AddDropdown("Select Player", initialList, onPlayerSelected, selectedName or "No Players Found")

	local function refreshPlayerList()
		local now = os.clock()
		if (now - lastPlayerRefreshTime) < SETTINGS.LIMITS.REFRESH_PLAYERS_COOLDOWN then return end
		lastPlayerRefreshTime = now

		local list = getUpdatedPlayerList()
		if playerDropdown then
			playerDropdown.Refresh(list, true)
			onPlayerSelected(playerDropdown.Get())
		end
	end

	plSelectSec:AddToggle("Include Self in Target List", includeSelf, function(v)
		includeSelf = v
		refreshPlayerList()
	end)
	plSelectSec:AddButton("Refresh Player Target List", function()
		refreshPlayerList()
		safeNotify("Players", "List refreshed", nil, Theme.Accent)
	end)

	if Connections and Connections.Add then
		Connections.Add(Players.PlayerAdded:Connect(function()
			task.wait(SETTINGS.LIMITS.REFRESH_PLAYERS_COOLDOWN)
			refreshPlayerList()
		end))
		Connections.Add(Players.PlayerRemoving:Connect(function()
			task.wait(0.2)
			refreshPlayerList()
		end))
	end

	plActionsSec:AddButton("Teleport to Target", function()
		if not selectedName or selectedName == "No Players Found" or not PlayersSystem then
			safeNotify("Players", "Select a valid player target", nil, Theme.Danger)
			return
		end
		local ok, err = PlayersSystem.TeleportTo(selectedName)
		safeNotify("Players", ok and ("Teleported to " .. selectedName) or (err or "Failed"), nil, ok and Theme.Success or Theme.Danger)
	end)

	plActionsSec:AddButton("Spectate Target View", function()
		if not selectedName or selectedName == "No Players Found" or not PlayersSystem then
			safeNotify("Players", "Select a valid player target", nil, Theme.Danger)
			return
		end
		local ok, err = PlayersSystem.StartSpectate(selectedName)
		safeNotify("Players", ok and ("Spectating " .. selectedName) or (err or "Failed"), nil, ok and Theme.Success or Theme.Danger)
	end)

	plActionsSec:AddButton("Stop Camera Spectate", function()
		if PlayersSystem then
			PlayersSystem.StopSpectate()
			safeNotify("Players", "Stopped spectating", nil, Theme.Accent)
		end
	end)

	plActionsSec:AddButton("Copy Player Exact Name", function()
		if not selectedName or selectedName == "No Players Found" then
			safeNotify("Players", "Select a valid player target", nil, Theme.Danger)
			return
		end
		safeSetClipboard(selectedName)
		safeNotify("Players", "Copied: " .. selectedName, nil, Theme.Accent)
	end)

	plActionsSec:AddButton("Fling Attack Player", function()
		if not selectedName or selectedName == "No Players Found" or not PlayersSystem then
			safeNotify("Players", "Select a valid player target", nil, Theme.Danger)
			return
		end
		local ok, err = PlayersSystem.StartFling(selectedName)
		safeNotify("Players", ok and ("Flinging " .. selectedName) or (err or "Failed"), nil, ok and Theme.Warning or Theme.Danger)
	end, 3)

	plActionsSec:AddButton("Stop Fling Attack", function()
		if PlayersSystem then
			PlayersSystem.StopFling()
			safeNotify("Players", "Stopped flinging", nil, Theme.Accent)
		end
	end, 3)

	local spectateStatusBtn = plStatusSec:AddButton("Spectating Target: None", function()
		if PlayersSystem then PlayersSystem.StopSpectate() end
	end)
	local flingStatusBtn = plStatusSec:AddButton("Fling Target: None", function()
		if PlayersSystem then PlayersSystem.StopFling() end
	end, 3)

	local statusMonitorThread = task.spawn(function()
		while UI and UI.Main and UI.Main.Parent do
			if PlayersSystem then
				local spec = PlayersSystem.GetSpectating()
				local fling = PlayersSystem.GetFlingTarget()
				if spectateStatusBtn then
					pcall(function()
						spectateStatusBtn.Text = "Spectating Target: " .. (spec and spec.Name or "None") .. " (click to stop)"
					end)
				end
				if flingStatusBtn then
					pcall(function()
						flingStatusBtn.Text = "Fling Target: " .. (fling and fling.Name or "None") .. " (click to stop)"
					end)
				end
			end
			task.wait(SETTINGS.LIMITS.STATUS_POLL_INTERVAL)
		end
	end)
	if Connections and Connections.Track then
		Connections.Track(statusMonitorThread)
	end

	local gameTab = UI:AddTab("Game", 3)
	local gameLoader = Context and Context.GameLoader

	local infoSec = gameTab:AddSection("Target Context")
	infoSec:AddButton("Game PlaceId: " .. tostring(game.PlaceId), function()
		safeSetClipboard(tostring(game.PlaceId))
		safeNotify("Game", "PlaceId copied to clipboard", nil, Theme.Accent)
	end)
	infoSec:AddButton("Map Module: " .. (gameLoader and gameLoader.GetDisplayName and gameLoader.GetDisplayName() or "Universal"), function() end)

	if gameLoader and gameLoader.IsSupported and gameLoader.IsSupported() then
		local ok, err = gameLoader.BuildUI(gameTab)
		if not ok then
			local errSec = gameTab:AddSection("Module Load Exception")
			errSec:AddButton("Fail Details - Click to Expand", function()
				safeNotify("Module Exception", tostring(err), 8, Theme.Danger)
			end)
		end
	else
		local unsup = gameTab:AddSection("Map Unsupported")
		unsup:AddButton("No custom game modifications found.", function()
			safeNotify("Game", "Universal hub features remain active.", nil, Theme.Warning)
		end)
	end

	local utilityTab = UI:AddTab("Utility", 1)

	local gpuSec = utilityTab:AddSection("Performance GPU Boosters")
	UIRegistry.Perf_NoTextures = gpuSec:AddToggle("Remove Textures & Decals", FeatureConfig.Performance.NoTextures, function(v)
		if PerfSystem then PerfSystem.SetNoTextures(v) end
	end)
	UIRegistry.Perf_LowMaterials = gpuSec:AddToggle("Force Flat Smooth Plastic", FeatureConfig.Performance.LowMaterials, function(v)
		if PerfSystem then PerfSystem.SetLowMaterials(v) end
	end)
	UIRegistry.Perf_OptimizeTerrain = gpuSec:AddToggle("Reduce 3D Material Details", FeatureConfig.Performance.OptimizeTerrain, function(v)
		if PerfSystem then PerfSystem.SetOptimizeTerrain(v) end
	end)
	UIRegistry.Perf_NoPostProcessing = gpuSec:AddToggle("Disable Post Processing Effects", FeatureConfig.Performance.NoPostProcessing, function(v)
		if PerfSystem then PerfSystem.SetNoPostProcessing(v) end
	end)

	local fxSec = utilityTab:AddSection("Lighting & Particles")
	UIRegistry.Perf_NoShadows = fxSec:AddToggle("Disable Light Shadows", FeatureConfig.Performance.NoShadows, function(v)
		if PerfSystem then PerfSystem.SetNoShadows(v) end
	end)
	UIRegistry.Perf_NoParticles = fxSec:AddToggle("Disable Particle Emitters", FeatureConfig.Performance.NoParticles, function(v)
		if PerfSystem then PerfSystem.SetNoParticles(v) end
	end)

	local fpsSec = utilityTab:AddSection("Target Framerate Limit")
	fpsSec:AddButton("Unlock Target Frame Cap (999)", function()
		safeSetFpsCap(SETTINGS.LIMITS.MAX_FPS_UNLOCK)
		safeNotify("Utility", "FPS Cap Unlocked", nil, Theme.Success)
	end)
	fpsSec:AddButton("Cap Target Limit to 60 FPS", function()
		safeSetFpsCap(SETTINGS.LIMITS.FPS_60)
		safeNotify("Utility", "60 FPS Cap Active", nil, Theme.Warning)
	end)
	fpsSec:AddButton("Cap Target Limit to 144 FPS", function()
		safeSetFpsCap(SETTINGS.LIMITS.FPS_144)
		safeNotify("Utility", "144 FPS Cap Active", nil, Theme.Success)
	end)

	local hitSec = utilityTab:AddSection("Hitbox Customizations")
	UIRegistry.Extras_Hitbox_Enabled = hitSec:AddToggle("Expand Character Hitboxes", false, function(v)
		FeatureConfig.Extras.Hitbox.Enabled = v
		if not v and Context.ResetHitboxes then Context.ResetHitboxes() end
	end)
	UIRegistry.Extras_Hitbox_Size = hitSec:AddSlider(
		"Hitbox Size Radius",
		FeatureConfig.Extras.Hitbox.Size,
		SETTINGS.RANGES.HITBOX_SIZE.MIN,
		SETTINGS.RANGES.HITBOX_SIZE.MAX,
		function(v) FeatureConfig.Extras.Hitbox.Size = v end
	)

	local spinSec = utilityTab:AddSection("Spin Bot System")
	UIRegistry.Extras_SpinBot_Enabled = spinSec:AddToggle("Enable Character Spin Bot", false, function(v)
		FeatureConfig.Extras.SpinBot.Enabled = v
	end)
	UIRegistry.Extras_SpinBot_Speed = spinSec:AddSlider(
		"Spin Velocity Speed",
		FeatureConfig.Extras.SpinBot.Speed,
		SETTINGS.RANGES.SPIN_SPEED.MIN,
		SETTINGS.RANGES.SPIN_SPEED.MAX,
		function(v) FeatureConfig.Extras.SpinBot.Speed = v end
	)

	local statSec = utilityTab:AddSection("On-Screen Statistics")
	statSec:AddToggle("Display FPS Counter", false, function(v)
		StatsConfig.ShowFPS = v
		if OverlayManager and OverlayManager.FPSLabel then
			OverlayManager.FPSLabel.Visible = v
		end
	end)
	statSec:AddToggle("Display Ping Monitor", false, function(v)
		StatsConfig.ShowPing = v
		if OverlayManager and OverlayManager.PingLabel then
			OverlayManager.PingLabel.Visible = v
		end
	end)

	local serverSec = utilityTab:AddSection("Anti-Idle & Server Manager")
	serverSec:AddToggle("Enable Anti-AFK Connection", false, function(v)
		if v and Connections and Connections.Add and LocalPlayer then
			Connections.Add(LocalPlayer.Idled:Connect(function()
				pcall(function()
					VirtualUser:CaptureController()
					VirtualUser:ClickButton2(Vector2.zero)
				end)
			end))
			safeNotify("Anti-AFK", "Connection lock engaged", nil, Theme.Success)
		end
	end)

	serverSec:AddToggle("Auto Rejoin on Kick Exception", false, function(v)
		if v and Connections and Connections.Add and LocalPlayer then
			Connections.Add(LocalPlayer.Kicked:Connect(function()
				if Utils.PrepareTeleport then Utils.PrepareTeleport() end
				task.wait(SETTINGS.LIMITS.REJOIN_WAIT)
				pcall(function()
					TeleportService:Teleport(game.PlaceId, LocalPlayer)
				end)
			end))
			safeNotify("Auto Rejoin", "Engaged", nil, Theme.Success)
		end
	end)

	serverSec:AddButton("Server Hop (Public Lobby)", function()
		local now = os.clock()
		if (now - lastServerHopTime) < SETTINGS.LIMITS.SERVER_HOP_COOLDOWN then
			safeNotify("Server Hop", "Please wait before hopping again", nil, Theme.Warning)
			return
		end
		lastServerHopTime = now
		safeNotify("Server Hop", "Fetching open instances...", nil, Theme.Accent)

		task.spawn(function()
			local ok, rawResponse = pcall(function()
				local url = string.format(SETTINGS.URLS.ROBLOX_SERVERS, tostring(game.PlaceId))
				return game:HttpGet(url)
			end)
			if not ok or not rawResponse then
				safeNotify("Server Hop", "Failed to retrieve servers", nil, Theme.Danger)
				return
			end

			local decodeOk, serverData = pcall(function()
				return HttpService:JSONEncode(rawResponse)
			end)
			if not decodeOk or not serverData or not serverData.data then
				safeNotify("Server Hop", "Invalid response from server api", nil, Theme.Danger)
				return
			end

			for _, server in ipairs(serverData.data) do
				if server.id ~= game.JobId and server.playing and server.maxPlayers and server.playing < server.maxPlayers then
					if Utils.PrepareTeleport then Utils.PrepareTeleport() end
					pcall(function()
						TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
					end)
					return
				end
			end
			safeNotify("Server Hop", "No open servers detected", nil, Theme.Danger)
		end)
	end)

	local settingsTab = UI:AddTab("Settings", 1)
	local cfgSec = settingsTab:AddSection("Configuration Profile Manager")
	local cfgState = { Selected = SETTINGS.DEFAULT_CONFIG_NAME, Name = "MyConfig" }

	local function getCfgList()
		return (ConfigSystem and ConfigSystem.GetSavedNames and ConfigSystem.GetSavedNames()) or { SETTINGS.DEFAULT_CONFIG_NAME }
	end

	local cfgDropdown = cfgSec:AddDropdown("Select Saved Profile", getCfgList(), function(v)
		cfgState.Selected = (v ~= "None" and v ~= "") and v or SETTINGS.DEFAULT_CONFIG_NAME
	end, SETTINGS.DEFAULT_CONFIG_NAME)

	local function refreshConfigDropdown()
		local now = os.clock()
		if (now - lastConfigRefreshTime) < SETTINGS.LIMITS.REFRESH_CONFIGS_COOLDOWN then return end
		lastConfigRefreshTime = now

		if cfgDropdown then
			cfgDropdown.Refresh(getCfgList(), true)
		end
	end

	cfgSec:AddButton("Refresh Directory List", function()
		refreshConfigDropdown()
		safeNotify("Configs", "Refreshed list directory", nil, Theme.Accent)
	end)

	cfgSec:AddTextbox("Custom Config Name", cfgState.Name, function(t)
		if type(t) == "string" and #t > 0 then
			cfgState.Name = Utils.SanitizeFileName and Utils.SanitizeFileName(t) or t
		end
	end, "Profile Name")

	cfgSec:AddButton("Save Current Profile", function()
		local sanitized = Utils.SanitizeFileName and Utils.SanitizeFileName(cfgState.Name or "") or (cfgState.Name or "")
		if #sanitized == 0 then
			safeNotify("Config", "Enter a configuration file name", nil, Theme.Danger)
			return
		end
		if sanitized:lower() == SETTINGS.DEFAULT_CONFIG_NAME:lower() then
			safeNotify("Config", "Cannot write default layout", nil, Theme.Warning)
			return
		end
		if not ConfigSystem then return end
		local ok, err = ConfigSystem.Save(sanitized)
		if ok then
			refreshConfigDropdown()
			safeNotify("Saved Profile", sanitized, nil, Theme.Success)
		else
			safeNotify("Write Failed", tostring(err), nil, Theme.Danger)
		end
	end)

	cfgSec:AddButton("Load Selected Profile", function()
		if not cfgState.Selected or not ConfigSystem then
			safeNotify("Config", "Select file first", nil, Theme.Danger)
			return
		end
		local ok, err = ConfigSystem.Load(cfgState.Selected)
		if ok then
			safeNotify("Loaded Profile", cfgState.Selected, nil, Theme.Success)
		else
			safeNotify("Load Failed", tostring(err), nil, Theme.Danger)
		end
	end)

	cfgSec:AddButton("Delete Selected Profile", function()
		if not cfgState.Selected or not ConfigSystem then
			safeNotify("Config", "Select file first", nil, Theme.Danger)
			return
		end
		if cfgState.Selected == SETTINGS.DEFAULT_CONFIG_NAME then
			safeNotify("Config", "Default profiles cannot be deleted", nil, Theme.Warning)
			return
		end
		local ok, err = ConfigSystem.Delete(cfgState.Selected)
		if ok then
			cfgState.Selected = SETTINGS.DEFAULT_CONFIG_NAME
			if cfgDropdown then
				cfgDropdown.Refresh(getCfgList())
				cfgDropdown.Set(SETTINGS.DEFAULT_CONFIG_NAME, true)
			end
			safeNotify("Deleted Profile", "Configuration deleted", nil, Theme.Success)
		else
			safeNotify("Deletion Failed", tostring(err), nil, Theme.Danger)
		end
	end)

	local cfgIO = settingsTab:AddSection("Import & Export Profiles")
	local rawImportString = ""

	cfgIO:AddButton("Copy Config layout to Clipboard", function()
		if not ConfigSystem then return end
		local ok, encoded = pcall(function()
			return HttpService:JSONEncode(ConfigSystem.Serialize())
		end)
		if ok then
			if safeSetClipboard(encoded) then
				safeNotify("Export Profile", "Layout written to clipboard", nil, Theme.Success)
			else
				safeNotify("Export Profile", "Clipboard support missing", nil, Theme.Danger)
			end
		else
			safeNotify("Export Profile", "Encoding serialization fail", nil, Theme.Danger)
		end
	end)

	cfgIO:AddTextbox("Paste Layout Data Here", "", function(v)
		rawImportString = v
	end, "JSON Layout Code String")

	cfgIO:AddButton("Import Layout from Textbox", function()
		if not rawImportString or #rawImportString == 0 or not ConfigSystem then
			safeNotify("Import Profile", "Paste profile code string", nil, Theme.Danger)
			return
		end
		local ok, data = pcall(function()
			return HttpService:JSONDecode(rawImportString)
		end)
		if ok and type(data) == "table" then
			ConfigSystem.Deserialize(data)
			ConfigSystem.UpdateUI()
			local rawName = cfgState.Name or SETTINGS.DEFAULT_IMPORT_NAME
			local saveName = Utils.SanitizeFileName and Utils.SanitizeFileName(rawName) or rawName
			if #saveName == 0 or saveName:lower() == SETTINGS.DEFAULT_CONFIG_NAME:lower() then
				saveName = SETTINGS.DEFAULT_IMPORT_NAME
			end
			local saved, saveErr = ConfigSystem.Save(saveName)
			if saved then
				refreshConfigDropdown()
				safeNotify("Import Profile", "Applied Layout & Saved as: " .. saveName, nil, Theme.Success)
			else
				safeNotify("Import Profile", "Applied, Save failed: " .. tostring(saveErr), nil, Theme.Warning)
			end
		else
			safeNotify("Import Profile", "Invalid Layout data string format", nil, Theme.Danger)
		end
	end)

	local themePresetsSec = settingsTab:AddSection("Visual Themes")
	local themeCustomSec = settingsTab:AddSection("Theme Adjustments")

	local presetNames = {}
	if ThemeManager and ThemeManager.Presets then
		for name in pairs(ThemeManager.Presets) do
			table.insert(presetNames, name)
		end
		table.sort(presetNames)
	end
	if #presetNames == 0 then
		table.insert(presetNames, SETTINGS.DEFAULT_PRESET)
	end

	themePresetsSec:AddDropdown("Choose Color Preset", presetNames, function(v)
		if ThemeManager and ThemeManager.Presets and ThemeManager.Presets[v] then
			local preset = ThemeManager.Presets[v]
			ThemeManager.ActivePreset = v
			UI:SetTheme(preset)
			updateCustomPickers(preset)
			safeNotify("Themes", "Theme preset applied: " .. v, nil, Theme.Success)
		end
	end, (ThemeManager and ThemeManager.ActivePreset) or SETTINGS.DEFAULT_PRESET)

	for _, themeKey in ipairs(SETTINGS.THEME_KEYS) do
		local registryName = "Theme_" .. themeKey
		UIRegistry[registryName] = themeCustomSec:AddColorPicker(themeKey, Theme[themeKey], function(c)
			UI:UpdateThemeKey(themeKey, c)
		end)
	end

	local keySec = settingsTab:AddSection("Account Keys")
	if KeySystem then
		keySec:AddButton("Current License: " .. KeySystem.GetTierName(), function() end)
		keySec:AddButton("Cached Key Token: " .. KeySystem.GetMaskedKey(), function()
			if KeySystem.CurrentKey ~= "" then
				safeSetClipboard(KeySystem.CurrentKey)
				safeNotify("Access Key", "Key written to clipboard", nil, Theme.Success)
			end
		end)

		local pendingKey = ""
		keySec:AddTextbox("Input Activation Key", "", function(v)
			pendingKey = v
		end, "License Token...")

		keySec:AddButton("Verify License Token", function()
			local ok, _, msg = KeySystem.ApplyKey(pendingKey)
			safeNotify(ok and "Verified" or "Invalid", msg or "", nil, ok and Theme.Success or Theme.Danger)
			if ok then
				safeNotify("License Upgrade", "Please restart client to load premium UI features", 5, Theme.Warning)
			end
		end)
		keySec:AddButton("Copy Direct Key Support Info", function()
			local ok, msg = KeySystem.CopyGetKeyLink()
			safeNotify("Key Info", msg, nil, ok and Theme.Success or Theme.Danger)
		end)
		keySec:AddButton("Clear License Token (Logout)", function()
			KeySystem.ClearKey()
			safeNotify("Logged out", "System profiles removed. Please restart.", nil, Theme.Warning)
		end)
	end

	do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 30)
		row.BackgroundTransparency = 1
		row.Parent = cfgSec.Frame

		local lbl = Instance.new("TextLabel")
		lbl.Text = "Menu Close Toggle Key"
		lbl.Font = Enum.Font.Code
		lbl.TextSize = 11
		lbl.TextColor3 = Theme.Text or Color3.fromRGB(255, 255, 255)
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.BackgroundTransparency = 1
		lbl.Position = UDim2.new(0, 8, 0, 0)
		lbl.Size = UDim2.new(1, -70, 1, 0)
		lbl.Parent = row
		UI:BindTheme(lbl, "TextColor3", "Text")

		local menuKeyBtn = Instance.new("TextButton")
		menuKeyBtn.Text = State.MenuKeybind and State.MenuKeybind.Name or "RightControl"
		menuKeyBtn.Font = Enum.Font.Code
		menuKeyBtn.TextSize = 10
		menuKeyBtn.TextColor3 = Theme.Text or Color3.fromRGB(255, 255, 255)
		menuKeyBtn.BackgroundColor3 = Theme.Elem or Color3.fromRGB(35, 35, 35)
		menuKeyBtn.BorderSizePixel = 0
		menuKeyBtn.Size = UDim2.new(0, 56, 0, 18)
		menuKeyBtn.Position = UDim2.new(1, -64, 0.5, -9)
		menuKeyBtn.AutoButtonColor = false
		menuKeyBtn.Parent = row
		UI:BindTheme(menuKeyBtn, "BackgroundColor3", "Elem")
		UI:BindTheme(menuKeyBtn, "TextColor3", "Text")

		table.insert(cfgSec.Elements, { Container = row, Name = "Menu Close Toggle Key" })

		menuKeyBtn.MouseButton1Click:Connect(function()
			isListeningForMenuKey = true
			menuKeyBtn.Text = "..."
			menuKeyBtn.TextColor3 = Theme.Accent or Color3.fromRGB(0, 200, 220)
		end)

		if Connections and Connections.Add then
			Connections.Add(UserInputService.InputBegan:Connect(function(input)
				if isListeningForMenuKey and input.UserInputType == Enum.UserInputType.Keyboard then
					if input.KeyCode ~= Enum.KeyCode.Escape then
						State.MenuKeybind = input.KeyCode
						menuKeyBtn.Text = input.KeyCode.Name
					else
						menuKeyBtn.Text = State.MenuKeybind and State.MenuKeybind.Name or "RightControl"
					end
					menuKeyBtn.TextColor3 = Theme.Text or Color3.fromRGB(255, 255, 255)
					isListeningForMenuKey = false
				end
			end))
		end
	end

	return UI
end
