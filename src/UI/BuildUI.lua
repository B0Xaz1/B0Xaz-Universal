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

	local UI = UIEngine.new("B0Xaz Universal")
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
	-- TAB: Aimbot
	----------------------------------------------------------------
	local aimbotTab = UI:AddTab("Aimbot")
	local aimMain = aimbotTab:AddSection("Main Controls")

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

	UIRegistry.Aimbot_Hitpart = aimMain:AddDropdown("Hit Part", {"Head", "Torso", "Root", "LeftArm", "RightArm", "LeftLeg", "RightLeg"}, function(v)
		FeatureConfig.Aimbot.Hitpart = v
	end, FeatureConfig.Aimbot.Hitpart)

	UIRegistry.Aimbot_Smoothness = aimMain:AddSlider("Smoothness", FeatureConfig.Aimbot.Smoothness, 1, 20, function(v)
		FeatureConfig.Aimbot.Smoothness = v
	end)

	UIRegistry.Aimbot_ShakeIntensity = aimMain:AddSlider("Shake Intensity", FeatureConfig.Aimbot.ShakeIntensity, 0, 10, function(v)
		FeatureConfig.Aimbot.ShakeIntensity = v
	end)

	local aimCheck = aimbotTab:AddSection("Target Checks & Limits")

	UIRegistry.Aimbot_TeamCheck = aimCheck:AddToggle("Team Check", FeatureConfig.Aimbot.TeamCheck, function(v)
		FeatureConfig.Aimbot.TeamCheck = v
	end)

	UIRegistry.Aimbot_VisCheck = aimCheck:AddToggle("Visibility Check (Raycast)", FeatureConfig.Aimbot.VisCheck, function(v)
		FeatureConfig.Aimbot.VisCheck = v
	end)

	UIRegistry.Aimbot_UnlockOnDeath = aimCheck:AddToggle("Unlock On Target Death", FeatureConfig.Aimbot.UnlockOnDeath, function(v)
		FeatureConfig.Aimbot.UnlockOnDeath = v
	end)

	UIRegistry.Aimbot_BreakOnPull = aimCheck:AddToggle("Break Lock On Mouse Pull", FeatureConfig.Aimbot.BreakOnPull, function(v)
		FeatureConfig.Aimbot.BreakOnPull = v
	end)

	UIRegistry.Aimbot_MaxLockRadius = aimCheck:AddSlider("Max Lock Radius", FeatureConfig.Aimbot.MaxLockRadius or 200, 50, 500, function(v)
		FeatureConfig.Aimbot.MaxLockRadius = v
	end, " px")

	UIRegistry.Aimbot_MaxDistance = aimCheck:AddSlider("Max Target Distance", FeatureConfig.Aimbot.MaxDistance, 50, 2000, function(v)
		FeatureConfig.Aimbot.MaxDistance = v
	end, " studs")

	local aimFov = aimbotTab:AddSection("FOV Circle")
	UIRegistry.Aimbot_FOV_Show = aimFov:AddToggle("Show FOV Circle", FeatureConfig.Aimbot.FOV.Show, function(v)
		FeatureConfig.Aimbot.FOV.Show = v
	end)
	UIRegistry.Aimbot_FOV_Filled = aimFov:AddToggle("Filled Circle", FeatureConfig.Aimbot.FOV.Filled, function(v)
		FeatureConfig.Aimbot.FOV.Filled = v
	end)
	UIRegistry.Aimbot_FOV_Rainbow = aimFov:AddToggle("Rainbow FOV", FeatureConfig.Aimbot.FOV.Rainbow, function(v)
		FeatureConfig.Aimbot.FOV.Rainbow = v
	end)
	UIRegistry.Aimbot_FOV_Size = aimFov:AddSlider("FOV Radius", FeatureConfig.Aimbot.FOV.Size, 10, 600, function(v)
		FeatureConfig.Aimbot.FOV.Size = v
	end, " px")
	UIRegistry.Aimbot_FOV_Thickness = aimFov:AddSlider("Line Thickness", FeatureConfig.Aimbot.FOV.Thickness, 1, 10, function(v)
		FeatureConfig.Aimbot.FOV.Thickness = v
	end)

	local aimPred = aimbotTab:AddSection("Target Prediction")
	UIRegistry.Aimbot_Prediction_Horizontal = aimPred:AddSlider("Horizontal Lead", math.floor((FeatureConfig.Aimbot.Prediction.Horizontal or 0) * 200), 0, 100, function(v)
		FeatureConfig.Aimbot.Prediction.Horizontal = v / 200
	end)
	UIRegistry.Aimbot_Prediction_Vertical = aimPred:AddSlider("Vertical Lead", math.floor((FeatureConfig.Aimbot.Prediction.Vertical or 0) * 200), 0, 100, function(v)
		FeatureConfig.Aimbot.Prediction.Vertical = v / 200
	end)
	aimPred:AddButton("Reset Prediction", function()
		FeatureConfig.Aimbot.Prediction.Horizontal = 0
		FeatureConfig.Aimbot.Prediction.Vertical = 0
		if UIRegistry.Aimbot_Prediction_Horizontal then UIRegistry.Aimbot_Prediction_Horizontal.Set(0, true) end
		if UIRegistry.Aimbot_Prediction_Vertical then UIRegistry.Aimbot_Prediction_Vertical.Set(0, true) end
		UI:Notify("Prediction", "Reset to zero", nil, Theme.Success)
	end)

	local aimTrig = aimbotTab:AddSection("Triggerbot")
	UIRegistry.Aimbot_Triggerbot_Enabled = aimTrig:AddToggle("Enable Triggerbot", FeatureConfig.Aimbot.Triggerbot.Enabled, function(v)
		FeatureConfig.Aimbot.Triggerbot.Enabled = v
	end)
	UIRegistry.Aimbot_Triggerbot_Delay = aimTrig:AddSlider("Trigger Delay", math.floor(FeatureConfig.Aimbot.Triggerbot.Delay * 100), 0, 50, function(v)
		FeatureConfig.Aimbot.Triggerbot.Delay = v / 100
	end, " ms")

	----------------------------------------------------------------
	-- TAB: ESP
	----------------------------------------------------------------
	local espTab = UI:AddTab("ESP")
	local espMain = espTab:AddSection("ESP")
	UIRegistry.ESP_Enabled = espMain:AddToggle("Enable ESP", FeatureConfig.ESP.Enabled, function(v)
		FeatureConfig.ESP.Enabled = v
	end)
	UIRegistry.ESP_Box = espMain:AddToggle("Box", FeatureConfig.ESP.Box, function(v)
		FeatureConfig.ESP.Box = v
	end)
	UIRegistry.ESP_Name = espMain:AddToggle("Name", FeatureConfig.ESP.Name, function(v)
		FeatureConfig.ESP.Name = v
	end)
	UIRegistry.ESP_Health = espMain:AddToggle("Health Bar", FeatureConfig.ESP.Health, function(v)
		FeatureConfig.ESP.Health = v
	end)
	UIRegistry.ESP_Distance = espMain:AddToggle("Distance", FeatureConfig.ESP.Distance, function(v)
		FeatureConfig.ESP.Distance = v
	end)
	UIRegistry.ESP_Tracers = espMain:AddToggle("Tracers", FeatureConfig.ESP.Tracers, function(v)
		FeatureConfig.ESP.Tracers = v
	end)
	UIRegistry.ESP_Skeleton = espMain:AddToggle("Skeleton", FeatureConfig.ESP.Skeleton, function(v)
		FeatureConfig.ESP.Skeleton = v
	end)
	UIRegistry.ESP_HeadDot = espMain:AddToggle("Head Dot", FeatureConfig.ESP.HeadDot, function(v)
		FeatureConfig.ESP.HeadDot = v
	end)
	UIRegistry.ESP_LookDir = espMain:AddToggle("Look Direction", FeatureConfig.ESP.LookDir, function(v)
		FeatureConfig.ESP.LookDir = v
	end)
	UIRegistry.ESP_TeamCheck = espMain:AddToggle("Team Check", FeatureConfig.ESP.TeamCheck, function(v)
		FeatureConfig.ESP.TeamCheck = v
	end)

	local espSet = espTab:AddSection("Settings")
	UIRegistry.ESP_MaxDist = espSet:AddSlider("Max Distance", FeatureConfig.ESP.MaxDist, 100, 2000, function(v)
		FeatureConfig.ESP.MaxDist = v
	end)
	UIRegistry.ESP_Color = espSet:AddColorPicker("ESP Color", FeatureConfig.ESP.Color, function(c)
		FeatureConfig.ESP.Color = c
	end)

	local chamsSec = espTab:AddSection("Chams")
	UIRegistry.ESP_Chams_Enabled = chamsSec:AddToggle("Enable Chams", FeatureConfig.Chams.Enabled, function(v)
		FeatureConfig.Chams.Enabled = v
		if v then
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= LocalPlayer and Utils.IsAlive(p) then
					local teamSkip = FeatureConfig.ESP.TeamCheck and Utils.SameTeam(p)
					if not teamSkip then
						ESPSystem.RemoveHighlight(p)
						ESPSystem.AddHighlight(p)
					end
				end
			end
		else
			for _, p in ipairs(Players:GetPlayers()) do
				ESPSystem.RemoveHighlight(p)
			end
		end
	end)
	UIRegistry.ESP_Chams_FillColor = chamsSec:AddColorPicker("Fill Color", FeatureConfig.Chams.FillColor, function(c)
		FeatureConfig.Chams.FillColor = c
	end)
	UIRegistry.ESP_Chams_OutlineColor = chamsSec:AddColorPicker("Outline Color", FeatureConfig.Chams.OutlineColor, function(c)
		FeatureConfig.Chams.OutlineColor = c
	end)

	----------------------------------------------------------------
	-- TAB: Players
	----------------------------------------------------------------
	local playersTab = UI:AddTab("Players")

	local plSelectSec = playersTab:AddSection("Player Selection")
	local plActionsSec = playersTab:AddSection("Actions")
	local plStatusSec = playersTab:AddSection("Active States")

	local selectedName = nil
	local playerDropdown = nil
	local includeSelf = false

	local function getUpdatedPlayerList()
		local list = Utils.GetPlayerNameList(not includeSelf)
		if #list == 0 then
			return { "No Players Found" }
		end
		return list
	end

	local function onPlayerSelected(v)
		if v == "No Players Found" or v == "None" or v == "" then
			selectedName = nil
			State.SelectedPlayer = nil
		else
			selectedName = v
			State.SelectedPlayer = v
		end
	end

	local initialList = getUpdatedPlayerList()
	selectedName = (initialList[1] ~= "No Players Found") and initialList[1] or nil
	State.SelectedPlayer = selectedName

	playerDropdown = plSelectSec:AddDropdown("Select Player", initialList, onPlayerSelected, selectedName or "No Players Found")

	local function refreshList()
		local list = getUpdatedPlayerList()
		if playerDropdown then
			playerDropdown.Refresh(list, true)
			local current = playerDropdown.Get()
			onPlayerSelected(current)
		end
	end

	plSelectSec:AddToggle("Include LocalPlayer (For Testing)", includeSelf, function(v)
		includeSelf = v
		refreshList()
	end)

	plSelectSec:AddButton("Refresh Player List", function()
		refreshList()
		UI:Notify("Players", "List refreshed (" .. tostring(#getUpdatedPlayerList()) .. " available)", nil, Theme.Accent)
	end)

	Connections.Add(Players.PlayerAdded:Connect(function(p)
		task.wait(0.5)
		refreshList()
	end))
	Connections.Add(Players.PlayerRemoving:Connect(function(p)
		task.wait(0.2)
		refreshList()
	end))

	----------------------------------------------------------------
	-- Actions
	----------------------------------------------------------------
	plActionsSec:AddButton("Teleport to Player", function()
		if not selectedName or selectedName == "No Players Found" then
			UI:Notify("Players", "Select a valid player first", nil, Theme.Danger)
			return
		end
		local ok, err = PlayersSystem.TeleportTo(selectedName)
		if ok then
			UI:Notify("Players", "Teleported to " .. selectedName, nil, Theme.Success)
		else
			UI:Notify("Players", err or "Failed to teleport", nil, Theme.Danger)
		end
	end)

	plActionsSec:AddButton("Spectate Player", function()
		if not selectedName or selectedName == "No Players Found" then
			UI:Notify("Players", "Select a valid player first", nil, Theme.Danger)
			return
		end
		local ok, err = PlayersSystem.StartSpectate(selectedName)
		if ok then
			UI:Notify("Players", "Spectating " .. selectedName, nil, Theme.Success)
		else
			UI:Notify("Players", err or "Failed to spectate", nil, Theme.Danger)
		end
	end)

	plActionsSec:AddButton("Stop Spectating", function()
		PlayersSystem.StopSpectate()
		UI:Notify("Players", "Stopped spectating", nil, Theme.Accent)
	end)

	plActionsSec:AddButton("Fling Player", function()
		if not selectedName or selectedName == "No Players Found" then
			UI:Notify("Players", "Select a valid player first", nil, Theme.Danger)
			return
		end
		local ok, err = PlayersSystem.StartFling(selectedName)
		if ok then
			UI:Notify("Players", "Flinging " .. selectedName, nil, Theme.Warning)
		else
			UI:Notify("Players", err or "Failed to fling", nil, Theme.Danger)
		end
	end)

	plActionsSec:AddButton("Stop Fling", function()
		PlayersSystem.StopFling()
		UI:Notify("Players", "Stopped flinging", nil, Theme.Accent)
	end)

	plActionsSec:AddButton("Copy Player Name", function()
		if not selectedName or selectedName == "No Players Found" then
			UI:Notify("Players", "Select a valid player first", nil, Theme.Danger)
			return
		end
		pcall(function() setclipboard(selectedName) end)
		UI:Notify("Players", "Copied: " .. selectedName, nil, Theme.Accent)
	end)

	----------------------------------------------------------------
	-- Active States display
	----------------------------------------------------------------
	plStatusSec:AddButton("Spectating: None", function()
		PlayersSystem.StopSpectate()
	end)

	plStatusSec:AddButton("Flinging: None", function()
		PlayersSystem.StopFling()
	end)

	task.spawn(function()
		while UI and UI.Main and UI.Main.Parent do
			local spec = PlayersSystem.GetSpectating()
			local fling = PlayersSystem.GetFlingTarget()

			local specText = "Spectating: " .. (spec and spec.Name or "None") .. " (click to stop)"
			local flingText = "Flinging: " .. (fling and fling.Name or "None") .. " (click to stop)"

			if plStatusSec and plStatusSec.Frame then
				for _, elem in ipairs(plStatusSec.Frame:GetDescendants()) do
					if elem:IsA("TextButton") then
						if elem.Text:find("Spectating:") then
							elem.Text = specText
						elseif elem.Text:find("Flinging:") then
							elem.Text = flingText
						end
					end
				end
			end
			task.wait(0.5)
		end
	end)

	----------------------------------------------------------------
	-- TAB: Movement
	----------------------------------------------------------------
	local moveTab = UI:AddTab("Movement")
	local charSec = moveTab:AddSection("Character")

	UIRegistry.Movement_Speed = charSec:AddSlider("Walk Speed", FeatureConfig.Movement.Speed, 16, 500, function(v)
		FeatureConfig.Movement.Speed = v
		local h = Utils.GetHumanoid()
		if h then h.WalkSpeed = v end
	end, " ws")

	UIRegistry.Movement_JumpPower = charSec:AddSlider("Jump Power", FeatureConfig.Movement.JumpPower, 50, 500, function(v)
		FeatureConfig.Movement.JumpPower = v
		local h = Utils.GetHumanoid()
		if h then
			h.UseJumpPower = true
			h.JumpPower = v
		end
	end, " jp")

	UIRegistry.Movement_SprintEnabled = charSec:AddToggle("Sprint (Hold Shift)", FeatureConfig.Movement.SprintEnabled, function(v)
		FeatureConfig.Movement.SprintEnabled = v
		if not v then
			local h = Utils.GetHumanoid()
			if h then h.WalkSpeed = FeatureConfig.Movement.Speed end
		end
	end)

	UIRegistry.Movement_SprintSpeed = charSec:AddSlider("Sprint Speed", FeatureConfig.Movement.SprintSpeed or 30, 16, 500, function(v)
		FeatureConfig.Movement.SprintSpeed = v
	end, " ws")

	UIRegistry.Movement_InfJump = charSec:AddToggle("Infinite Jump", FeatureConfig.Movement.InfJump, function(v)
		FeatureConfig.Movement.InfJump = v
	end)

	UIRegistry.Movement_CFrameSpeed = charSec:AddToggle("CFrame Movement", FeatureConfig.Movement.CFrameSpeed, function(v)
		FeatureConfig.Movement.CFrameSpeed = v
	end)

	UIRegistry.Movement_CFrameSpeedValue = charSec:AddSlider("CFrame Move Speed", FeatureConfig.Movement.CFrameSpeedValue or 50, 1, 500, function(v)
		FeatureConfig.Movement.CFrameSpeedValue = v
	end, " sps")

	UIRegistry.Movement_Bhop = charSec:AddToggle("Bhop (Hold Space)", FeatureConfig.Movement.Bhop, function(v)
		FeatureConfig.Movement.Bhop = v
	end)

	charSec:AddToggle("Freeze Character", false, function(v)
		local h, r = Utils.GetHumanoid(), Utils.GetRootPart()
		if h then h.PlatformStand = v end
		if r then r.Anchored = v end
	end)

	local flySec = moveTab:AddSection("Fly")
	UIRegistry.Movement_FlySpeed = flySec:AddSlider("Fly Speed", FeatureConfig.Movement.FlySpeed, 10, 500, function(v)
		FeatureConfig.Movement.FlySpeed = v
	end)
	UIRegistry.Movement_FlyEnabled = flySec:AddToggle("Enable Fly", FeatureConfig.Movement.FlyEnabled, function(v)
		if v then FlySystem.Start() else FlySystem.Stop() end
	end)
	if not IsMobile then
		flySec:AddKeybind("Fly Key", Enum.KeyCode.F, function()
			if FeatureConfig.Movement.FlyEnabled then FlySystem.Stop() else FlySystem.Start() end
		end)
	end

	local worldSec = moveTab:AddSection("World")
	worldSec:AddSlider("Gravity", math.floor(Workspace.Gravity), 0, 300, function(v)
		Workspace.Gravity = v
	end)
	worldSec:AddSlider("Hip Height", 0, 0, 48, function(v)
		local h = Utils.GetHumanoid()
		if h then h.HipHeight = v + 2 end
	end)
	UIRegistry.Camera_FOV = worldSec:AddSlider("Camera FOV", FeatureConfig.Camera.FOV, 70, 120, function(v)
		FeatureConfig.Camera.FOV = v
	end)
	worldSec:AddSlider("Camera Zoom", 400, 10, 1000, function(v)
		LocalPlayer.CameraMaxZoomDistance = v
	end)

	local tpSec = moveTab:AddSection("Teleports")
	tpSec:AddButton("Save Position", function()
		local r = Utils.GetRootPart()
		if not r then
			UI:Notify("Position", "No character root found", nil, Theme.Danger)
			return
		end
		State.SavedPosition = r.CFrame
		UI:Notify("Position", "Saved successfully", nil, Theme.Success)
	end)
	tpSec:AddButton("Return to Saved", function()
		local r = Utils.GetRootPart()
		if r and State.SavedPosition then
			r.CFrame = State.SavedPosition
			UI:Notify("Position", "Teleported to saved position", nil, Theme.Success)
		else
			UI:Notify("Position", "No saved position", nil, Theme.Danger)
		end
	end)
	tpSec:AddToggle(IsMobile and "Teleport on Tap" or "TP to Mouse (CTRL+Click)", false, function(v)
		State.TpToMouse = v
	end)

	----------------------------------------------------------------
	-- TAB: Optimization
	----------------------------------------------------------------
	local optTab = UI:AddTab("Optimization")

	local gpuSec = optTab:AddSection("GPU Boosters")

	UIRegistry.Perf_NoTextures = gpuSec:AddToggle("Remove Textures & Decals", FeatureConfig.Performance.NoTextures, function(v)
		PerfSystem.SetNoTextures(v)
	end)
	UIRegistry.Perf_LowMaterials = gpuSec:AddToggle("Force Smooth Plastic", FeatureConfig.Performance.LowMaterials, function(v)
		PerfSystem.SetLowMaterials(v)
	end)
	UIRegistry.Perf_OptimizeTerrain = gpuSec:AddToggle("Optimize 3D Terrain", FeatureConfig.Performance.OptimizeTerrain, function(v)
		PerfSystem.SetOptimizeTerrain(v)
	end)
	UIRegistry.Perf_NoPostProcessing = gpuSec:AddToggle("Disable Post-Processing Effects", FeatureConfig.Performance.NoPostProcessing, function(v)
		PerfSystem.SetNoPostProcessing(v)
	end)

	local fxSec = optTab:AddSection("Effects Optimizer")

	UIRegistry.Perf_NoShadows = fxSec:AddToggle("Disable Part Shadows", FeatureConfig.Performance.NoShadows, function(v)
		PerfSystem.SetNoShadows(v)
	end)
	UIRegistry.Perf_NoParticles = fxSec:AddToggle("Disable Particle Systems", FeatureConfig.Performance.NoParticles, function(v)
		PerfSystem.SetNoParticles(v)
	end)

	local fpsSec = optTab:AddSection("Framerate Adjusters")

	fpsSec:AddButton("Unlock FPS (Internal Cap 999)", function()
		pcall(function() setfpscap(999) end)
		UI:Notify("Optimization", "Framerate capability unlocked", nil, Theme.Success)
	end)

	fpsSec:AddButton("Reset Frame Lock to 60 FPS", function()
		pcall(function() setfpscap(60) end)
		UI:Notify("Optimization", "Framerate locked to 60 FPS", nil, Theme.Warning)
	end)

	fpsSec:AddButton("Cap Framerate to 144 FPS", function()
		pcall(function() setfpscap(144) end)
		UI:Notify("Optimization", "Framerate locked to 144 FPS", nil, Theme.Success)
	end)

	local lightSec = optTab:AddSection("Lighting")
	UIRegistry.Visuals_Fullbright = lightSec:AddToggle("Fullbright", false, function(v)
		FeatureConfig.Visuals.Fullbright = v
		if not v then
			Lighting.Ambient = DefaultLighting.Ambient
			Lighting.OutdoorAmbient = DefaultLighting.OutdoorAmbient
			Lighting.Brightness = DefaultLighting.Brightness
			Lighting.GlobalShadows = DefaultLighting.GlobalShadows
		end
	end)
	lightSec:AddSlider("Clock Time", math.floor(Lighting.ClockTime), 0, 24, function(v)
		Lighting.ClockTime = v
	end)
	lightSec:AddButton("Reset Lighting", function()
		for k, v in pairs(DefaultLighting) do
			pcall(function() Lighting[k] = v end)
		end
		UI:Notify("Lighting", "Reset to original values", nil, Theme.Success)
	end)

	----------------------------------------------------------------
	-- TAB: Game Specific
	----------------------------------------------------------------
	local gameTab = UI:AddTab("Game")
	local gameLoader = Context.GameLoader

	local infoSec = gameTab:AddSection("Current Game")
	infoSec:AddButton("PlaceId: " .. tostring(game.PlaceId), function()
		pcall(function() setclipboard(tostring(game.PlaceId)) end)
		UI:Notify("Game", "PlaceId copied to clipboard", nil, Theme.Accent)
	end)
	infoSec:AddButton("Game: " .. (gameLoader and gameLoader.GetDisplayName() or "Unknown"), function() end)

	if gameLoader and gameLoader.IsSupported() then
		local ok, err = gameLoader.BuildUI(gameTab)
		if not ok then
			local errSec = gameTab:AddSection("Module Error")
			errSec:AddButton("Load failed - click for details", function()
				UI:Notify("Module Error", tostring(err), 8, Theme.Danger)
			end)
		end
	else
		local unsup = gameTab:AddSection("Not Supported")
		unsup:AddButton("No specific game script found", function()
			UI:Notify("Game", "Universal features active", nil, Theme.Warning)
		end)
	end

	----------------------------------------------------------------
	-- TAB: Extras
	----------------------------------------------------------------
	local extrasTab = UI:AddTab("Extras")
	local hitSec = extrasTab:AddSection("Hitbox")
	UIRegistry.Extras_Hitbox_Enabled = hitSec:AddToggle("Hitbox Expander", false, function(v)
		FeatureConfig.Extras.Hitbox.Enabled = v
		if not v and Context.ResetHitboxes then
			Context.ResetHitboxes()
		end
	end)
	UIRegistry.Extras_Hitbox_Size = hitSec:AddSlider("Hitbox Size", FeatureConfig.Extras.Hitbox.Size, 4, 60, function(v)
		FeatureConfig.Extras.Hitbox.Size = v
	end)

	local spinSec = extrasTab:AddSection("Spin Bot")
	UIRegistry.Extras_SpinBot_Enabled = spinSec:AddToggle("Enable Spin Bot", false, function(v)
		FeatureConfig.Extras.SpinBot.Enabled = v
	end)
	UIRegistry.Extras_SpinBot_Speed = spinSec:AddSlider("Spin Speed", FeatureConfig.Extras.SpinBot.Speed, 1, 500, function(v)
		FeatureConfig.Extras.SpinBot.Speed = v
	end)

	local crossSec = extrasTab:AddSection("Crosshair")
	UIRegistry.Extras_Crosshair_Visible = crossSec:AddToggle("Show Crosshair", false, function(v)
		FeatureConfig.Extras.Crosshair.Visible = v
	end)
	UIRegistry.Extras_Crosshair_Size = crossSec:AddSlider("Size", FeatureConfig.Extras.Crosshair.Size, 4, 40, function(v)
		FeatureConfig.Extras.Crosshair.Size = v
	end)
	UIRegistry.Extras_Crosshair_Gap = crossSec:AddSlider("Gap", FeatureConfig.Extras.Crosshair.Gap, 0, 20, function(v)
		FeatureConfig.Extras.Crosshair.Gap = v
	end)
	UIRegistry.Extras_Crosshair_Thickness = crossSec:AddSlider("Thickness", FeatureConfig.Extras.Crosshair.Thickness, 1, 6, function(v)
		FeatureConfig.Extras.Crosshair.Thickness = v
	end)
	UIRegistry.Extras_Crosshair_Color = crossSec:AddColorPicker("Color", FeatureConfig.Extras.Crosshair.Color, function(c)
		FeatureConfig.Extras.Crosshair.Color = c
	end)

		local stretchSec = extrasTab:AddSection("Stretch Res")

	UIRegistry.Extras_StretchRes_Enabled = stretchSec:AddToggle("Enable Stretch Res", FeatureConfig.Extras.StretchRes and FeatureConfig.Extras.StretchRes.Enabled or false, function(v)
		FeatureConfig.Extras.StretchRes = FeatureConfig.Extras.StretchRes or {
			Enabled = false, FOV = 100, Amount = 1.25, Bars = false, BarOpacity = 0.85
		}
		FeatureConfig.Extras.StretchRes.Enabled = v
		if not v then
			-- restore normal camera fov
			if Workspace.CurrentCamera and FeatureConfig.Camera then
				Workspace.CurrentCamera.FieldOfView = FeatureConfig.Camera.FOV or 90
			end
			if Context.DestroyStretchRes then
				Context.DestroyStretchRes()
			end
			UI:Notify("Stretch Res", "Disabled", nil, Theme.Accent)
		else
			UI:Notify("Stretch Res", "Enabled", nil, Theme.Success)
		end
	end)

	UIRegistry.Extras_StretchRes_FOV = stretchSec:AddSlider("Stretch FOV", (FeatureConfig.Extras.StretchRes and FeatureConfig.Extras.StretchRes.FOV) or 100, 70, 120, function(v)
		FeatureConfig.Extras.StretchRes = FeatureConfig.Extras.StretchRes or {}
		FeatureConfig.Extras.StretchRes.FOV = v
	end, " fov")

	UIRegistry.Extras_StretchRes_Amount = stretchSec:AddSlider("Stretch Amount", math.floor(((FeatureConfig.Extras.StretchRes and FeatureConfig.Extras.StretchRes.Amount) or 1.25) * 100), 100, 200, function(v)
		FeatureConfig.Extras.StretchRes = FeatureConfig.Extras.StretchRes or {}
		FeatureConfig.Extras.StretchRes.Amount = v / 100
	end, "%")

	UIRegistry.Extras_StretchRes_Bars = stretchSec:AddToggle("4:3 Side Bars", FeatureConfig.Extras.StretchRes and FeatureConfig.Extras.StretchRes.Bars or false, function(v)
		FeatureConfig.Extras.StretchRes = FeatureConfig.Extras.StretchRes or {}
		FeatureConfig.Extras.StretchRes.Bars = v
	end)

	UIRegistry.Extras_StretchRes_BarOpacity = stretchSec:AddSlider("Bar Opacity", math.floor(((FeatureConfig.Extras.StretchRes and FeatureConfig.Extras.StretchRes.BarOpacity) or 0.85) * 100), 30, 100, function(v)
		FeatureConfig.Extras.StretchRes = FeatureConfig.Extras.StretchRes or {}
		FeatureConfig.Extras.StretchRes.BarOpacity = v / 100
	end, "%")

	stretchSec:AddButton("Reset Stretch Res", function()
		FeatureConfig.Extras.StretchRes = {
			Enabled = false,
			FOV = 100,
			Amount = 1.25,
			Bars = false,
			BarOpacity = 0.85,
		}
		if UIRegistry.Extras_StretchRes_Enabled then UIRegistry.Extras_StretchRes_Enabled.Set(false, true) end
		if UIRegistry.Extras_StretchRes_FOV then UIRegistry.Extras_StretchRes_FOV.Set(100, true) end
		if UIRegistry.Extras_StretchRes_Amount then UIRegistry.Extras_StretchRes_Amount.Set(125, true) end
		if UIRegistry.Extras_StretchRes_Bars then UIRegistry.Extras_StretchRes_Bars.Set(false, true) end
		if UIRegistry.Extras_StretchRes_BarOpacity then UIRegistry.Extras_StretchRes_BarOpacity.Set(85, true) end
		if Workspace.CurrentCamera and FeatureConfig.Camera then
			Workspace.CurrentCamera.FieldOfView = FeatureConfig.Camera.FOV or 90
		end
		if Context.DestroyStretchRes then
			Context.DestroyStretchRes()
		end
		UI:Notify("Stretch Res", "Reset to defaults", nil, Theme.Success)
	end)

	local visSec = extrasTab:AddSection("Visuals")
	UIRegistry.Extras_SpeedLines = visSec:AddToggle("Speed Lines", false, function(v)
		FeatureConfig.Extras.SpeedLines = v
	end)
	UIRegistry.Extras_Wallbang = visSec:AddToggle("Wallbang Transparency", false, function(v)
		FeatureConfig.Extras.Wallbang = v
		local myChar = Utils.GetCharacter()
		for _, o in ipairs(Workspace:GetDescendants()) do
			if o:IsA("BasePart") and (not myChar or not o:IsDescendantOf(myChar)) then
				if v then
					if not o:GetAttribute("B0XazOrigT") then
						o:SetAttribute("B0XazOrigT", o.Transparency)
					end
					o.Transparency = math.max(o.Transparency, 0.85)
				else
					local orig = o:GetAttribute("B0XazOrigT")
					if orig ~= nil then
						o.Transparency = orig
						o:SetAttribute("B0XazOrigT", nil)
					end
				end
			end
		end
	end)

	local perfSec = extrasTab:AddSection("Stats")
	perfSec:AddToggle("Show FPS", false, function(v)
		StatsConfig.ShowFPS = v
		if OverlayManager.FPSLabel then OverlayManager.FPSLabel.Visible = v end
	end)
	perfSec:AddToggle("Show Ping", false, function(v)
		StatsConfig.ShowPing = v
		if OverlayManager.PingLabel then OverlayManager.PingLabel.Visible = v end
	end)

	local miscSec = extrasTab:AddSection("Misc")
	miscSec:AddToggle("Anti-AFK", false, function(v)
		if v then
			Connections.Add(LocalPlayer.Idled:Connect(function()
				pcall(function()
					local VU = game:GetService("VirtualUser")
					VU:CaptureController()
					VU:ClickButton2(Vector2.new())
				end)
			end))
			UI:Notify("Anti-AFK", "Enabled", nil, Theme.Success)
		end
	end)
	miscSec:AddToggle("Auto Rejoin on Kick", false, function(v)
		if v then
			Connections.Add(LocalPlayer.Kicked:Connect(function()
				Utils.PrepareTeleport()
				task.wait(2)
				pcall(function()
					game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
				end)
			end))
			UI:Notify("Auto Rejoin", "Enabled", nil, Theme.Success)
		end
	end)
	miscSec:AddButton("Server Hop", function()
		UI:Notify("Server Hop", "Finding server...", nil, Theme.Accent)
		task.spawn(function()
			local ok, servers = pcall(function()
				return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
			end)
			if not ok or not servers or not servers.data then
				UI:Notify("Server Hop", "Failed to fetch servers", nil, Theme.Danger)
				return
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
			UI:Notify("Server Hop", "No open servers found", nil, Theme.Danger)
		end)
	end)

	do
		local menuKeyBtn = nil
		;(function()
			local secRef = miscSec
			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, 0, 0, 30)
			row.BackgroundTransparency = 1
			row.Parent = secRef.Frame

			local lbl = Instance.new("TextLabel")
			lbl.Text = "Menu Toggle Key"
			lbl.Font = Enum.Font.Code
			lbl.TextSize = 11
			lbl.TextColor3 = Theme.Text
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.BackgroundTransparency = 1
			lbl.Position = UDim2.new(0, 8, 0, 0)
			lbl.Size = UDim2.new(1, -70, 1, 0)
			lbl.Parent = row
			UI:BindTheme(lbl, "TextColor3", "Text")

			menuKeyBtn = Instance.new("TextButton")
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

			table.insert(secRef.Elements, {Container = row, Name = "Menu Toggle Key"})
		end)()

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

	----------------------------------------------------------------
	-- TAB: Themes (Live Theming & Player Theme Creation)
	----------------------------------------------------------------
	----------------------------------------------------------------
	-- TAB: Themes (Live Color Picker Registry Update)
	----------------------------------------------------------------
	local themeTab = UI:AddTab("Themes")

	local themePresetsSec = themeTab:AddSection("Theme Presets")
	local themeCustomSec = themeTab:AddSection("Customize Colors")
	local themeManageSec = themeTab:AddSection("Save & Load Themes")
	local themeIOSec = themeTab:AddSection("Import & Export")

	local presetNames = {}
	if ThemeManager and ThemeManager.Presets then
		for pName, _ in pairs(ThemeManager.Presets) do
			table.insert(presetNames, pName)
		end
		table.sort(presetNames)
	else
		presetNames = { "Default Cyan" }
	end

	local function updateCustomPickers(newColors)
		local function syncCP(key, val)
			if UIRegistry[key] and UIRegistry[key].Set then
				UIRegistry[key].Set(val, true)
			end
		end
		syncCP("Theme_Accent", newColors.Accent or Theme.Accent)
		syncCP("Theme_Bg", newColors.Bg or Theme.Bg)
		syncCP("Theme_Panel", newColors.Panel or Theme.Panel)
		syncCP("Theme_Elem", newColors.Elem or Theme.Elem)
		syncCP("Theme_Side", newColors.Side or Theme.Side)
		syncCP("Theme_Text", newColors.Text or Theme.Text)
		syncCP("Theme_Border", newColors.Border or Theme.Border)
		syncCP("Theme_ToggleOn", newColors.ToggleOn or Theme.ToggleOn)
	end

	themePresetsSec:AddDropdown("Choose Preset", presetNames, function(v)
		if ThemeManager and ThemeManager.Presets and ThemeManager.Presets[v] then
			local targetTheme = ThemeManager.Presets[v]
			ThemeManager.ActivePreset = v
			UI:SetTheme(targetTheme)
			updateCustomPickers(targetTheme)
			UI:Notify("Themes", "Applied " .. v .. " preset", nil, Theme.Success)
		end
	end, ThemeManager and ThemeManager.ActivePreset or "Default Cyan")

	UIRegistry.Theme_Accent = themeCustomSec:AddColorPicker("Accent Color", Theme.Accent, function(c)
		UI:UpdateThemeKey("Accent", c)
	end)

	UIRegistry.Theme_Bg = themeCustomSec:AddColorPicker("Main Background", Theme.Bg, function(c)
		UI:UpdateThemeKey("Bg", c)
	end)

	UIRegistry.Theme_Panel = themeCustomSec:AddColorPicker("Panel Background", Theme.Panel, function(c)
		UI:UpdateThemeKey("Panel", c)
	end)

	UIRegistry.Theme_Elem = themeCustomSec:AddColorPicker("Element / Button", Theme.Elem, function(c)
		UI:UpdateThemeKey("Elem", c)
	end)

	UIRegistry.Theme_Side = themeCustomSec:AddColorPicker("Header / Sidebar", Theme.Side, function(c)
		UI:UpdateThemeKey("Side", c)
	end)

	UIRegistry.Theme_Text = themeCustomSec:AddColorPicker("Text Primary", Theme.Text, function(c)
		UI:UpdateThemeKey("Text", c)
	end)

	UIRegistry.Theme_Border = themeCustomSec:AddColorPicker("Border Outline", Theme.Border, function(c)
		UI:UpdateThemeKey("Border", c)
	end)

	UIRegistry.Theme_ToggleOn = themeCustomSec:AddColorPicker("Toggle Active", Theme.ToggleOn, function(c)
		UI:UpdateThemeKey("ToggleOn", c)
	end)

	local themeState = { Selected = nil, Name = "MyTheme" }

	local function getSavedThemeNames()
		local themesFolder = CONFIG.FOLDER .. "/Themes"
		Utils.MakeFolder(themesFolder)
		local names = {}
		for _, path in ipairs(Utils.ListFiles(themesFolder)) do
			local name = path:match("[/\\]?([^/\\]+)$") or path
			if name:sub(-#CONFIG.EXT) == CONFIG.EXT then
				table.insert(names, name:sub(1, -#CONFIG.EXT - 1))
			end
		end
		table.sort(names)
		return #names > 0 and names or { "None" }
	end

	local customThemeDropdown
	customThemeDropdown = themeManageSec:AddDropdown("Saved Custom Themes", getSavedThemeNames(), function(v)
		themeState.Selected = v ~= "None" and v or nil
	end)

	themeManageSec:AddButton("Refresh Saved Themes", function()
		customThemeDropdown.Refresh(getSavedThemeNames(), true)
		UI:Notify("Themes", "Refreshed custom theme list", nil, Theme.Accent)
	end)

	themeManageSec:AddTextbox("Theme Name", themeState.Name, function(t)
		if type(t) == "string" and #t > 0 then
			themeState.Name = Utils.SanitizeFileName(t)
		end
	end, "Name")

	local function serializeCurrentTheme()
		local data = {}
		for k, v in pairs(Theme) do
			if typeof(v) == "Color3" then
				data[k] = Utils.ColorToTable(v)
			end
		end
		return data
	end

	local function deserializeThemeData(data)
		local out = {}
		for k, v in pairs(data) do
			if type(v) == "table" and v.r ~= nil then
				out[k] = Utils.TableToColor(v)
			end
		end
		return out
	end

	themeManageSec:AddButton("Save Custom Theme", function()
		local name = Utils.SanitizeFileName(themeState.Name or "")
		if #name == 0 then
			UI:Notify("Themes", "Enter a theme name", nil, Theme.Danger)
			return
		end
		local data = serializeCurrentTheme()
		local encoded = HttpService:JSONEncode(data)
		local path = CONFIG.FOLDER .. "/Themes/" .. name .. CONFIG.EXT
		local ok, err = Utils.WriteFile(path, encoded)
		if ok then
			customThemeDropdown.Refresh(getSavedThemeNames(), true)
			UI:Notify("Themes", "Saved theme: " .. name, nil, Theme.Success)
		else
			UI:Notify("Themes", "Failed: " .. tostring(err), nil, Theme.Danger)
		end
	end)

	themeManageSec:AddButton("Load Selected Theme", function()
		if not themeState.Selected then
			UI:Notify("Themes", "Select a theme first", nil, Theme.Danger)
			return
		end
		local path = CONFIG.FOLDER .. "/Themes/" .. themeState.Selected .. CONFIG.EXT
		local content = Utils.ReadFile(path)
		if not content then
			UI:Notify("Themes", "Theme file not found", nil, Theme.Danger)
			return
		end
		local ok, data = pcall(function() return HttpService:JSONDecode(content) end)
		if ok and type(data) == "table" then
			local loadedColors = deserializeThemeData(data)
			UI:SetTheme(loadedColors)
			updateCustomPickers(loadedColors)
			UI:Notify("Themes", "Loaded: " .. themeState.Selected, nil, Theme.Success)
		else
			UI:Notify("Themes", "Invalid theme format", nil, Theme.Danger)
		end
	end)

	themeManageSec:AddButton("Delete Selected Theme", function()
		if not themeState.Selected then
			UI:Notify("Themes", "Select a theme first", nil, Theme.Danger)
			return
		end
		local path = CONFIG.FOLDER .. "/Themes/" .. themeState.Selected .. CONFIG.EXT
		pcall(function() delfile(path) end)
		themeState.Selected = nil
		customThemeDropdown.Refresh(getSavedThemeNames())
		UI:Notify("Themes", "Theme deleted", nil, Theme.Success)
	end)

	local rawThemeImportString = ""

	themeIOSec:AddButton("Copy Theme Data to Clipboard", function()
		local data = serializeCurrentTheme()
		local ok, encoded = pcall(function() return HttpService:JSONEncode(data) end)
		if ok then
			local ok2 = pcall(function() setclipboard(encoded) end)
			if ok2 then
				UI:Notify("Themes", "Theme copied to clipboard", nil, Theme.Success)
			else
				UI:Notify("Themes", "Clipboard not supported", nil, Theme.Danger)
			end
		end
	end)

	themeIOSec:AddTextbox("Paste Theme Data", "", function(v)
		rawThemeImportString = v
	end, "JSON Theme String")

	themeIOSec:AddButton("Import & Apply Theme", function()
		if not rawThemeImportString or #rawThemeImportString == 0 then
			UI:Notify("Themes", "Paste theme data first", nil, Theme.Danger)
			return
		end
		local ok, data = pcall(function() return HttpService:JSONDecode(rawThemeImportString) end)
		if ok and type(data) == "table" then
			local loadedColors = deserializeThemeData(data)
			UI:SetTheme(loadedColors)
			updateCustomPickers(loadedColors)
			UI:Notify("Themes", "Custom theme imported and applied!", nil, Theme.Success)
		else
			UI:Notify("Themes", "Invalid theme format", nil, Theme.Danger)
		end
	end)

	----------------------------------------------------------------
	-- TAB: Config
	----------------------------------------------------------------
	local cfgTab = UI:AddTab("Config")
	local cfgSec = cfgTab:AddSection("Manage")
	local cfgState = { Selected = "Default", Name = "MyConfig" }

	local function getCfgList()
		return ConfigSystem.GetSavedNames()
	end

	local cfgDropdown = cfgSec:AddDropdown("Saved Configs", getCfgList(), function(v)
		cfgState.Selected = (v ~= "None" and v ~= "") and v or "Default"
	end, "Default")

	cfgSec:AddButton("Refresh Config List", function()
		cfgDropdown.Refresh(getCfgList(), true)
		UI:Notify("Configs", "Refreshed list (" .. tostring(#getCfgList()) .. " available)", nil, Theme.Accent)
	end)

	cfgSec:AddTextbox("Config Name", cfgState.Name, function(t)
		if type(t) == "string" and #t > 0 then
			cfgState.Name = Utils.SanitizeFileName(t)
		end
	end, "Name")

	cfgSec:AddButton("Save Config", function()
		local name = Utils.SanitizeFileName(cfgState.Name or "")
		if #name == 0 then
			UI:Notify("Config", "Enter config name", nil, Theme.Danger)
			return
		end
		if name:lower() == "default" then
			UI:Notify("Config", "Cannot overwrite Default config", nil, Theme.Warning)
			return
		end
		local ok, err = ConfigSystem.Save(name)
		if ok then
			cfgDropdown.Refresh(getCfgList(), true)
			UI:Notify("Saved", name, nil, Theme.Success)
		else
			UI:Notify("Failed", tostring(err), nil, Theme.Danger)
		end
	end)

	cfgSec:AddButton("Load Selected", function()
		if not cfgState.Selected then
			UI:Notify("Config", "Select a config first", nil, Theme.Danger)
			return
		end
		local ok, err = ConfigSystem.Load(cfgState.Selected)
		if ok then
			UI:Notify("Loaded", cfgState.Selected .. (cfgState.Selected == "Default" and " (Reset)" or ""), nil, Theme.Success)
		else
			UI:Notify("Failed", tostring(err), nil, Theme.Danger)
		end
	end)

	cfgSec:AddButton("Delete Selected", function()
		if not cfgState.Selected then
			UI:Notify("Config", "Select a config first", nil, Theme.Danger)
			return
		end
		if cfgState.Selected == "Default" then
			UI:Notify("Config", "Default config cannot be deleted", nil, Theme.Warning)
			return
		end
		local ok, err = ConfigSystem.Delete(cfgState.Selected)
		if ok then
			cfgState.Selected = "Default"
			cfgDropdown.Refresh(getCfgList())
			cfgDropdown.Set("Default", true)
			UI:Notify("Deleted", "Config removed", nil, Theme.Success)
		else
			UI:Notify("Failed", tostring(err), nil, Theme.Danger)
		end
	end)

	local cfgIO = cfgTab:AddSection("Import / Export")
	local rawImportString = ""

	cfgIO:AddButton("Copy Config to Clipboard", function()
		local ok, encoded = pcall(function()
			return HttpService:JSONEncode(ConfigSystem.Serialize())
		end)
		if ok then
			local ok2 = pcall(function() setclipboard(encoded) end)
			if ok2 then
				UI:Notify("Export", "Copied to clipboard!", nil, Theme.Success)
			else
				UI:Notify("Export", "Clipboard function unavailable", nil, Theme.Danger)
			end
		else
			UI:Notify("Export", "Failed to encode config", nil, Theme.Danger)
		end
	end)

	cfgIO:AddTextbox("Paste Config Data", "", function(v)
		rawImportString = v
	end, "JSON Config String")

	cfgIO:AddButton("Import Config from Textbox", function()
		if not rawImportString or #rawImportString == 0 then
			UI:Notify("Import", "Paste config data first", nil, Theme.Danger)
			return
		end
		local ok, data = pcall(function()
			return HttpService:JSONDecode(rawImportString)
		end)
		if ok and type(data) == "table" then
			ConfigSystem.Deserialize(data)
			ConfigSystem.UpdateUI()

			local saveName = Utils.SanitizeFileName(cfgState.Name or "ImportedConfig")
			if #saveName == 0 or saveName:lower() == "default" then
				saveName = "ImportedConfig"
			end
			local saved, saveErr = ConfigSystem.Save(saveName)
			if saved then
				cfgDropdown.Refresh(getCfgList(), true)
				UI:Notify("Import", "Applied & saved as: " .. saveName, nil, Theme.Success)
			else
				UI:Notify("Import", "Applied to session!", nil, Theme.Success)
			end
		else
			UI:Notify("Import", "Invalid config format", nil, Theme.Danger)
		end
	end)

	return UI
end
