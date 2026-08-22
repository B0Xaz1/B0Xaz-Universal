local SETTINGS = {
	DEFAULTS = {
		Hitpart = "Head",
		TeamCheck = false,
		VisCheck = false,
		LockMode = "Hold",
		FOV = { Size = 150 },
		MaxDistance = 1000,
		BreakOnPull = false,
		MaxLockRadius = 200,
		Smoothness = 1,
		ShakeIntensity = 0,
		Prediction = {
			Horizontal = 0,
			Vertical = 0,
			X = 0,
			Y = 0,
		},
		Triggerbot = {
			Enabled = false,
			Delay = 0.05,
			Tolerance = 14,
			ClickDuration = 0.02,
		},
	},
	LIMITS = {
		MIN_SMOOTHNESS = 1,
		MAX_SMOOTHNESS = 20,
		DEFAULT_DT = 0.016666666666667,
		TRIGGERBOT_COOLDOWN = 0.1,
		DELTA_THRESHOLD = 0.5,
		MIN_ALPHA = 0,
		MAX_ALPHA = 1,
	},
	BODY_PARTS = {
		R6 = {
			Head = "Head",
			Torso = "Torso",
			Root = "HumanoidRootPart",
			LeftArm = "Left Arm",
			RightArm = "Right Arm",
			LeftLeg = "Left Leg",
			RightLeg = "Right Leg",
		},
		R15 = {
			Head = "Head",
			Torso = "UpperTorso",
			LowerTorso = "LowerTorso",
			Root = "HumanoidRootPart",
			LeftArm = "LeftUpperArm",
			RightArm = "RightUpperArm",
			LeftLeg = "LeftUpperLeg",
			RightLeg = "RightUpperLeg",
		},
	},
	KEY_ALIASES = {
		MB1 = Enum.UserInputType.MouseButton1,
		MOUSEBUTTON1 = Enum.UserInputType.MouseButton1,
		MB2 = Enum.UserInputType.MouseButton2,
		MOUSEBUTTON2 = Enum.UserInputType.MouseButton2,
		MB3 = Enum.UserInputType.MouseButton3,
		MOUSEBUTTON3 = Enum.UserInputType.MouseButton3,
	},
}

return function(Context)
	local Workspace = game:GetService("Workspace")
	local Players = game:GetService("Players")
	local UserInputService = game:GetService("UserInputService")
	local VirtualInputManager = game:GetService("VirtualInputManager")

	local LocalPlayer = Players.LocalPlayer
	local Camera = Workspace.CurrentCamera

	local FeatureConfig = (Context and Context.FeatureConfig) or {}
	local State = (Context and Context.State) or {}
	local Utils = (Context and Context.Utils) or {}
	local Connections = (Context and Context.Connections) or {}

	local AimbotSystem = {}
	local targetPlayer = nil
	local activeHeldInputs = {}
	local isTriggerbotRunning = false
	local lastTriggerbotTime = 0

	local function getHitPart(character)
		if not character or not character.Parent then
			return nil
		end
		local aimConfig = FeatureConfig.Aimbot or SETTINGS.DEFAULTS
		local hitpartKey = aimConfig.Hitpart or SETTINGS.DEFAULTS.Hitpart
		local isR15 = character:FindFirstChild("UpperTorso") ~= nil
		local partMap = isR15 and SETTINGS.BODY_PARTS.R15 or SETTINGS.BODY_PARTS.R6
		local partName = partMap[hitpartKey] or hitpartKey

		return character:FindFirstChild(partName)
			or character:FindFirstChild("Head")
			or character:FindFirstChild("HumanoidRootPart")
	end

	local function isTeammate(player)
		local aimConfig = FeatureConfig.Aimbot
		if not (aimConfig and aimConfig.TeamCheck) then
			return false
		end
		return Utils.SameTeam and Utils.SameTeam(player) or false
	end

	local function isVisible(part)
		local aimConfig = FeatureConfig.Aimbot
		if not (aimConfig and aimConfig.VisCheck) then
			return true
		end
		if not part then
			return false
		end
		return Utils.IsVisible and Utils.IsVisible(part) or true
	end

	local function matchesBind(input, bindItem)
		if bindItem == nil then
			return false
		end
		local itemType = typeof(bindItem)

		if itemType == "string" then
			local resolvedAlias = SETTINGS.KEY_ALIASES[bindItem:upper()]
			if resolvedAlias then
				return input.UserInputType == resolvedAlias
			end
			local keyCode = Utils.GetKeyCode and Utils.GetKeyCode(bindItem)
			return keyCode ~= nil and input.KeyCode == keyCode
		elseif itemType == "EnumItem" then
			if bindItem.EnumType == Enum.KeyCode then
				return input.KeyCode == bindItem
			elseif bindItem.EnumType == Enum.UserInputType then
				return input.UserInputType == bindItem
			end
		end

		return false
	end

	local function getMatchingBind(input)
		local aimConfig = FeatureConfig.Aimbot
		if not aimConfig then
			return nil
		end
		local keybind = aimConfig.Keybind

		if typeof(keybind) == "table" then
			for _, bindItem in ipairs(keybind) do
				if matchesBind(input, bindItem) then
					return bindItem
				end
			end
			return nil
		end

		if matchesBind(input, keybind) then
			return keybind
		end

		return nil
	end

	local function isAnyKeyHeld()
		return next(activeHeldInputs) ~= nil
	end

	local function getClosestPlayer()
		local aimConfig = FeatureConfig.Aimbot or SETTINGS.DEFAULTS
		local closestDistance = math.huge
		local closestCandidate = nil
		local mousePosition = UserInputService:GetMouseLocation()
		local maxFovRadius = (aimConfig.FOV and aimConfig.FOV.Size) or SETTINGS.DEFAULTS.FOV.Size
		local localAssets = Utils.GetPlayerAssets and Utils.GetPlayerAssets(LocalPlayer)

		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and not isTeammate(player) then
				local assets = Utils.GetPlayerAssets and Utils.GetPlayerAssets(player)
				if assets and assets.Character then
					local hitPart = getHitPart(assets.Character)
					if hitPart and hitPart:IsDescendantOf(Workspace) and isVisible(hitPart) then
						local screenPos, onScreen = Camera:WorldToViewportPoint(hitPart.Position)
						if onScreen and screenPos.Z > 0 then
							local distance2D = (mousePosition - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
							if distance2D <= maxFovRadius then
								local isWithinMaxDistance = true
								if localAssets and localAssets.RootPart and aimConfig.MaxDistance then
									local worldDistance = (localAssets.RootPart.Position - hitPart.Position).Magnitude
									if worldDistance > aimConfig.MaxDistance then
										isWithinMaxDistance = false
									end
								end

								if isWithinMaxDistance and distance2D < closestDistance then
									closestDistance = distance2D
									closestCandidate = player
								end
							end
						end
					end
				end
			end
		end

		return closestCandidate
	end

	local function setTarget(player)
		local aimConfig = FeatureConfig.Aimbot or SETTINGS.DEFAULTS
		targetPlayer = player
		State.AimTarget = player
		State.AimLocked = player ~= nil
		State.AimHoldActive = (player ~= nil and aimConfig.LockMode == "Hold")
	end

	function AimbotSystem.LockOn()
		local target = getClosestPlayer()
		setTarget(target)
		return target ~= nil
	end

	function AimbotSystem.LockOff()
		setTarget(nil)
		table.clear(activeHeldInputs)
	end

	function AimbotSystem.GetClosestTarget()
		return getClosestPlayer()
	end

	function AimbotSystem.UpdateAim(deltaTime)
		local aimConfig = FeatureConfig.Aimbot
		if not (aimConfig and aimConfig.Enabled) then
			return
		end
		local dt = deltaTime or SETTINGS.LIMITS.DEFAULT_DT

		if aimConfig.LockMode == "Hold" then
			if isAnyKeyHeld() then
				local assets = targetPlayer and Utils.GetPlayerAssets and Utils.GetPlayerAssets(targetPlayer)
				if not assets then
					local target = getClosestPlayer()
					if target then
						setTarget(target)
					end
				end
			else
				if targetPlayer then
					setTarget(nil)
				end
				return
			end
		end

		if not targetPlayer then
			return
		end

		local assets = Utils.GetPlayerAssets and Utils.GetPlayerAssets(targetPlayer)
		if not (assets and assets.Character) then
			setTarget(nil)
			return
		end

		local hitPart = getHitPart(assets.Character)
		if not (hitPart and hitPart:IsDescendantOf(Workspace) and isVisible(hitPart)) then
			setTarget(nil)
			return
		end

		local mousePosition = UserInputService:GetMouseLocation()
		local screenPos, onScreen = Camera:WorldToViewportPoint(hitPart.Position)
		if not onScreen or screenPos.Z <= 0 then
			setTarget(nil)
			return
		end

		local targetScreenVector = Vector2.new(screenPos.X, screenPos.Y)
		local crosshairDelta = targetScreenVector - mousePosition

		if aimConfig.BreakOnPull then
			local maxRadius = aimConfig.MaxLockRadius or SETTINGS.DEFAULTS.MaxLockRadius
			if crosshairDelta.Magnitude > maxRadius then
				setTarget(nil)
				return
			end
		end

		local prediction = aimConfig.Prediction or SETTINGS.DEFAULTS.Prediction
		local predX = prediction.Horizontal or prediction.X or 0
		local predY = prediction.Vertical or prediction.Y or 0
		local velocity = hitPart.AssemblyLinearVelocity or hitPart.Velocity or Vector3.zero
		local predictedPosition = hitPart.Position + Vector3.new(velocity.X * predX, velocity.Y * predY, velocity.Z * predX)

		local shakeIntensity = aimConfig.ShakeIntensity or SETTINGS.DEFAULTS.ShakeIntensity
		if shakeIntensity > 0 then
			local scale = shakeIntensity / 10
			predictedPosition = predictedPosition + Vector3.new(
				(math.random() * 2 - 1) * scale,
				(math.random() * 2 - 1) * scale,
				0
			)
		end

		local rawSmoothness = tonumber(aimConfig.Smoothness) or SETTINGS.DEFAULTS.Smoothness
		local smoothness = math.clamp(rawSmoothness, SETTINGS.LIMITS.MIN_SMOOTHNESS, SETTINGS.LIMITS.MAX_SMOOTHNESS)
		local alpha = math.clamp(dt * (60 / smoothness), SETTINGS.LIMITS.MIN_ALPHA, SETTINGS.LIMITS.MAX_ALPHA)

		if crosshairDelta.Magnitude > SETTINGS.LIMITS.DELTA_THRESHOLD then
			local step = crosshairDelta * alpha
			local moved = false
			if mousemoverel then
				moved = pcall(mousemoverel, step.X, step.Y)
			end
			if not moved then
				local targetCFrame = CFrame.new(Camera.CFrame.Position, predictedPosition)
				Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, alpha)
			end
		else
			local targetCFrame = CFrame.new(Camera.CFrame.Position, predictedPosition)
			Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, alpha)
		end
	end

	function AimbotSystem.UpdateTriggerbot()
		local aimConfig = FeatureConfig.Aimbot
		if not (aimConfig and aimConfig.Enabled and aimConfig.Triggerbot and aimConfig.Triggerbot.Enabled) then
			return
		end

		local currentTime = os.clock()
		if isTriggerbotRunning or (currentTime - lastTriggerbotTime) < SETTINGS.LIMITS.TRIGGERBOT_COOLDOWN then
			return
		end

		local mousePos = Utils.GetMousePosition and Utils.GetMousePosition() or UserInputService:GetMouseLocation()
		local triggerTolerance = aimConfig.Triggerbot.Tolerance or SETTINGS.DEFAULTS.Triggerbot.Tolerance

		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and not isTeammate(player) then
				local assets = Utils.GetPlayerAssets and Utils.GetPlayerAssets(player)
				if assets and assets.Character then
					for _, part in ipairs(assets.Character:GetChildren()) do
						if part:IsA("BasePart") then
							local screenPos, onScreen, depth
							if Utils.WorldToScreen then
								screenPos, onScreen, depth = Utils.WorldToScreen(part.Position)
							else
								local v, visible = Camera:WorldToViewportPoint(part.Position)
								screenPos = Vector2.new(v.X, v.Y)
								onScreen = visible
								depth = v.Z
							end

							if onScreen and depth > 0 and (mousePos - screenPos).Magnitude <= triggerTolerance then
								isTriggerbotRunning = true
								lastTriggerbotTime = currentTime
								local triggerDelay = aimConfig.Triggerbot.Delay or SETTINGS.DEFAULTS.Triggerbot.Delay

								task.delay(triggerDelay, function()
									if FeatureConfig.Aimbot and FeatureConfig.Aimbot.Triggerbot and FeatureConfig.Aimbot.Triggerbot.Enabled then
										if mouse1click then
											pcall(mouse1click)
										else
											pcall(function()
												VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
												task.wait(SETTINGS.DEFAULTS.Triggerbot.ClickDuration)
												VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
											end)
										end
									end
									isTriggerbotRunning = false
								end)
								return
							end
						end
					end
				end
			end
		end
	end

	if Connections and Connections.Add then
		Connections.Add(UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then
				return
			end
			local aimConfig = FeatureConfig.Aimbot
			if not (aimConfig and aimConfig.Enabled) then
				return
			end

			local matched = getMatchingBind(input)
			if not matched then
				return
			end

			activeHeldInputs[tostring(matched)] = true

			if aimConfig.LockMode == "Toggle" then
				if targetPlayer then
					AimbotSystem.LockOff()
				else
					AimbotSystem.LockOn()
				end
			else
				AimbotSystem.LockOn()
			end
		end))

		Connections.Add(UserInputService.InputEnded:Connect(function(input)
			local matched = getMatchingBind(input)
			if not matched then
				return
			end

			activeHeldInputs[tostring(matched)] = nil

			local aimConfig = FeatureConfig.Aimbot or SETTINGS.DEFAULTS
			if aimConfig.LockMode == "Hold" and not isAnyKeyHeld() then
				AimbotSystem.LockOff()
			end
		end))

		Connections.Add(Players.PlayerRemoving:Connect(function(player)
			if player == targetPlayer then
				AimbotSystem.LockOff()
			end
		end))
	end

	return AimbotSystem
end
