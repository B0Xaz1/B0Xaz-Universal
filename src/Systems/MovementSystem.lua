-- // src/Systems/MovementSystem.lua
return function(Context)
	local UserInputService = game:GetService("UserInputService")
	local FeatureConfig = Context.FeatureConfig or {}
	local Utils = Context.Utils or {}

	local MovementSystem = {}
	local lastJump = 0

	local INVALID = {
		[Enum.HumanoidStateType.Jumping] = true,
		[Enum.HumanoidStateType.Freefall] = true,
		[Enum.HumanoidStateType.Dead] = true,
	}

	function MovementSystem.UpdateBhop()
		local mov = FeatureConfig.Movement
		if not (mov and mov.Bhop) then return end
		if not UserInputService:IsKeyDown(Enum.KeyCode.Space) and not UserInputService.TouchEnabled then return end

		local hum = Utils.GetHumanoid and Utils.GetHumanoid()
		if not hum or hum.Health <= 0 then return end

		local now = os.clock()
		if (now - lastJump) < 0.2 then return end

		local state = hum:GetState()
		local grounded = hum.FloorMaterial ~= Enum.Material.Air and not INVALID[state]
		if grounded then
			lastJump = now
			pcall(function()
				hum.Jump = true
				hum:ChangeState(Enum.HumanoidStateType.Jumping)
			end)
		end
	end

	function MovementSystem.UpdateCFrameSpeed(dt)
		local mov = FeatureConfig.Movement
		if not (mov and mov.CFrameSpeed) or mov.FlyEnabled then return end

		local hum = Utils.GetHumanoid and Utils.GetHumanoid()
		local root = Utils.GetRootPart and Utils.GetRootPart()
		if not hum or not root or hum.Health <= 0 then return end

		local md = hum.MoveDirection
		if md.Magnitude < 0.05 then return end

		local speed = math.clamp(mov.CFrameSpeedValue or 50, 0, 300)
		pcall(function()
			root.CFrame = root.CFrame + (md * speed * (dt or 1/60))
		end)
	end

	function MovementSystem.Update(dt)
		MovementSystem.UpdateBhop()
		MovementSystem.UpdateCFrameSpeed(dt)
	end

	return MovementSystem
end
