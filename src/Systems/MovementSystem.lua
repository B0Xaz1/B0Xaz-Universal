local SETTINGS = {
	LIMITS = {
		BHOP_COOLDOWN = 0.2,
		MIN_MOVE_MAGNITUDE = 0.05,
		DEFAULT_DT = 0.016666666666667,
		DEFAULT_CFRAME_SPEED = 50,
		MIN_CFRAME_SPEED = 0,
		MAX_CFRAME_SPEED = 300,
	},
	KEYS = {
		JUMP = Enum.KeyCode.Space,
	},
	INVALID_JUMP_STATES = {
		[Enum.HumanoidStateType.Jumping] = true,
		[Enum.HumanoidStateType.Freefall] = true,
		[Enum.HumanoidStateType.Dead] = true,
	},
}

return function(Context)
	local UserInputService = game:GetService("UserInputService")

	local FeatureConfig = (Context and Context.FeatureConfig) or {}
	local Utils = (Context and Context.Utils) or {}

	local MovementSystem = {}
	local lastJumpTime = 0

	local function getHumanoid()
		return Utils.GetHumanoid and Utils.GetHumanoid()
	end

	local function getRootPart()
		return Utils.GetRootPart and Utils.GetRootPart()
	end

	function MovementSystem.UpdateBhop()
		local movement = FeatureConfig.Movement
		if not (movement and movement.Bhop) then return end
		if not UserInputService:IsKeyDown(SETTINGS.KEYS.JUMP) and not UserInputService.TouchEnabled then return end

		local humanoid = getHumanoid()
		if not humanoid or humanoid.Health <= 0 then return end

		local currentTime = os.clock()
		if (currentTime - lastJumpTime) < SETTINGS.LIMITS.BHOP_COOLDOWN then return end

		local currentState = humanoid:GetState()
		local isGrounded = (humanoid.FloorMaterial ~= Enum.Material.Air) and not SETTINGS.INVALID_JUMP_STATES[currentState]

		if isGrounded then
			lastJumpTime = currentTime
			pcall(function()
				humanoid.Jump = true
				humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end)
		end
	end

	function MovementSystem.UpdateCFrameSpeed(dt)
		local movement = FeatureConfig.Movement
		if not (movement and movement.CFrameSpeed) or movement.FlyEnabled then return end

		local humanoid = getHumanoid()
		local rootPart = getRootPart()
		if not humanoid or not rootPart or humanoid.Health <= 0 then return end

		local moveDir = humanoid.MoveDirection
		if moveDir.Magnitude < SETTINGS.LIMITS.MIN_MOVE_MAGNITUDE then return end

		local rawSpeed = movement.CFrameSpeedValue or SETTINGS.LIMITS.DEFAULT_CFRAME_SPEED
		local speed = math.clamp(rawSpeed, SETTINGS.LIMITS.MIN_CFRAME_SPEED, SETTINGS.LIMITS.MAX_CFRAME_SPEED)
		local deltaTime = dt or SETTINGS.LIMITS.DEFAULT_DT

		pcall(function()
			rootPart.CFrame = rootPart.CFrame + (moveDir * speed * deltaTime)
		end)
	end

	function MovementSystem.Update(dt)
		MovementSystem.UpdateBhop()
		MovementSystem.UpdateCFrameSpeed(dt)
	end

	return MovementSystem
end
