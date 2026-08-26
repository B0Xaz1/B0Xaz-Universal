--!strict
-- ══════════════════════════════════════════════════════════════════════════════
-- B0XazUniversal - Locomotion & Movement Physics Service
-- Consolidates WalkSpeed, JumpPower, Infinite Jump, CFrame displacement,
-- fling attack execution, click-to-teleport, and position bookmarks.
-- ══════════════════════════════════════════════════════════════════════════════

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

	local originalHumanoid: Humanoid? = nil
	local originalWalkSpeed: number? = nil
	local originalUseJumpPower: boolean? = nil
	local originalJumpPower: number? = nil
	local originalJumpHeight: number? = nil

	-- ─────────────────────────────────────────────────────────────────────────
	-- Physics Updates (Heartbeat & Pre-Simulation)
	-- ─────────────────────────────────────────────────────────────────────────
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

		-- 1. Sprint & Base Speed Enforcement
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

		-- 2. Jump Power
		if movSettings.JumpPower and hum.JumpPower ~= movSettings.JumpPower then
			hum.UseJumpPower = true
			hum.JumpPower = movSettings.JumpPower
		end

		-- 3. CFrame Velocity Displacement
		if movSettings.CFrameSpeed and not movSettings.FlyEnabled then
			local moveDir = hum.MoveDirection
			-- Fall back to keyboard direction when an executor/game makes
			-- Humanoid.MoveDirection unavailable or stale.
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

		-- 4. Target Fling Physics Injection
		if LocomotionService._flingActive and LocomotionService._flingTarget then
			local targetAssets = PlayerTracker:GetPlayerAssets(LocomotionService._flingTarget)
			if targetAssets and targetAssets.RootPart then
				root.CFrame = targetAssets.RootPart.CFrame
				local currentVel = root.AssemblyLinearVelocity
				root.AssemblyLinearVelocity = currentVel * 10000 + Vector3.new(0, 10000, 0)
			else
				LocomotionService:StopFling()
			end
		end
	end

	-- ─────────────────────────────────────────────────────────────────────────
	-- Teleportation & Raycasting
	-- ─────────────────────────────────────────────────────────────────────────
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
			myAssets.RootPart.AssemblyLinearVelocity = Vector3.zero
			myAssets.RootPart.AssemblyAngularVelocity = Vector3.zero
			myAssets.RootPart.CFrame = saved
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

	-- ─────────────────────────────────────────────────────────────────────────
	-- Initialization & Event Bindings
	-- ─────────────────────────────────────────────────────────────────────────
	function LocomotionService:Initialize()
		-- Register Heartbeat Task
		TaskScheduler:RegisterHeartbeat("LocomotionUpdate", 10, updateMovement)

		-- Infinite Jump Listener
		local jumpConn = UserInputService.JumpRequest:Connect(function()
			if StateStore:Get("Movement.InfJump") then
				local myAssets = PlayerTracker:GetLocalAssets()
				if myAssets and myAssets.Humanoid then
					myAssets.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				end
			end
		end)
		Disposer:Add(jumpConn)

		-- Click / Tap to Teleport Listener
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
