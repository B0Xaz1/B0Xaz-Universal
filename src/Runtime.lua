-- // src/Runtime.lua
return function(Context)
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local Players = game:GetService("Players")
	local Lighting = game:GetService("Lighting")
	local Workspace = game:GetService("Workspace")
	local StatsService = game:GetService("Stats")

	local LocalPlayer = Players.LocalPlayer
	local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

	local FeatureConfig = Context.FeatureConfig or {}
	local State = Context.State or {}
	local StatsConfig = Context.StatsConfig or {}
	local Utils = Context.Utils or {}
	local Connections = Context.Connections or {}

	local AimbotSystem = Context.AimbotSystem
	local ESPSystem = Context.ESPSystem
	local FlySystem = Context.FlySystem
	local MovementSystem = Context.MovementSystem
	local OverlayManager = Context.OverlayManager
	local GameLoader = Context.GameLoader

	local env = (getgenv and getgenv()) or _G
	local sessionId = env.B0XazSessionId or 0

	local function isSessionAlive()
		return env.B0XazSessionId == sessionId
	end

	local function getCamera()
		return Workspace.CurrentCamera
	end

	local fpsCounter = 0
	local fpsTimer = 0
	local fpsDisplay = 0
	local hitboxTimer = 0
	local pingCache = 0
	local pingTimer = 0

	-- Hitbox Expander logic
	local function applyHitboxes()
		local extras = FeatureConfig.Extras
		if not (extras and extras.Hitbox and extras.Hitbox.Enabled) then return end
		local size = extras.Hitbox.Size or 10
		local targetSize = Vector3.new(size, size, size)

		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer then
				local assets = Utils.GetPlayerAssets and Utils.GetPlayerAssets(player)
				if assets and assets.RootPart and assets.RootPart:IsA("BasePart") then
					local root = assets.RootPart
					if State.OriginalHitboxSizes and not State.OriginalHitboxSizes[player] then
						State.OriginalHitboxSizes[player] = root.Size
					end
					if root.Size ~= targetSize then
						pcall(function()
							root.Size = targetSize
							root.Transparency = 0.9
							root.CanCollide = false
						end)
					end
				end
			end
		end
	end

	Context.ResetHitboxes = function()
		if not State.OriginalHitboxSizes then return end
		for player, originalSize in pairs(State.OriginalHitboxSizes) do
			local assets = player and Utils.GetPlayerAssets and Utils.GetPlayerAssets(player)
			if assets and assets.RootPart then
				pcall(function()
					assets.RootPart.Size = originalSize
					assets.RootPart.Transparency = 1
				end)
			end
		end
		table.clear(State.OriginalHitboxSizes)
	end

	if not (Connections and Connections.Add) then return end

	-- Teleport Queue Handler
	if LocalPlayer then
		pcall(function()
			Connections.Add(LocalPlayer.OnTeleport:Connect(function(teleportState)
				if not isSessionAlive() then return end
				if teleportState == Enum.TeleportState.Started or teleportState == Enum.TeleportState.InProgress then
					if Utils.PrepareTeleport then Utils.PrepareTeleport() end
				end
			end))
		end)
	end

	-- Infinite Jump
	Connections.Add(UserInputService.JumpRequest:Connect(function()
		if not isSessionAlive() then return end
		local movement = FeatureConfig.Movement
		if movement and movement.InfJump then
			local humanoid = Utils.GetHumanoid and Utils.GetHumanoid()
			if humanoid then
				pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end)
			end
		end
	end))

	-- Click / Tap Teleport
	if isMobile then
		Connections.Add(UserInputService.TouchTap:Connect(function(touchPositions)
			if not isSessionAlive() or not State.TpToMouse or not touchPositions or not touchPositions[1] then return end
			local root = Utils.GetRootPart and Utils.GetRootPart()
			local camera = getCamera()
			if not root or not camera then return end

			local ray = camera:ViewportPointToRay(touchPositions[1].X, touchPositions[1].Y)
			local params = RaycastParams.new()
			params.FilterDescendantsInstances = { Utils.GetCharacter and Utils.GetCharacter() }
			params.FilterType = Enum.RaycastFilterType.Exclude

			local result = Workspace:Raycast(ray.Origin, ray.Direction * 500, params)
			if result then
				root.CFrame = CFrame.new(result.Position + Vector3.new(0, 3, 0))
			end
		end))
	elseif LocalPlayer then
		local mouse = LocalPlayer:GetMouse()
		Connections.Add(mouse.Button1Down:Connect(function()
			if not isSessionAlive() or not State.TpToMouse or not UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then return end
			local root = Utils.GetRootPart and Utils.GetRootPart()
			if root and mouse.Hit then
				pcall(function()
					root.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
				end)
			end
		end))
	end

	-- RenderStepped Main Loop
	Connections.Add(RunService.RenderStepped:Connect(function(dt)
		if not isSessionAlive() then return end

		local camera = getCamera()
		if camera and FeatureConfig.Camera and FeatureConfig.Camera.FOV then
			pcall(function() camera.FieldOfView = FeatureConfig.Camera.FOV end)
		end

		if AimbotSystem then
			if AimbotSystem.UpdateAim then pcall(AimbotSystem.UpdateAim, dt) end
			if AimbotSystem.UpdateTriggerbot then pcall(AimbotSystem.UpdateTriggerbot) end
		end

		if OverlayManager then
			if OverlayManager.UpdateFOVCircle then pcall(OverlayManager.UpdateFOVCircle, dt) end
			if OverlayManager.UpdateCrosshair then pcall(OverlayManager.UpdateCrosshair) end
			if OverlayManager.UpdateSpeedLines then pcall(OverlayManager.UpdateSpeedLines, dt) end
		end

		if FlySystem and type(FlySystem.Update) == "function" then
			pcall(FlySystem.Update)
		end

		-- FPS Counter
		fpsCounter = fpsCounter + 1
		fpsTimer = fpsTimer + dt
		if fpsTimer >= 1.0 then
			fpsDisplay = fpsCounter
			fpsCounter = 0
			fpsTimer = 0
		end

		if OverlayManager and OverlayManager.FPSLabel then
			if StatsConfig.ShowFPS then
				OverlayManager.FPSLabel.Text = string.format("FPS: %d", fpsDisplay)
				OverlayManager.FPSLabel.Position = Vector2.new(8, 8)
				OverlayManager.FPSLabel.Visible = true
			else
				OverlayManager.FPSLabel.Visible = false
			end
		end

		-- Ping Counter
		pingTimer = pingTimer + dt
		if pingTimer >= 1.0 then
			pingTimer = 0
			pcall(function()
				local item = StatsService.Network.ServerStatsItem["Data Ping"]
				pingCache = math.floor(item:GetValue())
			end)
		end

		if OverlayManager and OverlayManager.PingLabel then
			if StatsConfig.ShowPing then
				OverlayManager.PingLabel.Text = string.format("Ping: %dms", pingCache)
				OverlayManager.PingLabel.Position = Vector2.new(8, 26)
				OverlayManager.PingLabel.Visible = true
			else
				OverlayManager.PingLabel.Visible = false
			end
		end

		-- SpinBot
		local extras = FeatureConfig.Extras
		if extras and extras.SpinBot and extras.SpinBot.Enabled then
			local root = Utils.GetRootPart and Utils.GetRootPart()
			if root then
				pcall(function()
					local speed = extras.SpinBot.Speed or 20
					State.SpinBotAngle = ((State.SpinBotAngle or 0) + speed * dt * 10) % 360
					root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, math.rad(State.SpinBotAngle), 0)
				end)
			end
		end

		if ESPSystem and type(ESPSystem.Update) == "function" then
			pcall(ESPSystem.Update)
		end
	end))

	-- Heartbeat Main Loop
	Connections.Add(RunService.Heartbeat:Connect(function(dt)
		if not isSessionAlive() then return end

		local humanoid = Utils.GetHumanoid and Utils.GetHumanoid()
		local movement = FeatureConfig.Movement
		if humanoid and movement then
			if movement.SprintEnabled and UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
				pcall(function() humanoid.WalkSpeed = movement.SprintSpeed or 30 end)
			elseif movement.SprintEnabled then
				pcall(function() humanoid.WalkSpeed = movement.Speed or 16 end)
			end
		end

		if MovementSystem and type(MovementSystem.Update) == "function" then
			pcall(MovementSystem.Update, dt)
		end

		if GameLoader and type(GameLoader.Update) == "function" then
			pcall(GameLoader.Update, dt)
		end

		-- Fullbright
		local visuals = FeatureConfig.Visuals
		if visuals and visuals.Fullbright then
			pcall(function()
				Lighting.Ambient = Color3.new(1, 1, 1)
				Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
				Lighting.Brightness = 2
				Lighting.GlobalShadows = false
			end)
		end

		-- Hitbox scan interval
		hitboxTimer = hitboxTimer + dt
		if hitboxTimer >= 0.25 then
			hitboxTimer = 0
			applyHitboxes()
		end

		-- Target Orbit / Loop TP / Spin Target
		if State.SelectedPlayer then
			local target = Utils.GetPlayerByName and Utils.GetPlayerByName(State.SelectedPlayer)
			local myAssets = Utils.GetPlayerAssets and Utils.GetPlayerAssets(LocalPlayer)
			local targetAssets = target and Utils.GetPlayerAssets and Utils.GetPlayerAssets(target)

			if myAssets and targetAssets and myAssets.RootPart and targetAssets.RootPart then
				local myRoot = myAssets.RootPart
				local targetRoot = targetAssets.RootPart

				if State.LoopTeleport then
					pcall(function() myRoot.CFrame = targetRoot.CFrame + Vector3.new(3, 0, 0) end)
				end

				if State.OrbitEnabled then
					pcall(function()
						local radius = State.OrbitRadius or 8
						local speed = State.OrbitSpeed or 2
						State.OrbitAngle = (State.OrbitAngle or 0) + speed * dt
						myRoot.CFrame = CFrame.new(
							targetRoot.Position.X + math.cos(State.OrbitAngle) * radius,
							targetRoot.Position.Y,
							targetRoot.Position.Z + math.sin(State.OrbitAngle) * radius
						) * CFrame.Angles(0, -State.OrbitAngle - math.pi * 0.5, 0)
					end)
				end

				if State.LoopJump then
					pcall(function() myRoot.CFrame = targetRoot.CFrame + Vector3.new(0, 4, 0) end)
				end

				if State.SpinTarget then
					pcall(function()
						State.SpinTargetAngle = (State.SpinTargetAngle or 0) + 10 * dt
						myRoot.CFrame = CFrame.new(
							targetRoot.Position.X + math.cos(State.SpinTargetAngle) * 2,
							targetRoot.Position.Y,
							targetRoot.Position.Z + math.sin(State.SpinTargetAngle) * 2
						)
					end)
				end
			end
		end
	end))
end
