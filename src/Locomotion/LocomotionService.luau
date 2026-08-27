local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

return function(services: any)
	local StateStore = services:Get("StateStore")
	local TaskScheduler = services:Get("TaskScheduler")
	local Disposer = services:Get("Disposer")
	local PlayerTracker = services:Get("PlayerTracker")
	local Environment = services:Get("Environment")

	local LocalPlayer = Players.LocalPlayer
	local LocomotionService = {
		_flingTarget = nil :: Player?,
		_flingActive = false,
		_flingOffset = 0.1,
	}

	-- Originals are captured on the first frame we touch a humanoid so the
	-- unload hook can return the character to exactly what it had
	local originalHumanoid: Humanoid? = nil
	local originalWalkSpeed: number? = nil
	local originalUseJumpPower: boolean? = nil
	local originalJumpPower: number? = nil
	local originalJumpHeight: number? = nil

	local function updateMovement(dt: number)
		local myAssets = PlayerTracker:GetLocalAssets()
		if not myAssets or not myAssets.Humanoid or not myAssets.RootPart or myAssets.Humanoid.Health <= 0 then
			return
		end

		local hum = myAssets.Humanoid
		local root = myAssets.RootPart
		if originalHumanoid == nil then
			originalHumanoid = hum
			originalWalkSpeed = hum.WalkSpeed
			originalUseJumpPower = hum.UseJumpPower
			originalJumpPower = hum.JumpPower
			originalJumpHeight = hum.JumpHeight
		end
		local movSettings = StateStore:Get("Movement")
		if not movSettings then return end

		if movSettings.SprintEnabled then
			local isSprinting = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
			local targetSpeed = isSprinting and (movSettings.SprintSpeed or 30) or (movSettings.Speed or 16)
			if hum.WalkSpeed ~= targetSpeed then
				hum.WalkSpeed = targetSpeed
			end
		else
			if hum.WalkSpeed ~= movSettings.Speed and not movSettings.FlyEnabled then
				hum.WalkSpeed = movSettings.Speed
			end
		end

		if movSettings.JumpPower and hum.JumpPower ~= movSettings.JumpPower then
			hum.UseJumpPower = true
			hum.JumpPower = movSettings.JumpPower
		end

		-- CFrame displacement teleports the root instead of changing velocity,
		-- which is why it must pause while constraint flight owns the assembly
		if movSettings.CFrameSpeed and not movSettings.FlyEnabled then
			local moveDir = hum.MoveDirection
			-- Some executors/games keep MoveDirection stale, so fall back to
			-- the camera-relative keyboard direction in that case.
			if moveDir.Magnitude <= 0.05 then
				local cam = Workspace.CurrentCamera
				if cam then
					local look = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z)
					local right = Vector3.new(cam.CFrame.RightVector.X, 0, cam.CFrame.RightVector.Z)
					if look.Magnitude > 0 then look = look.Unit end
					if right.Magnitude > 0 then right = right.Unit end
					if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += look end
					if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= look end
					if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= right end
					if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += right end
				end
			end
			if moveDir.Magnitude > 0.05 then
				local speedVal = math.clamp(tonumber(movSettings.CFrameSpeedValue) or 50, 1, 300)
				root.CFrame = root.CFrame + (moveDir.Unit * speedVal * dt)
			end
		end

		-- Fling: snap onto the target then slam the assembly at extreme speed
		if LocomotionService._flingActive and LocomotionService._flingTarget then
			local targetAssets = PlayerTracker:GetPlayerAssets(LocomotionService._flingTarget)
			if targetAssets and targetAssets.RootPart then
				root.CFrame = targetAssets.RootPart.CFrame
				local currentVel = root.AssemblyLinearVelocity
				root.AssemblyLinearVelocity = currentVel * 10000 + Vector3.new(0, 10000, 0)
				-- Keep the fling guard off while we are the one flinging
				StateStore:SetTransient("AntiFlingSuppressUntil", os.clock() + 0.1)
			else
				LocomotionService:StopFling()
			end
		end
	end

	function LocomotionService:SavePosition(): boolean
		local myAssets = PlayerTracker:GetLocalAssets()
		if myAssets and myAssets.RootPart then
			StateStore:SetTransient("SavedPosition", myAssets.RootPart.CFrame)
			return true
		end
		return false
	end

	function LocomotionService:TeleportToSaved(): boolean
		local saved = StateStore:GetTransient("SavedPosition")
		local myAssets = PlayerTracker:GetLocalAssets()
		if saved and myAssets and myAssets.RootPart then
			-- Zero velocity first so the teleport does not inherit momentum
			myAssets.RootPart.AssemblyLinearVelocity = Vector3.zero
			myAssets.RootPart.AssemblyAngularVelocity = Vector3.zero
			myAssets.RootPart.CFrame = saved
			-- Briefly suppress the fling guard so our own teleport is not
			-- read as an impulse and snapped back.
			StateStore:SetTransient("AntiFlingSuppressUntil", os.clock() + 0.5)
			return true
		end
		return false
	end

	function LocomotionService:TeleportToPosition(position: Vector3, offset: Vector3?)
		local myAssets = PlayerTracker:GetLocalAssets()
		if myAssets and myAssets.RootPart then
			myAssets.RootPart.AssemblyLinearVelocity = Vector3.zero
			myAssets.RootPart.AssemblyAngularVelocity = Vector3.zero
			myAssets.RootPart.CFrame = CFrame.new(position + (offset or Vector3.new(0, 3, 0)))
			StateStore:SetTransient("AntiFlingSuppressUntil", os.clock() + 0.5)
		end
	end

	function LocomotionService:StartFling(targetPlayer: Player): boolean
		if not StateStore:HasPermission("Locomotion.Fling") then return false end
		if not targetPlayer or targetPlayer == LocalPlayer then return false end
		self._flingTarget = targetPlayer
		self._flingActive = true
		return true
	end

	function LocomotionService:StopFling()
		self._flingActive = false
		self._flingTarget = nil
		local myAssets = PlayerTracker:GetLocalAssets()
		if myAssets and myAssets.RootPart then
			myAssets.RootPart.AssemblyLinearVelocity = Vector3.zero
			myAssets.RootPart.AssemblyAngularVelocity = Vector3.zero
		end
		if myAssets and myAssets.Humanoid then
			myAssets.Humanoid.PlatformStand = false
		end
	end

	function LocomotionService:Initialize()
		TaskScheduler:RegisterHeartbeat("LocomotionUpdate", 10, updateMovement)

		local jumpConn = UserInputService.JumpRequest:Connect(function()
			if StateStore:Get("Movement.InfJump") then
				local myAssets = PlayerTracker:GetLocalAssets()
				if myAssets and myAssets.Humanoid then
					myAssets.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				end
			end
		end)
		Disposer:Add(jumpConn)

		local inputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed or not StateStore:Get("Settings.TpToMouse") then return end

			local isDesktopTrigger = (input.UserInputType == Enum.UserInputType.MouseButton1 and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl))
			local isTouchTrigger = (input.UserInputType == Enum.UserInputType.Touch)

			if isDesktopTrigger or isTouchTrigger then
				local cam = Workspace.CurrentCamera
				local myAssets = PlayerTracker:GetLocalAssets()
				if not cam or not myAssets or not myAssets.RootPart then return end

				local screenPos = (input.UserInputType == Enum.UserInputType.Touch)
					and Vector2.new(input.Position.X, input.Position.Y)
					or UserInputService:GetMouseLocation()

				local unitRay = cam:ViewportPointToRay(screenPos.X, screenPos.Y)
				local rayParams = RaycastParams.new()
				rayParams.FilterType = Enum.RaycastFilterType.Exclude
				rayParams.FilterDescendantsInstances = { myAssets.Character }

				local result = Workspace:Raycast(unitRay.Origin, unitRay.Direction * 1500, rayParams)
				if result then
					myAssets.RootPart.AssemblyLinearVelocity = Vector3.zero
					myAssets.RootPart.AssemblyAngularVelocity = Vector3.zero
					myAssets.RootPart.CFrame = CFrame.new(result.Position + Vector3.new(0, 3, 0))
					StateStore:SetTransient("AntiFlingSuppressUntil", os.clock() + 0.5)
				end
			end
		end)
		Disposer:Add(inputConn)

		Disposer:Add(function()
			self:StopFling()
			if originalHumanoid and originalHumanoid.Parent then
				if originalWalkSpeed ~= nil then originalHumanoid.WalkSpeed = originalWalkSpeed end
				if originalUseJumpPower ~= nil then originalHumanoid.UseJumpPower = originalUseJumpPower end
				if originalJumpPower ~= nil then originalHumanoid.JumpPower = originalJumpPower end
				if originalJumpHeight ~= nil then originalHumanoid.JumpHeight = originalJumpHeight end
			end
		end)
	end

	return LocomotionService
end
