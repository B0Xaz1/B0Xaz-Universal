return function(Context)
	local RS = game:GetService("RunService")
	local UIS = game:GetService("UserInputService")
	local Players = game:GetService("Players")
	local Lighting = game:GetService("Lighting")
	local Workspace = game:GetService("Workspace")

	local LocalPlayer = Players.LocalPlayer
	local Camera = Workspace.CurrentCamera
	local Mouse = LocalPlayer:GetMouse()
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

	local function applyHitboxes()
		if not FeatureConfig.Extras or not FeatureConfig.Extras.Hitbox or not FeatureConfig.Extras.Hitbox.Enabled then return end
		local sz = FeatureConfig.Extras.Hitbox.Size or 10
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer and p.Character then
				local root = p.Character:FindFirstChild("HumanoidRootPart")
				if root and root:IsA("BasePart") then
					if State.OriginalHitboxSizes and not State.OriginalHitboxSizes[p] then
						State.OriginalHitboxSizes[p] = root.Size
					end
					if root.Size.X ~= sz then root.Size = Vector3.new(sz, sz, sz) end
					root.Transparency = 0.9
					root.CanCollide = false
				end
			end
		end
	end

	Context.ResetHitboxes = function()
		if not State.OriginalHitboxSizes then return end
		for p, sz in pairs(State.OriginalHitboxSizes) do
			if p and p.Character then
				local root = p.Character:FindFirstChild("HumanoidRootPart")
				if root then
					root.Size = sz
					root.Transparency = 1
				end
			end
		end
		table.clear(State.OriginalHitboxSizes)
	end

	if Connections.Add then
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
				local h = Utils.GetHumanoid and Utils.GetHumanoid()
				if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
			end
		end))

		if IsMobile then
			Connections.Add(UIS.TouchTap:Connect(function(tps)
				if not isSessionAlive() then return end
				if not State.TpToMouse then return end
				local r = Utils.GetRootPart and Utils.GetRootPart()
				if not r then return end
				local ray = Camera:ViewportPointToRay(tps[1].X, tps[1].Y)
				local params = RaycastParams.new()
				params.FilterDescendantsInstances = {Utils.GetCharacter and Utils.GetCharacter()}
				params.FilterType = Enum.RaycastFilterType.Exclude
				local res = Workspace:Raycast(ray.Origin, ray.Direction * 500, params)
				if res then r.CFrame = CFrame.new(res.Position + Vector3.new(0, 3, 0)) end
			end))
		else
			Connections.Add(Mouse.Button1Down:Connect(function()
				if not isSessionAlive() then return end
				if State.TpToMouse and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
					local r = Utils.GetRootPart and Utils.GetRootPart()
					if r then r.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3, 0)) end
				end
			end))
		end

		Connections.Add(RS.RenderStepped:Connect(function(dt)
			if not isSessionAlive() then return end

			if FeatureConfig.Camera and FeatureConfig.Camera.FOV then
				Camera.FieldOfView = FeatureConfig.Camera.FOV
			end

			if AimbotSystem then
				if type(AimbotSystem.UpdateAim) == "function" then AimbotSystem.UpdateAim(dt) end
				if type(AimbotSystem.UpdateTriggerbot) == "function" then AimbotSystem.UpdateTriggerbot() end
			end

			if OverlayManager then
				if type(OverlayManager.UpdateFOVCircle) == "function" then OverlayManager.UpdateFOVCircle(dt) end
				if type(OverlayManager.UpdateCrosshair) == "function" then OverlayManager.UpdateCrosshair() end
				if type(OverlayManager.UpdateSpeedLines) == "function" then OverlayManager.UpdateSpeedLines(dt) end
			end

			if FlySystem and type(FlySystem.Update) == "function" then
