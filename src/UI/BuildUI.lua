-- // src/UI/BuildUI.lua
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

	local Theme = Context.Theme or {}
	local ThemeManager = Context.ThemeManager
	local FeatureConfig = Context.FeatureConfig or {}
	local State = Context.State or {}
	local StatsConfig = Context.StatsConfig or {}
	local UIRegistry = Context.UIRegistry or {}
	local Utils = Context.Utils or {}
	local Connections = Context.Connections or {}
	local DefaultLighting = Context.DefaultLighting or {}

	local AimbotSystem = Context.AimbotSystem
	local ESPSystem = Context.ESPSystem
	local FlySystem = Context.FlySystem
	local ConfigSystem = Context.ConfigSystem
	local OverlayManager = Context.OverlayManager
	local PerfSystem = Context.PerformanceSystem
	local PlayersSystem = Context.PlayersSystem
	local KeySystem = Context.KeySystem

	local UI = Context.UIEngine.new("B0Xaz Universal")
	Context.UI = UI
	local env = (getgenv and getgenv()) or _G
	env.B0XazLibrary = UI

	local isListeningMenuKey = false
	local lastHop, lastPlRefresh, lastCfgRefresh = 0, 0, 0

	local function notify(title, msg, dur, color)
		if UI and UI.Notify then UI:Notify(title, msg, dur, color) end
	end

	local function setClip(text)
		if setclipboard then pcall(setclipboard, text) return true end
		return false
	end

	local function setFps(cap)
		if setfpscap then pcall(setfpscap, cap) end
	end

	local function updateCustomPickers(presetTheme)
		if type(presetTheme) ~= "table" then return end
		for k, v in pairs(presetTheme) do
			local rKey = "Theme_" .. k
			if UIRegistry[rKey] and type(UIRegistry[rKey].Set) == "function" then
				UIRegistry[rKey].Set(v, true)
			end
		end
	end

	if Connections and Connections.Add then
		Connections.Add(UserInputService.InputBegan:Connect(function(input, gp)
			if isListeningMenuKey or gp then return end
			if State.MenuKeybind and input.KeyCode == State.MenuKeybind then
				State.MenuVisible = not State.MenuVisible
				if UI.Main then UI.Main.Visible = State.MenuVisible end
			end
		end))
	end

	-- ============================================================
	-- COMBAT TAB
	-- ============================================================
	local combatTab = UI:AddTab("Combat", 3)
	local aimMain = combatTab:AddSection("Aimbot Controls")

	UIRegistry.Aimbot_Enabled = aimMain:AddToggle("Aimbot Enabled", FeatureConfig.Aimbot.Enabled, function(v)
		FeatureConfig.Aimbot.Enabled = v
		if not v and AimbotSystem then AimbotSystem.LockOff() end
	end)
	UIRegistry.Aimbot_Keybind = aimMain:AddKeybind("Activation Bind", FeatureConfig.Aimbot.Keybind, function(k)
		FeatureConfig.Aimbot.Keybind = k
		notify("Aimbot", "Bind updated", nil, Theme.Success)
	end)
	UIRegistry.Aimbot_LockMode = aimMain:AddDropdown("Lock Mode", { "Hold", "Toggle" }, function(v)
		FeatureConfig.Aimbot.LockMode = v
		if AimbotSystem then AimbotSystem.LockOff() end
	end, FeatureConfig.Aimbot.LockMode)
	UIRegistry.Aimbot_Hitpart = aimMain:AddDropdown("Hit Part", { "Head", "Torso", "Root", "LeftArm", "RightArm", "LeftLeg", "RightLeg" }, function(v)
		FeatureConfig.Aimbot.Hitpart = v
	end, FeatureConfig.Aimbot.Hitpart)
	UIRegistry.Aimbot_Smoothness = aimMain:AddSlider("Smoothness", FeatureConfig.Aimbot.Smoothness, 1, 20, function(v)
		FeatureConfig.Aimbot.Smoothness = v
	end)
	UIRegistry.Aimbot_ShakeIntensity = aimMain:AddSlider("Shake Intensity", FeatureConfig.Aimbot.ShakeIntensity, 0, 10, function(v)
		FeatureConfig.Aimbot.ShakeIntensity = v
	end)

	local aimCheck = combatTab:AddSection("Target Settings")
	UIRegistry.Aimbot_TeamCheck = aimCheck:AddToggle("Team Check", FeatureConfig.Aimbot.TeamCheck, function(v) FeatureConfig.Aimbot.TeamCheck = v end)
	UIRegistry.Aimbot_VisCheck = aimCheck:AddToggle("Visibility Check", FeatureConfig.Aimbot.VisCheck, function(v) FeatureConfig.Aimbot.VisCheck = v end)
	UIRegistry.Aimbot_UnlockOnDeath = aimCheck:AddToggle("Unlock On Death", FeatureConfig.Aimbot.UnlockOnDeath, function(v) FeatureConfig.Aimbot.UnlockOnDeath = v end)
	UIRegistry.Aimbot_BreakOnPull = aimCheck:AddToggle("Break on Mouse Pull", FeatureConfig.Aimbot.BreakOnPull, function(v) FeatureConfig.Aimbot.BreakOnPull = v end)
	UIRegistry.Aimbot_MaxLockRadius = aimCheck:AddSlider("Max Lock Radius", FeatureConfig.Aimbot.MaxLockRadius or 200, 50, 500, function(v) FeatureConfig.Aimbot.MaxLockRadius = v end, " px")
	UIRegistry.Aimbot_MaxDistance = aimCheck:AddSlider("Max Distance", FeatureConfig.Aimbot.MaxDistance, 50, 2000, function(v) FeatureConfig.Aimbot.MaxDistance = v end, " studs")

	local aimFov = combatTab:AddSection("Aimbot FOV")
	UIRegistry.Aimbot_FOV_Show = aimFov:AddToggle("Show FOV Circle", FeatureConfig.Aimbot.FOV.Show, function(v) FeatureConfig.Aimbot.FOV.Show = v end)
	UIRegistry.Aimbot_FOV_Filled = aimFov:AddToggle("Filled Circle", FeatureConfig.Aimbot.FOV.Filled, function(v) FeatureConfig.Aimbot.FOV.Filled = v end)
	UIRegistry.Aimbot_FOV_Rainbow = aimFov:AddToggle("Rainbow FOV", FeatureConfig.Aimbot.FOV.Rainbow, function(v) FeatureConfig.Aimbot.FOV.Rainbow = v end)
	UIRegistry.Aimbot_FOV_Size = aimFov:AddSlider("FOV Radius", FeatureConfig.Aimbot.FOV.Size, 10, 600, function(v) FeatureConfig.Aimbot.FOV.Size = v end, " px")
	UIRegistry.Aimbot_FOV_Thickness = aimFov:AddSlider("Line Thickness", FeatureConfig.Aimbot.FOV.Thickness, 1, 10, function(v) FeatureConfig.Aimbot.FOV.Thickness = v end)

	local aimPred = combatTab:AddSection("Prediction & Triggerbot")
	UIRegistry.Aimbot_Prediction_Horizontal = aimPred:AddSlider("Horizontal Prediction", math.floor((FeatureConfig.Aimbot.Prediction.Horizontal or 0) * 200), 0, 100, function(v) FeatureConfig.Aimbot.Prediction.Horizontal = v / 200 end)
	UIRegistry.Aimbot_Prediction_Vertical = aimPred:AddSlider("Vertical Prediction", math.floor((FeatureConfig.Aimbot.Prediction.Vertical or 0) * 200), 0, 100, function(v) FeatureConfig.Aimbot.Prediction.Vertical = v / 200 end)
	aimPred:AddButton("Reset Prediction", function()
		FeatureConfig.Aimbot.Prediction.Horizontal = 0
		FeatureConfig.Aimbot.Prediction.Vertical = 0
		if UIRegistry.Aimbot_Prediction_Horizontal then UIRegistry.Aimbot_Prediction_Horizontal.Set(0, true) end
		if UIRegistry.Aimbot_Prediction_Vertical then UIRegistry.Aimbot_Prediction_Vertical.Set(0, true) end
		notify("Prediction", "Reset to zero", nil, Theme.Success)
	end)
	UIRegistry.Aimbot_Triggerbot_Enabled = aimPred:AddToggle("Enable Triggerbot", FeatureConfig.Aimbot.Triggerbot.Enabled, function(v) FeatureConfig.Aimbot.Triggerbot.Enabled = v end)
	UIRegistry.Aimbot_Triggerbot_Delay = aimPred:AddSlider("Trigger Delay", math.floor((FeatureConfig.Aimbot.Triggerbot.Delay or 0) * 100), 0, 50, function(v) FeatureConfig.Aimbot.Triggerbot.Delay = v / 100 end, " ms")

	-- ============================================================
	-- VISUALS TAB
	-- ============================================================
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
	UIRegistry.ESP_MaxDist = espSet:AddSlider("Max Distance", FeatureConfig.ESP.MaxDist, 100, 2000, function(v) FeatureConfig.ESP.MaxDist = v end, " studs")
	UIRegistry.ESP_Color = espSet:AddColorPicker("ESP Global Color", FeatureConfig.ESP.Color, function(c) FeatureConfig.ESP.Color = c end)

	local chamsSec = visualsTab:AddSection("Player Chams")
	UIRegistry.ESP_Chams_Enabled = chamsSec:AddToggle("Enable Highlights", FeatureConfig.Chams.Enabled, function(v)
		FeatureConfig.Chams.Enabled = v
		if not ESPSystem then return end
		if v then
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= LocalPlayer and Utils.IsAlive and Utils.IsAlive(p) then
					ESPSystem.RemoveHighlight(p)
					ESPSystem.AddHighlight(p)
				end
			end
		else
			for _, p in ipairs(Players:GetPlayers()) do ESPSystem.RemoveHighlight(p) end
		end
	end)
	UIRegistry.ESP_Chams_FillColor = chamsSec:AddColorPicker("Chams Fill Color", FeatureConfig.Chams.FillColor, function(c) FeatureConfig.Chams.FillColor = c end)
	UIRegistry.ESP_Chams_OutlineColor = chamsSec:AddColorPicker("Chams Outline Color", FeatureConfig.Chams.OutlineColor, function(c) FeatureConfig.Chams.OutlineColor = c end)

	local crossSec = visualsTab:AddSection("Custom Crosshair")
	UIRegistry.Extras_Crosshair_Visible = crossSec:AddToggle("Display Crosshair", false, function(v) FeatureConfig.Extras.Crosshair.Visible = v end)
	UIRegistry.Extras_Crosshair_Size = crossSec:AddSlider("Crosshair Size", FeatureConfig.Extras.Crosshair.Size, 4, 40, function(v) FeatureConfig.Extras.Crosshair.Size = v end)
	UIRegistry.Extras_Crosshair_Gap = crossSec:AddSlider("Crosshair Gap", FeatureConfig.Extras.Crosshair.Gap, 0, 20, function(v) FeatureConfig.Extras.Crosshair.Gap = v end)
	UIRegistry.Extras_Crosshair_Thickness = crossSec:AddSlider("Crosshair Thickness", FeatureConfig.Extras.Crosshair.Thickness, 1, 6, function(v) FeatureConfig.Extras.Crosshair.Thickness = v end)
	UIRegistry.Extras_Crosshair_Color = crossSec:AddColorPicker("Crosshair Color", FeatureConfig.Extras.Crosshair.Color, function(c) FeatureConfig.Extras.Crosshair.Color = c end)

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
	lightSec:AddSlider("Time of Day", math.floor(Lighting.ClockTime), 0, 24, function(v) Lighting.ClockTime = v end)
	lightSec:AddButton("Reset World Lighting", function()
		if DefaultLighting then
			for k, v in pairs(DefaultLighting) do pcall(function() Lighting[k] = v end) end
		end
		notify("Lighting", "Reset", nil, Theme.Success)
	end)

	local visEffectsSec = visualsTab:AddSection("Visual Effects")
	UIRegistry.Extras_SpeedLines = visEffectsSec:AddToggle("Draw Speed Lines", false, function(v) FeatureConfig.Extras.SpeedLines = v end)
	UIRegistry.Extras_Wallbang = visEffectsSec:AddToggle("Transparent Materials", false, function(v)
		FeatureConfig.Extras.Wallbang = v
		local myChar = Utils.GetCharacter and Utils.GetCharacter()
		for _, obj in ipairs(Workspace:GetDescendants()) do
			if obj:IsA("BasePart") and (not myChar or not obj:IsDescendantOf(myChar)) then
				if v then
					if not obj:GetAttribute("B0XazOrigT") then obj:SetAttribute("B0XazOrigT", obj.Transparency) end
					obj.Transparency = math.max(obj.Transparency, 0.85)
				else
					local orig = obj:GetAttribute("B0XazOrigT")
					if orig ~= nil then obj.Transparency = orig obj:SetAttribute("B0XazOrigT", nil) end
				end
			end
		end
	end)

	-- ============================================================
	-- MOVEMENT TAB
	-- ============================================================
	local moveTab = UI:AddTab("Movement", 1)
	local charSec = moveTab:AddSection("Speed & Jump")

	UIRegistry.Movement_Speed = charSec:AddSlider("Walk Speed", FeatureConfig.Movement.Speed, 16, 500, function(v)
		FeatureConfig.Movement.Speed = v
		local hum = Utils.GetHumanoid and Utils.GetHumanoid()
		if hum then hum.WalkSpeed = v end
	end, " ws")
	UIRegistry.Movement_JumpPower = charSec:AddSlider("Jump Power", FeatureConfig.Movement.JumpPower, 50, 500, function(v)
		FeatureConfig.Movement.JumpPower = v
		local hum = Utils.GetHumanoid and Utils.GetHumanoid()
		if hum then hum.UseJumpPower = true hum.JumpPower = v end
	end, " jp")
	UIRegistry.Movement_SprintEnabled = charSec:AddToggle("Shift Sprint", FeatureConfig.Movement.SprintEnabled, function(v)
		FeatureConfig.Movement.SprintEnabled = v
		if not v then
			local hum = Utils.GetHumanoid and Utils.GetHumanoid()
			if hum then hum.WalkSpeed = FeatureConfig.Movement.Speed end
		end
	end)
	UIRegistry.Movement_SprintSpeed = charSec:AddSlider("Sprint Speed", FeatureConfig.Movement.SprintSpeed or 30, 16, 500, function(v)
		FeatureConfig.Movement.SprintSpeed = v
	end, " ws")
	UIRegistry.Movement_InfJump = charSec:AddToggle("Infinite Air Jump", FeatureConfig.Movement.InfJump, function(v) FeatureConfig.Movement.InfJump = v end)
	UIRegistry.Movement_CFrameSpeed = charSec:AddToggle("CFrame Teleport Move", FeatureConfig.Movement.CFrameSpeed, function(v) FeatureConfig.Movement.CFrameSpeed = v end)
	UIRegistry.Movement_CFrameSpeedValue = charSec:AddSlider("CFrame Velocity Speed", FeatureConfig.Movement.CFrameSpeedValue or 50, 1, 500, function(v) FeatureConfig.Movement.CFrameSpeedValue = v end, " sps")
	UIRegistry.Movement_Bhop = charSec:AddToggle("Bunny Hop (AutoJump)", FeatureConfig.Movement.Bhop, function(v) FeatureConfig.Movement.Bhop = v end)

	local flySec = moveTab:AddSection("Flight Controls")
	UIRegistry.Movement_FlySpeed = flySec:AddSlider("Fly Speed", FeatureConfig.Movement.FlySpeed, 10, 500, function(v) FeatureConfig.Movement.FlySpeed = v end)
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
	worldSec:AddSlider("World Gravity", math.floor(Workspace.Gravity), 0, 300, function(v) Workspace.Gravity = v end)
	UIRegistry.Camera_FOV = worldSec:AddSlider("Camera FOV Zoom", FeatureConfig.Camera.FOV, 70, 120, function(v) FeatureConfig.Camera.FOV = v end)

	local tpSec = moveTab:AddSection("Position Teleports")
	tpSec:AddButton("Save Current Position", function()
		local root = Utils.GetRootPart and Utils.GetRootPart()
		if not root then notify("Position", "No root found", nil, Theme.Danger) return end
		State.SavedPosition = root.CFrame
		notify("Position", "Saved CFrame", nil, Theme.Success)
	end)
	tpSec:AddButton("Teleport to Saved", function()
		local root = Utils.GetRootPart and Utils.GetRootPart()
		if root and State.SavedPosition then
			root.CFrame = State.SavedPosition
			notify("Position", "Teleported to saved", nil, Theme.Success)
		else
			notify("Position", "No position saved", nil, Theme.Danger)
		end
	end)
	tpSec:AddToggle(isMobile and "Tap-to-Teleport" or "TP to Click (Ctrl+Click)", false, function(v) State.TpToMouse = v end)

	-- ============================================================
	-- PLAYERS TAB
	-- ============================================================
	local playersTab = UI:AddTab("Players", 1)
	local plSelectSec = playersTab:AddSection("Target Selection")
	local plActionsSec = playersTab:AddSection("Actions")

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
		if (now - lastPlRefresh) < 0.5 then return end
		lastPlRefresh = now
		local list = getUpdatedPlayerList()
		if playerDropdown then
			playerDropdown.Refresh(list, true)
			onPlayerSelected(playerDropdown.Get())
		end
	end

	plSelectSec:AddToggle("Include Self in List", includeSelf, function(v) includeSelf = v refreshPlayerList() end)
	plSelectSec:AddButton("Refresh Player List", function() refreshPlayerList() notify("Players", "List refreshed", nil, Theme.Accent) end)

	if Connections and Connections.Add then
		Connections.Add(Players.PlayerAdded:Connect(function() task.wait(0.5) refreshPlayerList() end))
		Connections.Add(Players.PlayerRemoving:Connect(function() task.wait(0.2) refreshPlayerList() end))
	end

	plActionsSec:AddButton("Teleport to Target", function()
		if not selectedName or not PlayersSystem then notify("Players", "Select a valid target", nil, Theme.Danger) return end
		local ok, err = PlayersSystem.TeleportTo(selectedName)
		notify("Players", ok and ("Teleported to " .. selectedName) or (err or "Failed"), nil, ok and Theme.Success or Theme.Danger)
	end)
	plActionsSec:AddButton("Spectate Target View", function()
		if not selectedName or not PlayersSystem then notify("Players", "Select a valid target", nil, Theme.Danger) return end
		local ok, err = PlayersSystem.StartSpectate(selectedName)
		notify("Players", ok and ("Spectating " .. selectedName) or (err or "Failed"), nil, ok and Theme.Success or Theme.Danger)
	end)
	plActionsSec:AddButton("Stop Camera Spectate", function()
		if PlayersSystem then PlayersSystem.StopSpectate() notify("Players", "Stopped spectating", nil, Theme.Accent) end
	end)
	plActionsSec:AddButton("Copy Exact Name", function()
		if not selectedName then notify("Players", "Select a valid target", nil, Theme.Danger) return end
		setClip(selectedName)
		notify("Players", "Copied: " .. selectedName, nil, Theme.Accent)
	end)
	plActionsSec:AddButton("Fling Attack Player", function()
		if not selectedName or not PlayersSystem then notify("Players", "Select a valid target", nil, Theme.Danger) return end
		local ok, err = PlayersSystem.StartFling(selectedName)
		notify("Players", ok and ("Flinging " .. selectedName) or (err or "Failed"), nil, ok and Theme.Warning or Theme.Danger)
	end, 3)
	plActionsSec:AddButton("Stop Fling Attack", function()
		if PlayersSystem then PlayersSystem.StopFling() notify("Players", "Stopped flinging", nil, Theme.Accent) end
	end, 3)

	-- ============================================================
	-- GAME TAB
	-- ============================================================
	local gameTab = UI:AddTab("Game", 3)
	local gameLoader = Context.GameLoader

	local infoSec = gameTab:AddSection("Target Context")
	infoSec:AddButton("PlaceId: " .. tostring(game.PlaceId), function()
		setClip(tostring(game.PlaceId))
		notify("Game", "PlaceId copied", nil, Theme.Accent)
	end)
	infoSec:AddButton("Module: " .. (gameLoader and gameLoader.GetDisplayName and gameLoader.GetDisplayName() or "Universal"), function() end)

	if gameLoader and gameLoader.IsSupported and gameLoader.IsSupported() then
		local ok, err = gameLoader.BuildUI(gameTab)
		if not ok then
			local errSec = gameTab:AddSection("Module Load Exception")
			errSec:AddButton("Details: " .. tostring(err), function() end)
		end
	else
		local unsup = gameTab:AddSection("Map Unsupported")
		unsup:AddButton("No game modifications found for this game.", function() end)
	end

	-- ============================================================
	-- UTILITY TAB
	-- ============================================================
	local utilityTab = UI:AddTab("Utility", 1)

	local gpuSec = utilityTab:AddSection("Performance Boosters")
	UIRegistry.Perf_NoTextures = gpuSec:AddToggle("Remove Textures & Decals", FeatureConfig.Performance.NoTextures, function(v)
		if PerfSystem then PerfSystem.SetNoTextures(v) end
	end)
	UIRegistry.Perf_LowMaterials = gpuSec:AddToggle("Force Flat Smooth Plastic", FeatureConfig.Performance.LowMaterials, function(v)
		if PerfSystem then PerfSystem.SetLowMaterials(v) end
	end)
	UIRegistry.Perf_OptimizeTerrain = gpuSec:AddToggle("Reduce 3D Terrain Details", FeatureConfig.Performance.OptimizeTerrain, function(v)
		if PerfSystem then PerfSystem.SetOptimizeTerrain(v) end
	end)
	UIRegistry.Perf_NoPostProcessing = gpuSec:AddToggle("Disable Post Processing", FeatureConfig.Performance.NoPostProcessing, function(v)
		if PerfSystem then PerfSystem.SetNoPostProcessing(v) end
	end)

	local fxSec = utilityTab:AddSection("Lighting & Particles")
	UIRegistry.Perf_NoShadows = fxSec:AddToggle("Disable Shadows", FeatureConfig.Performance.NoShadows, function(v)
		if PerfSystem then PerfSystem.SetNoShadows(v) end
	end)
	UIRegistry.Perf_NoParticles = fxSec:AddToggle("Disable Particle Emitters", FeatureConfig.Performance.NoParticles, function(v)
		if PerfSystem then PerfSystem.SetNoParticles(v) end
	end)

	local fpsSec = utilityTab:AddSection("Target Framerate Limit")
	fpsSec:AddButton("Unlock Target Frame Cap (999)", function() setFps(999) notify("Utility", "FPS Cap Unlocked", nil, Theme.Success) end)
	fpsSec:AddButton("Cap Target Limit to 60 FPS", function() setFps(60) notify("Utility", "60 FPS Cap Active", nil, Theme.Warning) end)
	fpsSec:AddButton("Cap Target Limit to 144 FPS", function() setFps(144) notify("Utility", "144 FPS Cap Active", nil, Theme.Success) end)

	local hitSec = utilityTab:AddSection("Hitbox Customizations")
	UIRegistry.Extras_Hitbox_Enabled = hitSec:AddToggle("Expand Character Hitboxes", false, function(v)
		FeatureConfig.Extras.Hitbox.Enabled = v
		if not v and Context.ResetHitboxes then Context.ResetHitboxes() end
	end)
	UIRegistry.Extras_Hitbox_Size = hitSec:AddSlider("Hitbox Radius", FeatureConfig.Extras.Hitbox.Size, 4, 60, function(v)
		FeatureConfig.Extras.Hitbox.Size = v
	end)

	local spinSec = utilityTab:AddSection("Spin Bot System")
	UIRegistry.Extras_SpinBot_Enabled = spinSec:AddToggle("Enable Spin Bot", false, function(v) FeatureConfig.Extras.SpinBot.Enabled = v end)
	UIRegistry.Extras_SpinBot_Speed = spinSec:AddSlider("Spin Speed", FeatureConfig.Extras.SpinBot.Speed, 1, 500, function(v) FeatureConfig.Extras.SpinBot.Speed = v end)

	local statSec = utilityTab:AddSection("On-Screen Statistics")
	statSec:AddToggle("Display FPS Counter", false, function(v)
		StatsConfig.ShowFPS = v
		if OverlayManager and OverlayManager.FPSLabel then OverlayManager.FPSLabel.Visible = v end
	end)
	statSec:AddToggle("Display Ping Monitor", false, function(v)
		StatsConfig.ShowPing = v
		if OverlayManager and OverlayManager.PingLabel then OverlayManager.PingLabel.Visible = v end
	end)

	local serverSec = utilityTab:AddSection("Server Manager")
	serverSec:AddToggle("Enable Anti-AFK", false, function(v)
		if v and Connections and Connections.Add and LocalPlayer then
			Connections.Add(LocalPlayer.Idled:Connect(function()
				pcall(function()
					VirtualUser:CaptureController()
					VirtualUser:ClickButton2(Vector2.zero)
				end)
			end))
			notify("Anti-AFK", "Engaged", nil, Theme.Success)
		end
	end)

	-- FIXED Server Hop JSON Decode Bug
	serverSec:AddButton("Server Hop (Public Lobby)", function()
		local now = os.clock()
		if (now - lastHop) < 3.0 then notify("Server Hop", "Please wait before hopping again", nil, Theme.Warning) return end
		lastHop = now
		notify("Server Hop", "Fetching open instances...", nil, Theme.Accent)

		task.spawn(function()
			local ok, rawResponse = pcall(function()
				return game:HttpGet(string.format("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100", tostring(game.PlaceId)))
			end)
			if not ok or not rawResponse then notify("Server Hop", "Failed to retrieve servers", nil, Theme.Danger) return end

			-- FIXED: HttpService:JSONDecode instead of JSONEncode
			local decodeOk, serverData = pcall(function() return HttpService:JSONDecode(rawResponse) end)
			if not decodeOk or not serverData or not serverData.data then
				notify("Server Hop", "Invalid response from Roblox API", nil, Theme.Danger)
				return
			end

			for _, server in ipairs(serverData.data) do
				if server.id ~= game.JobId and server.playing and server.maxPlayers and server.playing < server.maxPlayers then
					if Utils.PrepareTeleport then Utils.PrepareTeleport() end
					pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer) end)
					return
				end
			end
			notify("Server Hop", "No open servers found", nil, Theme.Danger)
		end)
	end)

	-- ============================================================
	-- SETTINGS TAB
	-- ============================================================
	local settingsTab = UI:AddTab("Settings", 1)
	local cfgSec = settingsTab:AddSection("Configuration Profiles")
	local cfgState = { Selected = "Default", Name = "MyConfig" }

	local function getCfgList()
		return (ConfigSystem and ConfigSystem.GetSavedNames and ConfigSystem.GetSavedNames()) or { "Default" }
	end

	local cfgDropdown = cfgSec:AddDropdown("Select Profile", getCfgList(), function(v)
		cfgState.Selected = (v ~= "None" and v ~= "") and v or "Default"
	end, "Default")

	local function refreshConfigDropdown()
		local now = os.clock()
		if (now - lastCfgRefresh) < 0.5 then return end
		lastCfgRefresh = now
		if cfgDropdown then cfgDropdown.Refresh(getCfgList(), true) end
	end

	cfgSec:AddButton("Refresh List", function() refreshConfigDropdown() notify("Configs", "Refreshed list", nil, Theme.Accent) end)
	cfgSec:AddTextbox("Profile Name", cfgState.Name, function(t)
		if type(t) == "string" and #t > 0 then
			cfgState.Name = Utils.SanitizeFileName and Utils.SanitizeFileName(t) or t
		end
	end, "Profile Name")

	cfgSec:AddButton("Save Profile", function()
		local sanitized = Utils.SanitizeFileName and Utils.SanitizeFileName(cfgState.Name or "") or (cfgState.Name or "")
		if #sanitized == 0 then notify("Config", "Enter a configuration file name", nil, Theme.Danger) return end
		if sanitized:lower() == "default" then notify("Config", "Cannot write default layout", nil, Theme.Warning) return end
		if not ConfigSystem then return end
		local ok, err = ConfigSystem.Save(sanitized)
		if ok then refreshConfigDropdown() notify("Saved Profile", sanitized, nil, Theme.Success)
		else notify("Write Failed", tostring(err), nil, Theme.Danger) end
	end)

	cfgSec:AddButton("Load Selected", function()
		if not cfgState.Selected or not ConfigSystem then notify("Config", "Select file first", nil, Theme.Danger) return end
		local ok, err = ConfigSystem.Load(cfgState.Selected)
		if ok then notify("Loaded Profile", cfgState.Selected, nil, Theme.Success)
		else notify("Load Failed", tostring(err), nil, Theme.Danger) end
	end)

	cfgSec:AddButton("Delete Selected", function()
		if not cfgState.Selected or not ConfigSystem then notify("Config", "Select file first", nil, Theme.Danger) return end
		if cfgState.Selected == "Default" then notify("Config", "Default profile cannot be deleted", nil, Theme.Warning) return end
		local ok, err = ConfigSystem.Delete(cfgState.Selected)
		if ok then
			cfgState.Selected = "Default"
			if cfgDropdown then cfgDropdown.Refresh(getCfgList()) cfgDropdown.Set("Default", true) end
			notify("Deleted Profile", "Configuration deleted", nil, Theme.Success)
		else notify("Deletion Failed", tostring(err), nil, Theme.Danger) end
	end)

	local themePresetsSec = settingsTab:AddSection("Visual Themes")
	local themeCustomSec = settingsTab:AddSection("Theme Adjustments")

	local presetNames = {}
	if ThemeManager and ThemeManager.Presets then
		for name in pairs(ThemeManager.Presets) do table.insert(presetNames, name) end
		table.sort(presetNames)
	end
	if #presetNames == 0 then table.insert(presetNames, "Default Cyan") end

	themePresetsSec:AddDropdown("Color Preset", presetNames, function(v)
		if ThemeManager and ThemeManager.Presets and ThemeManager.Presets[v] then
			local preset = ThemeManager.Presets[v]
			ThemeManager.ActivePreset = v
			UI:SetTheme(preset)
			updateCustomPickers(preset)
			notify("Themes", "Theme applied: " .. v, nil, Theme.Success)
		end
	end, (ThemeManager and ThemeManager.ActivePreset) or "Default Cyan")

	local themeKeys = { "Accent", "Bg", "Panel", "Elem", "Side", "Text", "Border", "ToggleOn" }
	for _, tk in ipairs(themeKeys) do
		local rName = "Theme_" .. tk
		UIRegistry[rName] = themeCustomSec:AddColorPicker(tk, Theme[tk], function(c)
			UI:UpdateThemeKey(tk, c)
		end)
	end

	local keySec = settingsTab:AddSection("License Keys")
	if KeySystem then
		keySec:AddButton("License: " .. KeySystem.GetTierName(), function() end)
		keySec:AddButton("Token: " .. KeySystem.GetMaskedKey(), function()
			if KeySystem.CurrentKey ~= "" then
				setClip(KeySystem.CurrentKey)
				notify("Access Key", "Key written to clipboard", nil, Theme.Success)
			end
		end)

		local pendingKey = ""
		keySec:AddTextbox("Input Key", "", function(v) pendingKey = v end, "License Token...")
		keySec:AddButton("Verify Token", function()
			local ok, _, msg = KeySystem.ApplyKey(pendingKey)
			notify(ok and "Verified" or "Invalid", msg or "", nil, ok and Theme.Success or Theme.Danger)
		end)
		keySec:AddButton("Copy Support Info", function()
			local ok, msg = KeySystem.CopyGetKeyLink()
			notify("Key Info", msg, nil, ok and Theme.Success or Theme.Danger)
		end)
		keySec:AddButton("Logout", function()
			KeySystem.ClearKey()
			notify("Logged out", "System keys removed.", nil, Theme.Warning)
		end)
	end

	return UI
end
