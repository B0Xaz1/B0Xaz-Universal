-- // src/Systems/FlySystem.lua
return function(Context)
	local UserInputService = game:GetService("UserInputService")
	local Workspace = game:GetService("Workspace")
	local Players = game:GetService("Players")

	local LocalPlayer = Players.LocalPlayer
	local FeatureConfig = Context.FeatureConfig or {}
	local State = Context.State or {}
	local Utils = Context.Utils or {}
	local Connections = Context.Connections or {}

	local FlySystem = {}
	local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

	function FlySystem.Cleanup()
		if State.FlyBodyVelocity then
			pcall(function() State.FlyBodyVelocity:Destroy() end)
			State.FlyBodyVelocity = nil
		end
		if State.FlyBodyGyro then
			pcall(function() State.FlyBodyGyro:Destroy() end)
			State.FlyBodyGyro = nil
		end
	end

	function FlySystem.Start()
		if FeatureConfig.Movement and FeatureConfig.Movement.FlyEnabled then return end
		local assets = Utils.GetPlayerAssets and Utils.GetPlayerAssets(LocalPlayer)
		if not (assets and assets.RootPart and assets.Humanoid) then return end

		FlySystem.Cleanup()
		local ok = pcall(function()
			local bv = Instance.new("BodyVelocity")
			bv.MaxForce = Vector3.one * 1e5
			bv.Velocity = Vector3.zero
			bv.Parent = assets.RootPart
			State.FlyBodyVelocity = bv

			local bg = Instance.new("BodyGyro")
			bg.MaxTorque = Vector3.one * 1e5
			bg.D = 50
			bg.P = 1000
			bg.CFrame = assets.RootPart.CFrame
			bg.Parent = assets.RootPart
			State.FlyBodyGyro = bg

			assets.Humanoid.PlatformStand = true
			assets.Humanoid.AutoRotate = false
		end)

		if FeatureConfig.Movement then
			FeatureConfig.Movement.FlyEnabled = ok
		end
		if not ok then FlySystem.Cleanup() end
	end

	function FlySystem.Stop()
		if FeatureConfig.Movement then FeatureConfig.Movement.FlyEnabled = false end
		FlySystem.Cleanup()
		local hum = Utils.GetHumanoid and Utils.GetHumanoid()
		local root = Utils.GetRootPart and Utils.GetRootPart()
		if hum then pcall(function() hum.PlatformStand = false hum.AutoRotate = true end) end
		if root then
			pcall(function()
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero
			end)
		end
	end

	function FlySystem.Update()
		if not (FeatureConfig.Movement and FeatureConfig.Movement.FlyEnabled) then return end
		local bv, bg = State.FlyBodyVelocity, State.FlyBodyGyro
		if not (bv and bv.Parent and bg and bg.Parent) then FlySystem.Stop() return end

		local assets = Utils.GetPlayerAssets and Utils.GetPlayerAssets(LocalPlayer)
		if not (assets and assets.Humanoid and assets.RootPart) then FlySystem.Stop() return end

		local cam = Workspace.CurrentCamera
		if not cam then return end

		bg.CFrame = cam.CFrame
		local dir = Vector3.zero
		local speed = math.clamp(FeatureConfig.Movement.FlySpeed or 50, 1, 500)

		if not isMobile then
			local cf = cam.CFrame
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cf.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cf.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cf.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cf.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.yAxis end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and not FeatureConfig.Movement.SprintEnabled then
				dir = dir - Vector3.yAxis
			end
		else
			local md = assets.Humanoid.MoveDirection
			if md.Magnitude > 0.1 then
				local look = cam.CFrame.LookVector
				local right = cam.CFrame.RightVector
				local f = Vector3.new(look.X, 0, look.Z)
				local r = Vector3.new(right.X, 0, right.Z)
				f = f.Magnitude > 0 and f.Unit or Vector3.zero
				r = r.Magnitude > 0 and r.Unit or Vector3.zero
				dir = (f * -md.Z) + (r * md.X)
			end
			if FeatureConfig.Movement.MobileFlyUp then dir = dir + Vector3.yAxis end
			if FeatureConfig.Movement.MobileFlyDown then dir = dir - Vector3.yAxis end
		end

		bv.Velocity = dir.Magnitude > 0 and (dir.Unit * speed) or Vector3.zero
	end

	if LocalPlayer and Connections and Connections.Add then
		Connections.Add(LocalPlayer.CharacterAdded:Connect(function()
			if FeatureConfig.Movement and FeatureConfig.Movement.FlyEnabled then
				FlySystem.Stop()
				task.wait(0.5)
				FlySystem.Start()
			end
		end))
	end

	return FlySystem
end
