local SETTINGS = {
	PHYSICS = {
		MAX_FORCE = Vector3.one * 1e5,
		MAX_TORQUE = Vector3.one * 1e5,
		GYRO_DAMPING = 50,
		GYRO_POWER = 1000,
	},
	LIMITS = {
		MIN_FLY_SPEED = 1,
		MAX_FLY_SPEED = 500,
		DEFAULT_FLY_SPEED = 50,
		RESPAWN_DELAY = 0.5,
		MOBILE_MOVE_THRESHOLD = 0.1,
	},
	KEYS = {
		FORWARD = Enum.KeyCode.W,
		BACKWARD = Enum.KeyCode.S,
		LEFT = Enum.KeyCode.A,
		RIGHT = Enum.KeyCode.D,
		UP = Enum.KeyCode.Space,
		DOWN = Enum.KeyCode.LeftShift,
	},
}

return function(Context)
	local UserInputService = game:GetService("UserInputService")
	local Workspace = game:GetService("Workspace")
	local Players = game:GetService("Players")

	local LocalPlayer = Players.LocalPlayer
	local FeatureConfig = (Context and Context.FeatureConfig) or {}
	local State = (Context and Context.State) or {}
	local Utils = (Context and Context.Utils) or {}
	local Connections = (Context and Context.Connections) or {}

	local FlySystem = {}

	local function getCamera()
		return Workspace.CurrentCamera
	end

	local function isMobileDevice()
		return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	end

	local function getMoveSpeed()
		local movement = FeatureConfig.Movement
		local rawSpeed = movement and movement.FlySpeed or SETTINGS.LIMITS.DEFAULT_FLY_SPEED
		return math.clamp(rawSpeed, SETTINGS.LIMITS.MIN_FLY_SPEED, SETTINGS.LIMITS.MAX_FLY_SPEED)
	end

	function FlySystem.Cleanup()
		if State.FlyBodyVelocity then
			pcall(function()
				State.FlyBodyVelocity:Destroy()
			end)
			State.FlyBodyVelocity = nil
		end
		if State.FlyBodyGyro then
			pcall(function()
				State.FlyBodyGyro:Destroy()
			end)
			State.FlyBodyGyro = nil
		end
	end

	function FlySystem.Start()
		if FeatureConfig.Movement and FeatureConfig.Movement.FlyEnabled then
			return
		end

		local assets = Utils.GetPlayerAssets and Utils.GetPlayerAssets(LocalPlayer)
		if not (assets and assets.RootPart and assets.Humanoid) then
			return
		end

		FlySystem.Cleanup()

		local success = pcall(function()
			local bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.MaxForce = SETTINGS.PHYSICS.MAX_FORCE
			bodyVelocity.Velocity = Vector3.zero
			bodyVelocity.Parent = assets.RootPart
			State.FlyBodyVelocity = bodyVelocity

			local bodyGyro = Instance.new("BodyGyro")
			bodyGyro.MaxTorque = SETTINGS.PHYSICS.MAX_TORQUE
			bodyGyro.D = SETTINGS.PHYSICS.GYRO_DAMPING
			bodyGyro.P = SETTINGS.PHYSICS.GYRO_POWER
			bodyGyro.CFrame = assets.RootPart.CFrame
			bodyGyro.Parent = assets.RootPart
			State.FlyBodyGyro = bodyGyro

			assets.Humanoid.PlatformStand = true
			assets.Humanoid.AutoRotate = false
		end)

		if success then
			if FeatureConfig.Movement then
				FeatureConfig.Movement.FlyEnabled = true
			end
		else
			FlySystem.Cleanup()
			if FeatureConfig.Movement then
				FeatureConfig.Movement.FlyEnabled = false
			end
		end
	end

	function FlySystem.Stop()
		if FeatureConfig.Movement then
			FeatureConfig.Movement.FlyEnabled = false
		end
		FlySystem.Cleanup()

		local humanoid = Utils.GetHumanoid and Utils.GetHumanoid()
		local rootPart = Utils.GetRootPart and Utils.GetRootPart()

		if humanoid then
			pcall(function()
				humanoid.PlatformStand = false
				humanoid.AutoRotate = true
			end)
		end

		if rootPart then
			pcall(function()
				rootPart.AssemblyLinearVelocity = Vector3.zero
				rootPart.AssemblyAngularVelocity = Vector3.zero
			end)
		end
	end

	function FlySystem.Update()
		if not (FeatureConfig.Movement and FeatureConfig.Movement.FlyEnabled) then
			return
		end

		local bodyVelocity, bodyGyro = State.FlyBodyVelocity, State.FlyBodyGyro
		if not (bodyVelocity and bodyVelocity.Parent and bodyGyro and bodyGyro.Parent) then
			FlySystem.Stop()
			return
		end

		local assets = Utils.GetPlayerAssets and Utils.GetPlayerAssets(LocalPlayer)
		if not (assets and assets.Humanoid and assets.RootPart) then
			FlySystem.Stop()
			return
		end

		local camera = getCamera()
		if not camera then
			return
		end

		bodyGyro.CFrame = camera.CFrame
		local moveDirection = Vector3.zero
		local flySpeed = getMoveSpeed()

		if not isMobileDevice() then
			local camCFrame = camera.CFrame
			if UserInputService:IsKeyDown(SETTINGS.KEYS.FORWARD) then
				moveDirection = moveDirection + camCFrame.LookVector
			end
			if UserInputService:IsKeyDown(SETTINGS.KEYS.BACKWARD) then
				moveDirection = moveDirection - camCFrame.LookVector
			end
			if UserInputService:IsKeyDown(SETTINGS.KEYS.LEFT) then
				moveDirection = moveDirection - camCFrame.RightVector
			end
			if UserInputService:IsKeyDown(SETTINGS.KEYS.RIGHT) then
				moveDirection = moveDirection + camCFrame.RightVector
			end
			if UserInputService:IsKeyDown(SETTINGS.KEYS.UP) then
				moveDirection = moveDirection + Vector3.yAxis
			end
			if UserInputService:IsKeyDown(SETTINGS.KEYS.DOWN) and not (FeatureConfig.Movement and FeatureConfig.Movement.SprintEnabled) then
				moveDirection = moveDirection - Vector3.yAxis
			end
		else
			local moveDir = assets.Humanoid.MoveDirection
			if moveDir.Magnitude > SETTINGS.LIMITS.MOBILE_MOVE_THRESHOLD then
				local camLook = camera.CFrame.LookVector
				local camRight = camera.CFrame.RightVector
				local forwardFlat = Vector3.new(camLook.X, 0, camLook.Z)
				local rightFlat = Vector3.new(camRight.X, 0, camRight.Z)

				local forwardUnit = forwardFlat.Magnitude > 0 and forwardFlat.Unit or Vector3.zero
				local rightUnit = rightFlat.Magnitude > 0 and rightFlat.Unit or Vector3.zero

				moveDirection = (forwardUnit * -moveDir.Z) + (rightUnit * moveDir.X)
			end

			if FeatureConfig.Movement and FeatureConfig.Movement.MobileFlyUp then
				moveDirection = moveDirection + Vector3.yAxis
			end
			if FeatureConfig.Movement and FeatureConfig.Movement.MobileFlyDown then
				moveDirection = moveDirection - Vector3.yAxis
			end
		end

		if moveDirection.Magnitude > 0 then
			bodyVelocity.Velocity = moveDirection.Unit * flySpeed
		else
			bodyVelocity.Velocity = Vector3.zero
		end
	end

	if LocalPlayer and Connections and Connections.Add then
		Connections.Add(LocalPlayer.CharacterAdded:Connect(function()
			if FeatureConfig.Movement and FeatureConfig.Movement.FlyEnabled then
				FlySystem.Stop()
				task.wait(SETTINGS.LIMITS.RESPAWN_DELAY)
				FlySystem.Start()
			end
		end))
	end

	return FlySystem
end
