-- // src/Systems/AimbotSystem.lua
return function(Context)
	local Workspace = game:GetService("Workspace")
	local Players = game:GetService("Players")
	local UserInputService = game:GetService("UserInputService")
	local VirtualInputManager = game:GetService("VirtualInputManager")

	local LocalPlayer = Players.LocalPlayer
	local FeatureConfig = Context.FeatureConfig or {}
	local State = Context.State or {}
	local Utils = Context.Utils or {}
	local Connections = Context.Connections or {}

	local BODY = {
		R6 = {
			Head = "Head", Torso = "Torso", Root = "HumanoidRootPart",
			LeftArm = "Left Arm", RightArm = "Right Arm",
			LeftLeg = "Left Leg", RightLeg = "Right Leg",
		},
		R15 = {
			Head = "Head", Torso = "UpperTorso", LowerTorso = "LowerTorso",
			Root = "HumanoidRootPart",
			LeftArm = "LeftUpperArm", RightArm = "RightUpperArm",
			LeftLeg = "LeftUpperLeg", RightLeg = "RightUpperLeg",
		},
	}

	local KEY_ALIASES = {
		MB1 = Enum.UserInputType.MouseButton1,
		MOUSEBUTTON1 = Enum.UserInputType.MouseButton1,
		MB2 = Enum.UserInputType.MouseButton2,
		MOUSEBUTTON2 = Enum.UserInputType.MouseButton2,
		MB3 = Enum.UserInputType.MouseButton3,
		MOUSEBUTTON3 = Enum.UserInputType.MouseButton3,
	}

	local AimbotSystem = {}
	local targetPlayer = nil
	local heldInputs = {}
	local triggerRunning = false
	local lastTrigger = 0

	local function getCamera()
		return Workspace.CurrentCamera
	end

	local function getHitPart(character)
		if not character or not character.Parent then return nil end
		local cfg = FeatureConfig.Aimbot or {}
		local key = cfg.Hitpart or "Head"
		local isR15 = character:FindFirstChild("UpperTorso") ~= nil
		local map = isR15 and BODY.R15 or BODY.R6
		local name = map[key] or key
		return character:FindFirstChild(name)
			or character:FindFirstChild("Head")
			or character:FindFirstChild("HumanoidRootPart")
	end

	local function isTeammate(player)
		local cfg = FeatureConfig.Aimbot
		if not (cfg and cfg.TeamCheck) then return false end
		return Utils.SameTeam and Utils.SameTeam(player) or false
	end

	local function isVisible(part)
		local cfg = FeatureConfig.Aimbot
		if not (cfg and cfg.VisCheck) then return true end
		if not part then return false end
		if Utils.IsVisible then return Utils.IsVisible(part) end
		return true
	end

	local function matchesBind(input, bind)
		if bind == nil then return false end
		local t = typeof(bind)
		if t == "string" then
			local alias = KEY_ALIASES[bind:upper()]
			if alias then return input.UserInputType == alias end
			local kc = Utils.GetKeyCode and Utils.GetKeyCode(bind)
			return kc ~= nil and input.KeyCode == kc
		elseif t == "EnumItem" then
			if bind.EnumType == Enum.KeyCode then
				return input.KeyCode == bind
			elseif bind.EnumType == Enum.UserInputType then
				return input.UserInputType == bind
			end
		end
		return false
	end

	local function getMatchingBind(input)
		local cfg = FeatureConfig.Aimbot
		if not cfg then return nil end
		local kb = cfg.Keybind
		if typeof(kb) == "table" then
			for _, item in ipairs(kb) do
				if matchesBind(input, item) then return item end
			end
			return nil
		end
		if matchesBind(input, kb) then return kb end
		return nil
	end

	local function anyHeld()
		return next(heldInputs) ~= nil
	end

	local function getClosest()
		local cfg = FeatureConfig.Aimbot or {}
		local bestDist, best = math.huge, nil
		local mouse = UserInputService:GetMouseLocation()
		local maxFov = (cfg.FOV and cfg.FOV.Size) or 150
		local cam = getCamera()
		if not cam then return nil end
		local myAssets = Utils.GetPlayerAssets and Utils.GetPlayerAssets(LocalPlayer)

		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and not isTeammate(player) then
				local assets = Utils.GetPlayerAssets and Utils.GetPlayerAssets(player)
				if assets and assets.Character then
					local hit = getHitPart(assets.Character)
					if hit and hit:IsDescendantOf(Workspace) and isVisible(hit) then
						local sp, onScreen = cam:WorldToViewportPoint(hit.Position)
						if onScreen and sp.Z > 0 then
							local d2 = (mouse - Vector2.new(sp.X, sp.Y)).Magnitude
							if d2 <= maxFov then
								local ok = true
								if myAssets and myAssets.RootPart and cfg.MaxDistance then
									if (myAssets.RootPart.Position - hit.Position).Magnitude > cfg.MaxDistance then
										ok = false
									end
								end
								if ok and d2 < bestDist then
									bestDist = d2
									best = player
								end
							end
						end
					end
				end
			end
		end
		return best
	end

	local function setTarget(player)
		local cfg = FeatureConfig.Aimbot or {}
		targetPlayer = player
		State.AimTarget = player
		State.AimLocked = player ~= nil
		State.AimHoldActive = (player ~= nil and cfg.LockMode == "Hold")
	end

	function AimbotSystem.LockOn()
		local t = getClosest()
		setTarget(t)
		return t ~= nil
	end

	function AimbotSystem.LockOff()
		setTarget(nil)
		table.clear(heldInputs)
	end

	function AimbotSystem.GetClosestTarget()
		return getClosest()
	end

	function AimbotSystem.UpdateAim(dt)
		local cfg = FeatureConfig.Aimbot
		if not (cfg and cfg.Enabled) then return end
		dt = dt or (1 / 60)
		local cam = getCamera()
		if not cam then return end

		if cfg.LockMode == "Hold" then
			if anyHeld() then
				local assets = targetPlayer and Utils.GetPlayerAssets and Utils.GetPlayerAssets(targetPlayer)
				if not assets then
					local t = getClosest()
					if t then setTarget(t) end
				end
			else
				if targetPlayer then setTarget(nil) end
				return
			end
		end

		if not targetPlayer then return end
		local assets = Utils.GetPlayerAssets and Utils.GetPlayerAssets(targetPlayer)
		if not (assets and assets.Character) then setTarget(nil) return end

		local hit = getHitPart(assets.Character)
		if not (hit and hit:IsDescendantOf(Workspace) and isVisible(hit)) then
			setTarget(nil) return
		end

		local mouse = UserInputService:GetMouseLocation()
		local sp, onScreen = cam:WorldToViewportPoint(hit.Position)
		if not onScreen or sp.Z <= 0 then setTarget(nil) return end

		local targetScreen = Vector2.new(sp.X, sp.Y)
		local delta = targetScreen - mouse

		if cfg.BreakOnPull then
			if delta.Magnitude > (cfg.MaxLockRadius or 200) then
				setTarget(nil) return
			end
		end

		local pred = cfg.Prediction or {}
		local px = pred.Horizontal or pred.X or 0
		local py = pred.Vertical or pred.Y or 0
		local vel = hit.AssemblyLinearVelocity or hit.Velocity or Vector3.zero
		local predicted = hit.Position + Vector3.new(vel.X * px, vel.Y * py, vel.Z * px)

		local shake = cfg.ShakeIntensity or 0
		if shake > 0 then
			local s = shake / 10
			predicted = predicted + Vector3.new((math.random() * 2 - 1) * s, (math.random() * 2 - 1) * s, 0)
		end

		local smooth = math.clamp(tonumber(cfg.Smoothness) or 4, 1, 20)
		local alpha = math.clamp(dt * (60 / smooth), 0, 1)

		if delta.Magnitude > 0.5 then
			local step = delta * alpha
			local moved = false
			if mousemoverel then
				moved = pcall(mousemoverel, step.X, step.Y)
			end
			if not moved then
				local targetCF = CFrame.new(cam.CFrame.Position, predicted)
				cam.CFrame = cam.CFrame:Lerp(targetCF, alpha)
			end
		else
			local targetCF = CFrame.new(cam.CFrame.Position, predicted)
			cam.CFrame = cam.CFrame:Lerp(targetCF, alpha)
		end
	end

	function AimbotSystem.UpdateTriggerbot()
		local cfg = FeatureConfig.Aimbot
		if not (cfg and cfg.Enabled and cfg.Triggerbot and cfg.Triggerbot.Enabled) then return end

		local now = os.clock()
		if triggerRunning or (now - lastTrigger) < 0.1 then return end

		local mouse = Utils.GetMousePosition and Utils.GetMousePosition() or UserInputService:GetMouseLocation()
		local tol = cfg.Triggerbot.Tolerance or 14
		local cam = getCamera()
		if not cam then return end

		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and not isTeammate(player) then
				local assets = Utils.GetPlayerAssets and Utils.GetPlayerAssets(player)
				if assets and assets.Character then
					for _, part in ipairs(assets.Character:GetChildren()) do
						if part:IsA("BasePart") then
							local sp, onScreen = cam:WorldToViewportPoint(part.Position)
							if onScreen and sp.Z > 0 and (mouse - Vector2.new(sp.X, sp.Y)).Magnitude <= tol then
								triggerRunning = true
								lastTrigger = now
								local delay = cfg.Triggerbot.Delay or 0.05
								task.delay(delay, function()
									if FeatureConfig.Aimbot and FeatureConfig.Aimbot.Triggerbot and FeatureConfig.Aimbot.Triggerbot.Enabled then
										if mouse1click then
											pcall(mouse1click)
										else
											pcall(function()
												VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
												task.wait(0.02)
												VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
											end)
										end
									end
									triggerRunning = false
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
		Connections.Add(UserInputService.InputBegan:Connect(function(input, gp)
			if gp then return end
			local cfg = FeatureConfig.Aimbot
			if not (cfg and cfg.Enabled) then return end
			local matched = getMatchingBind(input)
			if not matched then return end
			heldInputs[tostring(matched)] = true
			if cfg.LockMode == "Toggle" then
				if targetPlayer then AimbotSystem.LockOff() else AimbotSystem.LockOn() end
			else
				AimbotSystem.LockOn()
			end
		end))

		Connections.Add(UserInputService.InputEnded:Connect(function(input)
			local matched = getMatchingBind(input)
			if not matched then return end
			heldInputs[tostring(matched)] = nil
			local cfg = FeatureConfig.Aimbot or {}
			if cfg.LockMode == "Hold" and not anyHeld() then
				AimbotSystem.LockOff()
			end
		end))

		Connections.Add(Players.PlayerRemoving:Connect(function(player)
			if player == targetPlayer then AimbotSystem.LockOff() end
		end))
	end

	return AimbotSystem
end
