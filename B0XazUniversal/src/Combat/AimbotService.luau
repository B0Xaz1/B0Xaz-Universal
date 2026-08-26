--!strict
-- ══════════════════════════════════════════════════════════════════════════════
-- B0XazUniversal - High-Performance Aimbot Service
-- Features zero-allocation WindMouse physics, linear smoothing, target leading
-- prediction, dynamic CFrame interpolation, and priority camera execution.
-- ══════════════════════════════════════════════════════════════════════════════

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local BODY_PARTS_R6 = {
	Head = "Head", Torso = "Torso", Root = "HumanoidRootPart",
	LeftArm = "Left Arm", RightArm = "Right Arm",
	LeftLeg = "Left Leg", RightLeg = "Right Leg",
}

local BODY_PARTS_R15 = {
	Head = "Head", Torso = "UpperTorso", Root = "HumanoidRootPart",
	LeftArm = "LeftUpperArm", RightArm = "RightUpperArm",
	LeftLeg = "LeftUpperLeg", RightLeg = "RightUpperLeg",
}

return function(services: any)
	local StateStore = services:Get("StateStore")
	local TaskScheduler = services:Get("TaskScheduler")
	local Disposer = services:Get("Disposer")
	local PlayerTracker = services:Get("PlayerTracker")
	local TargetFilter = services:Get("TargetFilter")
	local Environment = services:Get("Environment")

	local LocalPlayer = Players.LocalPlayer
	local AimbotService = {
		_targetPlayer = nil :: Player?,
		_isHoldActive = false,
		_windVelocity = Vector2.zero,
		_subPixelRemainder = Vector2.zero,
	}

	local function isMobile(): boolean
		return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	end

	-- Resolve target HitPart on character model
	local function resolveHitPart(character: Model, desiredKey: string): BasePart?
		if not character then return nil end
		local isR15 = character:FindFirstChild("UpperTorso") ~= nil
		local partMap = isR15 and BODY_PARTS_R15 or BODY_PARTS_R6
		local partName = partMap[desiredKey] or desiredKey

		local found = character:FindFirstChild(partName)
		if found and found:IsA("BasePart") then
			return found
		end
		return character:FindFirstChild("Head") :: BasePart? or character:FindFirstChild("HumanoidRootPart") :: BasePart?
	end

	-- Find closest eligible player within FOV circle
	function AimbotService:GetClosestTarget(): (Player?, BasePart?)
		local aimCfg = StateStore:Get("Aimbot")
		if not aimCfg then return nil, nil end

		local cam = Workspace.CurrentCamera
		if not cam then return nil, nil end

		local mousePos = isMobile()
			and Vector2.new(cam.ViewportSize.X * 0.5, cam.ViewportSize.Y * 0.5)
			or UserInputService:GetMouseLocation()

		local maxFov = tonumber(aimCfg.FOV and aimCfg.FOV.Size) or 150
		local maxFovSq = maxFov * maxFov
		local maxDist = tonumber(aimCfg.MaxDistance) or 1000
		local maxDistSq = maxDist * maxDist

		local myAssets = PlayerTracker:GetLocalAssets()
		local myPos = myAssets and myAssets.RootPart and myAssets.RootPart.Position

		local bestPlayer: Player? = nil
		local bestPart: BasePart? = nil
		local bestDistSq = math.huge

		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer then
				local assets = PlayerTracker:GetPlayerAssets(player)
				if assets and assets.Character and assets.Humanoid.Health > 0 then
					local targetPart = resolveHitPart(assets.Character, aimCfg.Hitpart or "Head")
					if targetPart and targetPart:IsDescendantOf(Workspace) then
						if TargetFilter:ValidateTarget(player, targetPart, aimCfg) then
							local partPos = targetPart.Position

							-- 3D Distance Check
							local distance3DSq = myPos and (myPos - partPos).Magnitude ^ 2 or 0
							if distance3DSq <= maxDistSq then
								local screenPos, onScreen = cam:WorldToViewportPoint(partPos)
								if onScreen and screenPos.Z > 0 then
									local deltaX = mousePos.X - screenPos.X
									local deltaY = mousePos.Y - screenPos.Y
									local screenDistSq = deltaX * deltaX + deltaY * deltaY

									if screenDistSq <= maxFovSq and screenDistSq < bestDistSq then
										bestDistSq = screenDistSq
										bestPlayer = player
										bestPart = targetPart
									end
								end
							end
						end
					end
				end
			end
		end

		return bestPlayer, bestPart
	end

	-- Zero-allocation WindMouse physics step calculation
	local function computeWindMouseDelta(delta: Vector2, alpha: number, dt: number, windStrength: number, windDamping: number): Vector2
		local distance = delta.Magnitude
		if distance < 0.1 then return Vector2.zero end

		local direction = delta.Unit
		local windScale = math.clamp(distance / 150, 0.2, 1.2) * windStrength
		local randomPerturbation = Vector2.new(math.random() * 2 - 1, math.random() * 2 - 1) * windScale

		local damping = math.clamp(windDamping + dt * 1.5, 0.1, 0.95)
		AimbotService._windVelocity = AimbotService._windVelocity * damping + randomPerturbation * (1 - damping)

		local step = delta * alpha + AimbotService._windVelocity * 0.5
		local maxStep = math.max(0.5, math.min(distance, distance * alpha * 1.8 + 0.5))

		if step.Magnitude > maxStep then
			step = step.Unit * maxStep
		end
		if step:Dot(direction) < 0 then
			step = direction * math.min(maxStep, distance * alpha)
		end
		return step
	end

	-- ─────────────────────────────────────────────────────────────────────────
	-- Frame Camera Step Update
	-- ─────────────────────────────────────────────────────────────────────────
	local function onCameraStep(dt: number)
		local aimCfg = StateStore:Get("Aimbot")
		if not aimCfg or not aimCfg.Enabled or not StateStore:HasPermission("Aimbot.Enabled") then
			if AimbotService._targetPlayer ~= nil then
				AimbotService:LockOff()
			end
			return
		end

		-- Lock Mode Evaluation
		if aimCfg.LockMode == "Hold" then
			if not AimbotService._isHoldActive then
				if AimbotService._targetPlayer ~= nil then AimbotService:LockOff() end
				return
			end
		end

		-- Target Refresh
		if not AimbotService._targetPlayer or not PlayerTracker:IsAlive(AimbotService._targetPlayer) then
			local newTarget, _ = AimbotService:GetClosestTarget()
			AimbotService._targetPlayer = newTarget
			StateStore:SetTransient("AimTarget", newTarget)
			StateStore:SetTransient("AimTargetName", newTarget and newTarget.DisplayName or nil)
		end

		local target = AimbotService._targetPlayer
		if not target then return end

		local assets = PlayerTracker:GetPlayerAssets(target)
		local targetPart = assets and resolveHitPart(assets.Character, aimCfg.Hitpart or "Head")
		if not targetPart or not TargetFilter:ValidateTarget(target, targetPart, aimCfg) then
			AimbotService:LockOff()
			return
		end

		local cam = Workspace.CurrentCamera
		if not cam then return end

		-- Prediction Lead Calculation
		local prediction = aimCfg.Prediction or {}
		local px = tonumber(prediction.Horizontal) or 0
		local py = tonumber(prediction.Vertical) or 0
		local vel = targetPart.AssemblyLinearVelocity or Vector3.zero

		local aimWorldPos = targetPart.Position + Vector3.new(vel.X * px, vel.Y * py, vel.Z * px)

		-- Shake Perturbation
		local shake = tonumber(aimCfg.ShakeIntensity) or 0
		if shake > 0 then
			local s = shake * 0.1
			aimWorldPos += Vector3.new((math.random() * 2 - 1) * s, (math.random() * 2 - 1) * s, (math.random() * 2 - 1) * s * 0.2)
		end

		local screenPos, onScreen = cam:WorldToViewportPoint(aimWorldPos)
		if not onScreen or screenPos.Z <= 0 then
			if aimCfg.UnlockOnDeath ~= false then AimbotService:LockOff() end
			return
		end

		local mousePos = isMobile()
			and Vector2.new(cam.ViewportSize.X * 0.5, cam.ViewportSize.Y * 0.5)
			or UserInputService:GetMouseLocation()

		local targetScreen = Vector2.new(screenPos.X, screenPos.Y)
		local delta = targetScreen - mousePos

		-- Break on Mouse Pull
		if aimCfg.BreakOnPull and delta.Magnitude > (aimCfg.MaxLockRadius or 200) then
			AimbotService:LockOff()
			return
		end

		local smoothness = math.clamp(tonumber(aimCfg.Smoothness) or 4, 1, 20)
		local alpha = 1 - math.exp(-dt * (60 
