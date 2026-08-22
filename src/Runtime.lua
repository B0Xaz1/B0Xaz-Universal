return function(Context)
	local RS = game:GetService("RunService")
	local UIS = game:GetService("UserInputService")
	local Players = game:GetService("Players")
	local Lighting = game:GetService("Lighting")
	local Workspace = game:GetService("Workspace")

	local LocalPlayer = Players.LocalPlayer
	local Camera = Workspace.CurrentCamera
	local IsMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled

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

	local SessionId = getgenv().B0XazSessionId or 0
	local function isSessionAlive()
		return getgenv().B0XazSessionId == SessionId
	end

	local _fpsCounter = 0
	local _fpsTimer = 0
	local _fpsDisplay = 0
	local _hitboxTimer = 0
	local _pingCache = 0
	local _pingTimer = 0

	local function safe(fn, ...)
		local ok, err = pcall(fn, ...)
		if not ok then
			warn("[B0Xaz Runtime] " .. tostring(err))
		end
	end

	local function applyHitboxes()
		if not FeatureConfig.Extras or not FeatureConfig.Extras.Hitbox or not FeatureConfig.Extras.Hitbox.Enabled then return end
		local sz = FeatureConfig.Extras.Hitbox.Size or 10
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer then
				local assets = Utils.GetPlayerAssets(p)
				if assets then
					local root = assets.RootPart
					if root and root:IsA("BasePart") then
						if State.OriginalHitboxSizes and not State.OriginalHitboxSizes[p] then
							State.OriginalHitboxSizes[p] = root.Size
						end
						if root.Size.X ~= sz then
							pcall(function()
								root.Size = Vector3.new(sz, sz, sz)
								root.Transparency = 0.9
								root.CanCollide = false
							end)
						end
					end
				end
			end
		end
	end

	Context.ResetHitboxes = function()
		if not State.OriginalHitboxSizes then return end
		for p, sz in pairs(State.OriginalHitboxSizes) do
			local assets = p and Utils.GetPlayerAssets(p)
			if assets then
				pcall(function()
					assets.RootPart.Size = sz
					assets.RootPart.Transparency = 1
				end)
			end
		end
		table.clear(State.OriginalHitboxSizes)
	end

	if not Connections.Add then return end

	pcall(function()
		Connections.Add(LocalPlayer.OnTeleport:Connect(function(teleportState)
			if not isSessionAlive() then return end
			if teleportState == Enum.TeleportState.Started or teleportState == Enum.TeleportState.InProgress then
				if Utils.PrepareTeleport then Utils.PrepareTeleport() end
			end
		end))
	end)

	Connections.Add(UIS.JumpRequest:Connect(function()
		if not isSessionAlive() then return end
		if FeatureConfig.Movement and FeatureConfig.Movement.InfJump then
			local h = Utils.GetHumanoid()
			if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end
		end
	end))

	if IsMobile then
		Connections.Add(UIS.TouchTap:Connect(function(tps)
			if not isSessionAlive() then return end
			if not State.TpToMouse then return end
			safe(function()
				local r = Utils.GetRootPart()
				if not r then return end
				local ray = Camera:ViewportPointToRay(tps[1].X, tps[1].Y)
				local params = RaycastParams.new()
				params.FilterDescendantsInstances = {Utils.GetCharacter()}
				params.FilterType = Enum.RaycastFilterType.Exclude
				local res = Workspace:Raycast(ray.Origin, ray.Direction * 500, params)
				if res then r.CFrame = CFrame.new(res.Position + Vector3.new(0, 3, 0)) end
			end)
		end))
	else
		local mouse = LocalPlayer:GetMouse()
		Connections.Add(mouse.Button1Down:Connect(function()
			if not isSessionAlive() then return end
			if State.TpToMouse and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
				local r = Utils.GetRootPart()
				if r then pcall(function() r.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0)) end) end
			end
		end))
	end

	Connections.Add(RS.RenderStepped:Connect(function(dt)
		if not isSessionAlive() then return end

		if FeatureConfig.Camera and FeatureConfig.Camera.FOV then
			pcall(function() Camera.FieldOfView = FeatureConfig.Camera.FOV end)
		end

		if AimbotSystem then
			safe(AimbotSystem.UpdateAim, dt)
			safe(AimbotSystem.UpdateTriggerbot)
		end

		if OverlayManager then
			safe(OverlayManager.UpdateFOVCircle, dt)
			safe(OverlayManager.UpdateCrosshair)
			safe(OverlayManager.UpdateSpeedLines, dt)
		end

		if FlySystem and type(FlySystem.Update) == "function" then
			safe(FlySystem.Update)
		end

		_fpsCounter += 1
		_fpsTimer += dt
		if _fpsTimer >= 1 then
			_fpsDisplay = _fpsCounter
			_fpsCounter = 0
			_fpsTimer = 0
		end

		if OverlayManager and OverlayManager.FPSLabel then
			if StatsConfig.ShowFPS then
				OverlayManager.FPSLabel.Text = "FPS: " .. _fpsDisplay
				OverlayManager.FPSLabel.Position = Vector2.new(8, 8)
				OverlayManager.FPSLabel.Visible = true
			else
				OverlayManager.FPSLabel.Visible = false
			end
		end

		_pingTimer += dt
		if _pingTimer >= 1 then
			_pingTimer = 0
			pcall(function()
				_pingCache = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
			end)
		end

		if OverlayManager and OverlayManager.PingLabel then
			if StatsConfig.ShowPing then
				OverlayManager.PingLabel.Text = "Ping: " .. _pingCache .. "ms"
				OverlayManager.PingLabel.Position = Vector2.new(8, 26)
				OverlayManager.PingLabel.Visible = true
			else
				OverlayManager.PingLabel.Visible = false
			end
		end

		if FeatureConfig.Extras and FeatureConfig.Extras.SpinBot and FeatureConfig.Extras.SpinBot.Enabled then
			local r = Utils.GetRootPart()
			if r then
				pcall(function()
					State.SpinBotAngle = ((State.SpinBotAngle or 0) + (FeatureConfig.Extras.SpinBot.Speed or 20) * dt * 10) % 360
					r.CFrame = CFrame.new(r.Position) * CFrame.Angles(0, math.rad(State.SpinBotAngle), 0)
				end)
			end
		end

		if ESPSystem and type(ESPSystem.Update) == "function" then
			safe(ESPSystem.Update)
		end
	end))

	Connections.Add(RS.Heartbeat:Connect(function(dt)
		if not isSessionAlive() then return end

		local hum = Utils.GetHumanoid()
		if hum and FeatureConfig.Movement then
			if FeatureConfig.Movement.SprintEnabled and UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
				pcall(function() hum.WalkSpeed = FeatureConfig.Movement.SprintSpeed or 30 end)
			elseif FeatureConfig.Movement.SprintEnabled then
				pcall(function() hum.WalkSpeed = FeatureConfig.Movement.Speed or 16 end)
			end
		end

		if MovementSystem and type(MovementSystem.Update) == "function" then
			safe(MovementSystem.Update, dt)
		end

		if GameLoader and type(GameLoader.Update) == "function" then
			safe(GameLoader.Update, dt)
		end

		if FeatureConfig.Visuals and FeatureConfig.Visuals.Fullbright then
			pcall(function()
				Lighting.Ambient = Color3.fromRGB(255, 255, 255)
				Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
				Lighting.Brightness = 2
				Lighting.GlobalShadows = false
			end)
		end

		_hitboxTimer += dt
		if _hitboxTimer >= 0.25 then
			_hitboxTimer = 0
			if FeatureConfig.Extras and FeatureConfig.Extras.Hitbox and FeatureConfig.Extras.Hitbox.Enabled then
				safe(applyHitboxes)
			end
		end

		if State.SelectedPlayer then
			local t = Utils.GetPlayerByName(State.SelectedPlayer)
			local myAssets = Utils.GetPlayerAssets(LocalPlayer)
			local targetAssets = t and Utils.GetPlayerAssets(t)

			if myAssets and targetAssets then
				local mr = myAssets.RootPart
				local tr = targetAssets.RootPart

				if State.LoopTeleport then
					pcall(function() mr.CFrame = tr.CFrame + Vector3.new(3, 0, 0) end)
				end
				if State.OrbitEnabled then
					pcall(function()
						State.OrbitAngle = (State.OrbitAngle or 0) + (State.OrbitSpeed or 2) * dt
						mr.CFrame = CFrame.new(
							tr.Position.X + math.cos(State.OrbitAngle) * (State.OrbitRadius or 8),
							tr.Position.Y,
							tr.Position.Z + math.sin(State.OrbitAngle) * (State.OrbitRadius or 8)
						) * CFrame.Angles(0, -State.OrbitAngle - math.pi / 2, 0)
					end)
				end
				if State.LoopJump then
					pcall(function() mr.CFrame = tr.CFrame + Vector3.new(0, 4, 0) end)
				end
				if State.SpinTarget then
					pcall(function()
						State.SpinTargetAngle = (State.SpinTargetAngle or 0) + 10 * dt
						mr.CFrame = CFrame.new(
							tr.Position.X + math.cos(State.SpinTargetAngle) * 2,
							tr.Position.Y,
							tr.Position.Z + math.sin(State.SpinTargetAngle) * 2
						)
					end)
				end
			end
		end
	end))
end
