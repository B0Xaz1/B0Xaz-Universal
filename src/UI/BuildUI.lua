-- src/UI/BuildUI.lua
return function(Context)
	local Players = game:GetService("Players")
	local Workspace = game:GetService("Workspace")
	local Lighting = game:GetService("Lighting")
	local UIS = game:GetService("UserInputService")
	local HttpService = game:GetService("HttpService")

	local LocalPlayer = Players.LocalPlayer
	local IsMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled

	local CONFIG = Context.CONFIG
	local UIEngine = Context.UIEngine
	local Theme = Context.Theme
	local ThemeManager = Context.ThemeManager
	local FeatureConfig = Context.FeatureConfig
	local State = Context.State
	local StatsConfig = Context.StatsConfig
	local UIRegistry = Context.UIRegistry
	local Utils = Context.Utils
	local Connections = Context.Connections
	local DefaultLighting = Context.DefaultLighting

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
	getgenv().B0XazLibrary = UI

	local _listeningForMenuKey = false
	Connections.Add(UIS.InputBegan:Connect(function(input, processed)
		if _listeningForMenuKey or processed then return end
		if input.KeyCode == State.MenuKeybind then
			State.MenuVisible = not State.MenuVisible
			UI.Main.Visible = State.MenuVisible
		end
	end))

	----------------------------------------------------------------
	-- TAB 1: Combat (Tier 3)
	----------------------------------------------------------------
	local combatTab = UI:AddTab("Combat", 3)
	local aimMain = combatTab:AddSection("Aimbot Controls")

	UIRegistry.Aimbot_Enabled = aimMain:AddToggle("Aimbot Enabled", FeatureConfig.Aimbot.Enabled, function(v)
		FeatureConfig.Aimbot.Enabled = v
		if not v then AimbotSystem.LockOff() end
	end)
	UIRegistry.Aimbot_Keybind = aimMain:AddKeybind("Activation Bind", FeatureConfig.Aimbot.Keybind, function(k)
		FeatureConfig.Aimbot.Keybind = k
		UI:Notify("Aimbot", "Bind updated", nil, Theme.Success)
	end)
	UIRegistry.Aimbot_LockMode = aimMain:AddDropdown("Lock Mode", {"Hold", "Toggle"}, function(v)
		FeatureConfig.Aimbot.LockMode = v
		AimbotSystem.LockOff()
	end, FeatureConfig.Aimbot.LockMode)
	UIRegistry.Aimbot_Hitpart = aimMain:AddDropdown("Hit Part", {"Head","Torso","Root","LeftArm","RightArm","LeftLeg","RightLeg"}, function(v)
		FeatureConfig.Aimbot.Hitpart = v
	end, FeatureConfig.Aimbot.Hitpart)
	UIRegistry.Aimbot_Smoothness = aimMain:AddSlider("Smoothness", FeatureConfig.Aimbot.Smoothness, 1, 20, function(v) FeatureConfig.Aimbot.Smoothness = v end)
	UIRegistry.Aimbot_ShakeIntensity = aimMain:AddSlider("Shake Intensity", FeatureConfig.Aimbot.ShakeIntensity, 0, 10, function(v) FeatureConfig.Aimbot.ShakeIntensity = v end)

	local aimCheck = combatTab:AddSection("Target Settings")
	UIRegistry.Aimbot_TeamCheck = aimCheck:AddToggle("Team Check", FeatureConfig.Aimbot.TeamCheck, function(v) FeatureConfig.Aimbot.TeamCheck = v end)
	UIRegistry.Aimbot_VisCheck = aimCheck:AddToggle("Visibility Check", FeatureConfig.Aimbot.VisCheck, function(v) FeatureConfig.Aimbot.VisCheck = v end)
	UIRegistry.Aimbot_UnlockOnDeath = aimCheck:AddToggle("Unlock On Death", FeatureConfig.Aimbot.UnlockOnDeath, function(v) FeatureConfig.Aimbot.UnlockOnDeath = v end)
	UIRegistry.Aimbot_BreakOnPull = aimCheck:AddToggle("Break on Mouse Pull", FeatureConfig.Aimbot.BreakOnPull, function(v) FeatureConfig.Aimbot.BreakOnPull = v end)
	UIRegistry.Aimbot_MaxLockRadius = aimCheck:AddSlider("Max Lock Radius", FeatureConfig.Aimbot.MaxLockRadius or 200, 50, 500, function(v) FeatureConfig.Aimbot.MaxLockRadius = v end, " px")
	UIRegistry.Aimbot_MaxDistance = aimCheck:AddSlider("Max Target Distance", FeatureConfig.Aimbot.MaxDistance, 50, 2000, function(v) FeatureConfig.Aimbot.MaxDistance = v end, " studs")

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
		UI:Notify("Prediction", "Reset to zero", nil, Theme.Success)
	end)
	UIRegistry.Aimbot_Triggerbot_Enabled = aimPred:AddToggle("Enable Triggerbot", FeatureConfig.Aimbot.Triggerbot.Enabled, function(v) FeatureConfig.Aimbot.Triggerbot.Enabled = v end)
	UIRegistry.Aimbot_Triggerbot_Delay = aimPred:AddSlider("Trigger Delay", math.floor(FeatureConfig.Aimbot.Triggerbot.Delay * 100), 0, 50, function(v) FeatureConfig.Aimbot.Triggerbot.Delay = v / 100 end, " ms")


	----------------------------------------------------------------
	-- TAB 2: Visuals (Tier 2)
	----------------------------------------------------------------
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
	UIRegistry.ESP_MaxDist = espSet:AddSlider("Max Render Distance", FeatureConfig.ESP.MaxDist, 100, 2000, function(v) FeatureConfig.ESP.MaxDist = v end, " studs")
	UIRegistry.ESP_Color = espSet:AddColorPicker("ESP Global Color", FeatureConfig.ESP.Color, function(c) FeatureConfig.ESP.Color = c end)

	local chamsSec = visualsTab:AddSection("Player Chams")
	UIRegistry.ESP_Chams_Enabled = chamsSec:AddToggle("Enable Highlights", FeatureConfig.Chams.Enabled, function(v)
		FeatureConfig.Chams.Enabled = v
		if v then
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= LocalPlayer and Utils.IsAlive(p) and not (FeatureConfig.ESP.TeamCheck and Utils.SameTeam(p)) then
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
		if not v then
			Lighting.Ambient = DefaultLighting.Ambient
			Lighting.OutdoorAmbient = DefaultLighting.OutdoorAmbient
			Lighting.Brightness = DefaultLighting.Brightness
			Lighting.GlobalShadows = DefaultLighting.GlobalShadows
		end
	end)
	lightSec:AddSlider("Time of Day", math.floor(Lighting.ClockTime), 0, 24, function(v) Lighting.ClockTime = v end)
	lightSec:AddButton("Reset World Lighting", function()
		for k, v in pairs(DefaultLighting) do pcall(function() Lighting[k] = v end) end
		UI:Notify("Lighting", "Reset", nil, Theme.Success)
	end)

	local visEffectsSec = visualsTab:AddSection("Visual Effects")
	UIRegistry.Extras_SpeedLines = visEffectsSec:AddToggle("Draw Speed Lines", false, function(v) FeatureConfig.Extras.SpeedLines = v end)
	UIRegistry.Extras_Wallbang = visEffectsSec:AddToggle("Transparent Materials", false, function(v)
		FeatureConfig.Extras.Wallbang = v
		local myChar = Utils.GetCharacter()
		for _, o in ipairs(Workspace:GetDescendants()) do
			if o:IsA("BasePart") and (not myChar or not o:IsDescendantOf(myChar)) then
				if v then
					if not o:GetAttribute("B0XazOrigT") then o:SetAttribute("B0XazOrigT", o.Transparency) end
					o.Transparency = math.max(o.Transparency, 0.85)
				else
					local orig = o:GetAttribute("B0XazOrigT")
					if orig ~= nil then o.Transparency = orig; o:SetAttribute("B0XazOrigT", nil) end
				end
			end
		end
	end)


	----------------------------------------------------------------
	-- TAB 3: Movement (Tier 1)
	----------------------------------------------------------------
	local moveTab = UI:AddTab("Movement", 1)
	local charSec = moveTab:AddSection("Character Speed & Jump")

	UIRegistry.Movement_Speed = charSec:AddSlider("Walk Speed", FeatureConfig.Movement.Speed, 16, 500, function(v)
		FeatureConfig.Movement.Speed = v
		local h = Utils.GetHumanoid(); if h then h.WalkSpeed = v end
	end, " ws")
	UIRegistry.Movement_JumpPower = charSec:AddSlider("Jump Power", FeatureConfig.Movement.JumpPower, 50, 500, function(v)
		FeatureConfig.Movement.JumpPower = v
		local h = Utils.GetHumanoid(); if h then h.UseJumpPower = true; h.JumpPower = v end
	end, " jp")
	UIRegistry.Movement_SprintEnabled = charSec:AddToggle("Enable Shift-Sprint", FeatureConfig.Movement.SprintEnabled, function(v)
		FeatureConfig.Movement.SprintEnabled = v
		if not v then local h = Utils.GetHumanoid(); if h then h.WalkSpeed = FeatureConfig.Movement.Speed end end
	end)
	UIRegistry.Movement_SprintSpeed = charSec:AddSlider("Sprint Walk Speed", FeatureConfig.Movement.SprintSpeed or 30, 16, 500, function(v) FeatureConfig.Movement.SprintSpeed = v end, " ws")
	UIRegistry.Movement_InfJump = charSec:AddToggle("Infinite Air Jump", FeatureConfig.Movement.InfJump, function(v) FeatureConfig.Movement.InfJump = v end)
	UIRegistry.Movement_CFrameSpeed = charSec:AddToggle("CFrame Teleport Move", FeatureConfig.Movement.CFrameSpeed, function(v) FeatureConfig.Movement.CFrameSpeed = v end)
	UIRegistry.Movement_CFrameSpeedValue = charSec:AddSlider("CFrame Velocity Speed", FeatureConfig.Movement.CFrameSpeedValue or 50, 1, 500, function(v) FeatureConfig.Movement.CFrameSpeedValue = v end, " sps")
	UIRegistry.Movement_Bhop = charSec:AddToggle("Bunny Hop (AutoJump)", FeatureConfig.Movement.Bhop, function(v) FeatureConfig.Movement.Bhop = v end)
	charSec:AddToggle("Freeze Anchor Position", false, function(v)
		local h, r = Utils.GetHumanoid(), Utils.GetRootPart()
		if h then h.PlatformStand = v end
		if r then r.Anchored = v end
	end)

	local flySec = moveTab:AddSection("Flight Configuration")
	UIRegistry.Movement_FlySpeed = flySec:AddSlider("Fly Speed", FeatureConfig.Movement.FlySpeed, 10, 500, function(v) FeatureConfig.Movement.FlySpeed = v end)
	UIRegistry.Movement_FlyEnabled = flySec:AddToggle("Enable Fly Mode", FeatureConfig.Movement.FlyEnabled, function(v) if v then FlySystem.Start() else FlySystem.Stop() end end)
	if not IsMobile then
		flySec:AddKeybind("Fly Hotkey", Enum.KeyCode.F, function()
			if FeatureConfig.Movement.FlyEnabled then FlySystem.Stop() else FlySystem.Start() end
		end)
	end

	local worldSec = moveTab:AddSection("World Adjustments")
	worldSec:AddSlider("World Gravity", math.floor(Workspace.Gravity), 0, 300, function(v) Workspace.Gravity = v end)
	worldSec:AddSlider("Humanoid Hip Height", 0, 0, 48, function(v) local h = Utils.GetHumanoid(); if h then h.HipHeight = v + 2 end end)
	UIRegistry.Camera_FOV = worldSec:AddSlider("Camera FOV Zoom", FeatureConfig.Camera.FOV, 70, 120, function(v) FeatureConfig.Camera.FOV = v end)
	worldSec:AddSlider("Max Camera Zoom", 400, 10, 1000, function(v) LocalPlayer.CameraMaxZoomDistance = v end)

	local tpSec = moveTab:AddSection("Position Teleports")
	tpSec:AddButton("Save Current Position", function()
		local r = Utils.GetRootPart()
		if not r then UI:Notify("Position", "No character root found", nil, Theme.Danger); return end
		State.SavedPosition = r.CFrame
		UI:Notify("Position", "Saved Current CFrame", nil, Theme.Success)
	end)
	tpSec:AddButton("Teleport to Saved", function()
		local r = Utils.GetRootPart()
		if r and State.SavedPosition then r.CFrame = State.SavedPosition
			UI:Notify("Position", "Teleported to CFrame", nil, Theme.Success)
		else UI:Notify("Position", "No position saved", nil, Theme.Danger) end
	end)
	tpSec:AddToggle(IsMobile and "Tap-to-Teleport" or "TP to Click (Ctrl+Click)", false, function(v) State.TpToMouse = v end)


	----------------------------------------------------------------
	-- TAB 4: Players (Tier 1)
	----------------------------------------------------------------
	local playersTab = UI:AddTab("Players", 1)
	local plSelectSec = playersTab:AddSection("Target Selection")
	local plActionsSec = playersTab:AddSection("Actions")
	local plStatusSec = playersTab:AddSection("States")

	local selectedName = nil
	local playerDropdown = nil
	local includeSelf = false

	local function getUpdatedPlayerList()
		local list = Utils.GetPlayerNameList(not includeSelf)
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

	local function refreshList()
		local list = getUpdatedPlayerList()
		if playerDropdown then
			playerDropdown.Refresh(list, true)
			onPlayerSelected(playerDropdown.Get())
		end
	end

	plSelectSec:AddToggle("Include Self in Target List", includeSelf, function(v) includeSelf = v; refreshList() end)
	plSelectSec:AddButton("Refresh Player Target List", function()
		refreshList()
		UI:Notify("Players", "List refreshed", nil, Theme.Accent)
	end)

	Connections.Add(Players.PlayerAdded:Connect(function(p) task.wait(0.5); refreshList() end))
	Connections.Add(Players.PlayerRemoving:Connect(function(p) task.wait(0.2); refreshList() end))

	plActionsSec:AddButton("Teleport to Target", function()
		if not selectedName or selectedName == "No Players Found" then
			UI:Notify("Players", "Select a valid player target", nil, Theme.Danger); return
		end
		local ok, err = PlayersSystem.TeleportTo(selectedName)
		UI:Notify("Players", ok and ("Teleported to " .. selectedName) or (err or "Failed"), nil, ok and Theme.Success or Theme.Danger)
	end)

	plActionsSec:AddButton("Spectate Target View", function()
		if not selectedName or selectedName == "No Players Found" then
			UI:Notify("Players", "Select a valid player target", nil, Theme.Danger); return
		end
		local ok, err = PlayersSystem.StartSpectate(selectedName)
		UI:Notify("Players", ok and ("Spectating " .. selectedName) or (err or "Failed"), nil, ok and Theme.Success or Theme.Danger)
	end)

	plActionsSec:AddButton("Stop Camera Spectate", function()
		PlayersSystem.StopSpectate()
		UI:Notify("Players", "Stopped spectating", nil, Theme.Accent)
	end)

	plActionsSec:AddButton("Copy Player Exact Name", function()
		if not selectedName or selectedName == "No Players Found" then
			UI:Notify("Players", "Select a valid player target", nil, Theme.Danger); return
		end
		pcall(function() setclipboard(selectedName) end)
		UI:Notify("Players", "Copied: " .. selectedName, nil, Theme.Accent)
	end)

	-- Fling Attack (Restricted to Premium Tier 3)
	plActionsSec:AddButton("Fling Attack Player", function()
		if not selectedName or selectedName == "No Players Found" then
			UI:Notify("Players", "Select a valid player target", nil, Theme.Danger); return
		end
		local ok, err = PlayersSystem.StartFling(selectedName)
		UI:Notify("Players", ok and ("Flinging " .. selectedName) or (err or "Failed"), nil, ok and Theme.Warning or Theme.Danger)
	end, 3)

	plActionsSec:AddButton("Stop Fling Attack", function()
		PlayersSystem.StopFling()
		UI:Notify("Players", "Stopped flinging", nil, Theme.Accent)
	end, 3)

	plStatusSec:AddButton("Spectating Target: None", function() PlayersSystem.StopSpectate() end)
	plStatusSec:AddButton("Fling Target: None", function() PlayersSystem.StopFling() end, 3)

	task.spawn(function()
		while UI and UI.Main and UI.Main.Parent do
			local spec = PlayersSystem.GetSpectating()
			local fling = PlayersSystem.GetFlingTarget()
			local specText = "Spectating Target: " .. (spec and spec.Name or "None") .. " (click to stop)"
			local flingText = "Fling Target: " .. (fling and fling.Name or "None") .. " (click to stop)"
			if plStatusSec and plStatusSec.Frame then
				for _, elem in ipairs(plStatusSec.Frame:GetDescendants()) do
					if elem:IsA("TextButton") then
						if elem.Text:find("Spectating Target:") then elem.Text = specText
						elseif elem.Text:find("Fling Target:") then elem.Text = flingText end
					end
				end
			end
			task.wait(0.5)
		end
	end)


	----------------------------------------------------------------
	-- TAB 5: Game Module (Tier 3)
	----------------------------------------------------------------
	local gameTab = UI:AddTab("Game", 3)
	local gameLoader = Context.GameLoader

	local infoSec = gameTab:AddSection("Target Context")
	infoSec:AddButton("Game PlaceId: " .. tostring(game.PlaceId), function()
		pcall(function() setclipboard(tostring(game.PlaceId)) end)
		UI:Notify("Game", "PlaceId copied to clipboard", nil, Theme.Accent)
	end)
	infoSec:AddButton("Map Module: " .. (gameLoader and gameLoader.GetDisplayName() or "Unknown Map"), function() end)

	if gameLoader and gameLoader.IsSupported() then
		local ok, err = gameLoader.BuildUI(gameTab)
		if not ok then
			local errSec = gameTab:AddSection("Module Load Exception")
			errSec:AddButton("Fail Details - Click to Expand", function()
				UI:Notify("Module Exception", tostring(err), 8, Theme.Danger)
			end)
		end
	else
		local unsup = gameTab:AddSection("Map Unsupported")
		unsup:AddButton("No custom game modifications found.", function()
			UI:Notify("Game", "Universal hub features remain active.", nil, Theme.Warning)
		end)
	end


	----------------------------------------------------------------
	-- TAB 6: Utility (Tier 1)
	----------------------------------------------------------------
	local utilityTab = UI:AddTab("Utility", 1)

	local gpuSec = utilityTab:AddSection("Performance GPU Boosters")
	UIRegistry.Perf_NoTextures = gpuSec:AddToggle("Remove Textures & Decals", FeatureConfig.Performance.NoTextures, function(v) PerfSystem.SetNoTextures(v) end)
	UIRegistry.Perf_LowMaterials = gpuSec:AddToggle("Force Flat Smooth Plastic", FeatureConfig.Performance.LowMaterials, function(v) PerfSystem.SetLowMaterials(v) end)
	UIRegistry.Perf_OptimizeTerrain = gpuSec:AddToggle("Reduce 3D Material Details", FeatureConfig.Performance.OptimizeTerrain, function(v) PerfSystem.SetOptimizeTerrain(v) end)
	UIRegistry.Perf_NoPostProcessing = gpuSec:AddToggle("Disable Post Processing Effects", FeatureConfig.Performance.NoPostProcessing, function(v) PerfSystem.SetNoPostProcessing(v) end)

	local fxSec = utilityTab:AddSection("Lighting & Particles")
	UIRegistry.Perf_NoShadows = fxSec:AddToggle("Disable Light Shadows", FeatureConfig.Performance.NoShadows, function(v) PerfSystem.SetNoShadows(v) end)
	UIRegistry.Perf_NoParticles = fxSec:AddToggle("Disable Particle Emitters", FeatureConfig.Performance.NoParticles, function(v) PerfSystem.SetNoParticles(v) end)

	local fpsSec = utilityTab:AddSection("Target Framerate Limit")
	fpsSec:AddButton("Unlock Target Frame Cap (999)", function() pcall(function() setfpscap(999) end) UI:Notify("Utility", "FPS Cap Unlocked", nil, Theme.Success) end)
	fpsSec:AddButton("Cap Target Limit to 60 FPS", function() pcall(function() setfpscap(60) end) UI:Notify("Utility", "60 FPS Cap Active", nil, Theme.Warning) end)
	fpsSec:AddButton("Cap Target Limit to 144 FPS", function() pcall(function() setfpscap(144) end) UI:Notify("Utility", "144 FPS Cap Active", nil, Theme.Success) end)

	local hitSec = utilityTab:AddSection("Hitbox Customizations")
	UIRegistry.Extras_Hitbox_Enabled = hitSec:AddToggle("Expand Character Hitboxes", false, function(v)
		FeatureConfig.Extras.Hitbox.Enabled = v
		if not v and Context.ResetHitboxes then Context.ResetHitboxes() end
	end)
	UIRegistry.Extras_Hitbox_Size = hitSec:AddSlider("Hitbox Size Radius", FeatureConfig.Extras.Hitbox.Size, 4, 60, function(v) FeatureConfig.Extras.Hitbox.Size = v end)

	local spinSec = utilityTab:AddSection("Spin Bot System")
	UIRegistry.Extras_SpinBot_Enabled = spinSec:AddToggle("Enable Character Spin Bot", false, function(v) FeatureConfig.Extras.SpinBot.Enabled = v end)
	UIRegistry.Extras_SpinBot_Speed = spinSec:AddSlider("Spin Velocity Speed", FeatureConfig.Extras.SpinBot.Speed, 1, 500, function(v) FeatureConfig.Extras.SpinBot.Speed = v end)

	local statSec = utilityTab:AddSection("On-Screen Statistics")
	statSec:AddToggle("Display FPS Counter", false, function(v)
		StatsConfig.ShowFPS = v
		if OverlayManager.FPSLabel then OverlayManager.FPSLabel.Visible = v end
	end)
	statSec:AddToggle("Display Ping Monitor", false, function(v)
		StatsConfig.ShowPing = v
		if OverlayManager.PingLabel then OverlayManager.PingLabel.Visible = v end
	end)

	local serverSec = utilityTab:AddSection("Anti-Idle & Server Manager")
	serverSec:AddToggle("Enable Anti-AFK Connection", false, function(v)
		if v then
			Connections.Add(LocalPlayer.Idled:Connect(function()
				pcall(function()
					local VU = game:GetService("VirtualUser")
					VU:CaptureController()
					VU:ClickButton2(Vector2.new())
				end)
			end))
			UI:Notify("Anti-AFK", "Connection lock engaged", nil, Theme.Success)
		end
	end)
	serverSec:AddToggle("Auto Rejoin on Kick Exception", false, function(v)
		if v then
			Connections.Add(LocalPlayer.Kicked:Connect(function()
				Utils.PrepareTeleport()
				task.wait(2)
				pcall(function()
					game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
				end)
			end))
			UI:Notify("Auto Rejoin", "Engaged", nil, Theme.Success)
		end
	end)
	serverSec:AddButton("Server Hop (Public Lobby)", function()
		UI:Notify("Server Hop", "Fetching open instances...", nil, Theme.Accent)
		task.spawn(function()
			local ok, servers = pcall(function()
				return HttpService:JSONEncode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
			end)
			if not ok or not servers or not servers.data then
				UI:Notify("Server Hop", "Failed to retrieve servers", nil, Theme.Danger); return
			end
			for _, server in ipairs(servers.data) do
				if server.id ~= game.JobId and server.playing and server.maxPlayers and server.playing < server.maxPlayers then
					Utils.PrepareTeleport()
					pcall(function()
						game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
					end)
					return
				end
			end
			UI:Notify("Server Hop", "No open servers detected", nil, Theme.Danger)
		end)
	end)


	----------------------------------------------------------------
	-- TAB 7: Settings (Tier 1)
	----------------------------------------------------------------
	local settingsTab = UI:AddTab("Settings", 1)

	local cfgSec = settingsTab:AddSection("Configuration Profile Manager")
	local cfgState = { Selected = "Default", Name = "MyConfig" }
	local function getCfgList()
		return ConfigSystem.GetSavedNames()
	end

	local cfgDropdown = cfgSec:AddDropdown("Select Saved Profile", getCfgList(), function(v)
		cfgState.Selected = (v ~= "None" and v ~= "") and v or "Default"
	end, "Default")

	cfgSec:AddButton("Refresh Directory List", function()
		cfgDropdown.Refresh(getCfgList(), true)
		UI:Notify("Configs", "Refreshed list directory", nil, Theme.Accent)
	end)

	cfgSec:AddTextbox("Custom Config Name", cfgState.Name, function(t)
		if type(t) == "string" and #t > 0 then cfgState.Name = Utils.SanitizeFileName(t) end
	end, "Profile Name")

	cfgSec:AddButton("Save Current Profile", function()
		local name = Utils.SanitizeFileName(cfgState.Name or "")
		if #name == 0 then UI:Notify("Config", "Enter a configuration file name", nil, Theme.Danger); return end
		if name:lower() == "default" then UI:Notify("Config", "Cannot write default layout", nil, Theme.Warning); return end
		local ok, err = ConfigSystem.Save(name)
		if ok then cfgDropdown.Refresh(getCfgList(), true); UI:Notify("Saved Profile", name, nil, Theme.Success)
		else UI:Notify("Write Failed", tostring(err), nil, Theme.Danger) end
	end)

	cfgSec:AddButton("Load Selected Profile", function()
		if not cfgState.Selected then UI:Notify("Config", "Select file first", nil, Theme.Danger); return end
		local ok, err = ConfigSystem.Load(cfgState.Selected)
		if ok then UI:Notify("Loaded Profile", cfgState.Selected, nil, Theme.Success)
		else UI:Notify("Load Failed", tostring(err), nil, Theme.Danger) end
	end)

	cfgSec:AddButton("Delete Selected Profile", function()
		if not cfgState.Selected then UI:Notify("Config", "Select file first", nil, Theme.Danger); return end
		if cfgState.Selected == "Default" then UI:Notify("Config", "Default profiles cannot be deleted", nil, Theme.Warning); return end
		local ok, err = ConfigSystem.Delete(cfgState.Selected)
		if ok then
			cfgState.Selected = "Default"
			cfgDropdown.Refresh(getCfgList())
			cfgDropdown.Set("Default", true)
			UI:Notify("Deleted Profile", "Configuration deleted", nil, Theme.Success)
		else
			UI:Notify("Deletion Failed", tostring(err), nil, Theme.Danger)
		end
	end)

	local cfgIO = settingsTab:AddSection("Import & Export Profiles")
	local rawImportString = ""

	cfgIO:AddButton("Copy Config layout to Clipboard", function()
		local ok, encoded = pcall(function() return HttpService:JSONEncode(ConfigSystem.Serialize()) end)
		if ok then
			local ok2 = pcall(function() setclipboard(encoded) end)
			if ok2 then UI:Notify("Export Profile", "Layout written to clipboard", nil, Theme.Success)
			else UI:Notify("Export Profile", "Clipboard support missing", nil, Theme.Danger) end
		else UI:Notify("Export Profile", "Encoding serialization fail", nil, Theme.Danger) end
	end)

	cfgIO:AddTextbox("Paste Layout Data Here", "", function(v) rawImportString = v end, "JSON Layout Code String")

	cfgIO:AddButton("Import Layout from Textbox", function()
		if not rawImportString or #rawImportString == 0 then
			UI:Notify("Import Profile", "Paste profile code string", nil, Theme.Danger); return
		end
		local ok, data = pcall(function() return HttpService:JSONDecode(rawImportString) end)
		if ok and type(data) == "table" then
			ConfigSystem.Deserialize(data)
			ConfigSystem.UpdateUI()
			local saveName = Utils.SanitizeFileName(cfgState.Name or "ImportedConfig")
			if #saveName == 0 or saveName:lower() == "default" then saveName = "ImportedConfig" end
			local saved, saveErr = ConfigSystem.Save(saveName)
			if saved then
				cfgDropdown.Refresh(getCfgList(), true)
				UI:Notify("Import Profile", "Applied Layout & Saved as: " .. saveName, nil, Theme.Success)
			else
				UI:Notify("Import Profile", "Applied, Save failed: " .. tostring(saveErr), nil, Theme.Warning)
			end
		else
			UI:Notify("Import Profile", "Invalid Layout data string format", nil, Theme.Danger)
		end
	end)

	local themePresetsSec = settingsTab:AddSection("Visual Themes")
	local themeCustomSec = settingsTab:AddSection("Theme Adjustments")

	themePresetsSec:AddDropdown("Choose Color Preset", presetNames, function(v)
		if ThemeManager and ThemeManager.Presets and ThemeManager.Presets[v] then
			local t = ThemeManager.Presets[v]
			ThemeManager.ActivePreset = v
			UI:SetTheme(t)
			updateCustomPickers(t)
			UI:Notify("Themes", "Theme preset applied: " .. v, nil, Theme.Success)
		end
	end, ThemeManager and ThemeManager.ActivePreset or "Default Cyan")

	UIRegistry.Theme_Accent = themeCustomSec:AddColorPicker("Accent Highlight", Theme.Accent, function(c) UI:UpdateThemeKey("Accent", c) end)
	UIRegistry.Theme_Bg = themeCustomSec:AddColorPicker("Background Panel", Theme.Bg, function(c) UI:UpdateThemeKey("Bg", c) end)
	UIRegistry.Theme_Panel = themeCustomSec:AddColorPicker("Sub-Panel Element", Theme.Panel, function(c) UI:UpdateThemeKey("Panel", c) end)
	UIRegistry.Theme_Elem = themeCustomSec:AddColorPicker("Element Fill Base", Theme.Elem, function(c) UI:UpdateThemeKey("Elem", c) end)
	UIRegistry.Theme_Side = themeCustomSec:AddColorPicker("Header Sidebar Trim", Theme.Side, function(c) UI:UpdateThemeKey("Side", c) end)
	UIRegistry.Theme_Text = themeCustomSec:AddColorPicker("Text Primary Fill", Theme.Text, function(c) UI:UpdateThemeKey("Text", c) end)
	UIRegistry.Theme_Border = themeCustomSec:AddColorPicker("Border Frame Outlines", Theme.Border, function(c) UI:UpdateThemeKey("Border", c) end)
	UIRegistry.Theme_ToggleOn = themeCustomSec:AddColorPicker("Toggle Control Active", Theme.ToggleOn, function(c) UI:UpdateThemeKey("ToggleOn", c) end)

	local keySec = settingsTab:AddSection("Account Keys")
	keySec:AddButton("Current License: " .. KeySystem.GetTierName(), function() end)
	keySec:AddButton("Cached Key Token: " .. KeySystem.GetMaskedKey(), function()
		if KeySystem.CurrentKey ~= "" then
			pcall(function() setclipboard(KeySystem.CurrentKey) end)
			UI:Notify("Access Key", "Key written to clipboard", nil, Theme.Success)
		end
	end)

	local pending = ""
	keySec:AddTextbox("Input Activation Key", "", function(v) pending = v end, "License Token...")
	keySec:AddButton("Verify License Token", function()
		local ok, tier, msg = KeySystem.ApplyKey(pending)
		UI:Notify(ok and "Verified" or "Invalid", msg or "", nil, ok and Theme.Success or Theme.Danger)
		if ok then UI:Notify("License Upgrade", "Please restart client to load premium UI features", 5, Theme.Warning) end
	end)
	keySec:AddButton("Copy Direct Key Support Info", function()
		local ok, msg = KeySystem.CopyGetKeyLink()
		UI:Notify("Key Info", msg, nil, ok and Theme.Success or Theme.Danger)
	end)
	keySec:AddButton("Clear License Token (Logout)", function()
		KeySystem.ClearKey()
		UI:Notify("Logged out", "System profiles removed. Please restart.", nil, Theme.Warning)
	end)

	-- Custom Keybind Selection Row for HUD Menu
	do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 30)
		row.BackgroundTransparency = 1
		row.Parent = cfgSec.Frame

		local lbl = Instance.new("TextLabel")
		lbl.Text = "Menu Close Toggle Key"
		lbl.Font = Enum.Font.Code
		lbl.TextSize = 11
		lbl.TextColor3 = Theme.Text
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.BackgroundTransparency = 1
		lbl.Position = UDim2.new(0, 8, 0, 0)
		lbl.Size = UDim2.new(1, -70, 1, 0)
		lbl.Parent = row
		UI:BindTheme(lbl, "TextColor3", "Text")

		local menuKeyBtn = Instance.new("TextButton")
		menuKeyBtn.Text = State.MenuKeybind.Name
		menuKeyBtn.Font = Enum.Font.Code
		menuKeyBtn.TextSize = 10
		menuKeyBtn.TextColor3 = Theme.Text
		menuKeyBtn.BackgroundColor3 = Theme.Elem
		menuKeyBtn.BorderSizePixel = 0
		menuKeyBtn.Size = UDim2.new(0, 56, 0, 18)
		menuKeyBtn.Position = UDim2.new(1, -64, 0.5, -9)
		menuKeyBtn.AutoButtonColor = false
		menuKeyBtn.Parent = row
		UI:BindTheme(menuKeyBtn, "BackgroundColor3", "Elem")
		UI:BindTheme(menuKeyBtn, "TextColor3", "Text")

		table.insert(cfgSec.Elements, {Container = row, Name = "Menu Close Toggle Key"})

		menuKeyBtn.MouseButton1Click:Connect(function()
			_listeningForMenuKey = true
			menuKeyBtn.Text = "..."
			menuKeyBtn.TextColor3 = Theme.Accent
		end)
		Connections.Add(UIS.InputBegan:Connect(function(input)
			if _listeningForMenuKey and input.UserInputType == Enum.UserInputType.Keyboard then
				if input.KeyCode ~= Enum.KeyCode.Escape then
					State.MenuKeybind = input.KeyCode
					menuKeyBtn.Text = input.KeyCode.Name
				else
					menuKeyBtn.Text = State.MenuKeybind.Name
				end
				menuKeyBtn.TextColor3 = Theme.Text
				_listeningForMenuKey = false
			end
		end))
	end

	return UI
end
