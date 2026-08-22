local SETTINGS = {
	DEFAULTS = {
		DoorPhase = false,
		DoorGlow = true,
		GlowColor = Color3.fromRGB(0, 200, 220),
		PhaseTransparency = 0.65,
		NoSpread = false,
		FastFire = false,
		ForceAuto = false,
		ForceRange = false,
		FireRateValue = 0.001,
		RangeValue = 10000,
		FakeMacro = false,
		FakeMacroKey = Enum.KeyCode.V,
		FakeMacroMode = "Toggle",
		FakeMacroDelay = 0.03,
		AntiRestrict = false,
		PunchAura = false,
		PunchAuraRange = 15,
		SuperPunch = false,
		SuperPunchHits = 10,
	},
	LIMITS = {
		PUNCH_AURA_INTERVAL = 0.1,
		SUPER_PUNCH_COOLDOWN = 0.15,
		MIN_MACRO_DELAY = 0.01,
		MAX_MACRO_DELAY = 0.5,
		MIN_SUPER_PUNCH_HITS = 1,
		MAX_SUPER_PUNCH_HITS = 30,
		MIN_PUNCH_AURA_RANGE = 5,
		MAX_PUNCH_AURA_RANGE = 40,
		MIN_PHASE_TRANSPARENCY = 0.1,
		MAX_PHASE_TRANSPARENCY = 0.95,
		GUN_GRAB_WAIT = 1.3,
		CRIMINAL_SWITCH_WAIT = 3.5,
		WARNING_COUNTDOWN = 3,
		WARNING_HOLD_TIME = 2.0,
	},
	LOCATIONS = {
		{ "Prison Cells", CFrame.new(920, 98, 2436) },
		{ "Cafeteria", CFrame.new(920, 98, 2290) },
		{ "Prison Yard", CFrame.new(779, 98, 2463) },
		{ "Criminal Base", CFrame.new(-943, 95, 2058) },
		{ "Police Armory", CFrame.new(831, 98, 2284) },
		{ "Parking Lot", CFrame.new(745, 98, 2148) },
		{ "Roof", CFrame.new(845, 130, 2235) },
		{ "Secret Room", CFrame.new(674, 98, 2384) },
		{ "Tunnels", CFrame.new(918, 80, 2284) },
		{ "Outside of Prison", CFrame.new(451.67, 98.04, 2216.34) },
		{ "Kitchen", CFrame.new(906.64, 99.99, 2237.67) },
		{ "Break Room", CFrame.new(800.09, 99.99, 2266.72) },
	},
	GUN_SPAWNS = {
		["MP5"] = Vector3.new(813.72, 102.50, 2229.37),
		["Remington 870"] = Vector3.new(820.27, 102.50, 2229.31),
		["AK-47"] = Vector3.new(-932, 100.74, 2039.5),
	},
	DOOR_FOLDERS = { "doors", "glass", "celldoors", "prison_fences", "prison_gate" },
	PRISON_GUNS = { "Remington 870", "M9", "AK-47", "Taser", "M4A1", "MP5" },
	GUN_ATTRIBUTES = { "SpreadRadius", "FireRate", "AutoFire", "Range" },
	RESTRICTED_GUIS = { "Taser", "Flashbang", "Cuffs" },
	CRIMINAL_BASE_POS = Vector3.new(-943, 95, 2058),
	DEFAULT_WALKSPEED = 16,
	DEFAULT_JUMPPOWER = 50,
	THEME_FALLBACKS = {
		Danger = Color3.fromRGB(220, 80, 80),
		Success = Color3.fromRGB(80, 220, 80),
		Accent = Color3.fromRGB(0, 200, 220),
		Bg = Color3.fromRGB(20, 20, 20),
		Side = Color3.fromRGB(25, 25, 25),
		Panel = Color3.fromRGB(30, 30, 30),
		Border = Color3.fromRGB(45, 45, 45),
		BorderDim = Color3.fromRGB(35, 35, 35),
		Elem = Color3.fromRGB(35, 35, 35),
		ElemHover = Color3.fromRGB(45, 45, 45),
		Text = Color3.fromRGB(255, 255, 255),
		TextDim = Color3.fromRGB(180, 180, 180),
		TextMuted = Color3.fromRGB(120, 120, 120),
	},
}

return function(Context)
	local Workspace = game:GetService("Workspace")
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local LocalPlayer = Players.LocalPlayer
	local FeatureConfig = Context and Context.FeatureConfig or {}
	local Theme = Context and Context.Theme or {}
	local Connections = Context and Context.Connections or {}
	local UIRegistry = Context and Context.UIRegistry or {}
	local Utils = Context and Context.Utils or {}

	if not FeatureConfig.Game then
		FeatureConfig.Game = {}
	end
	for key, value in pairs(SETTINGS.DEFAULTS) do
		if FeatureConfig.Game[key] == nil then
			FeatureConfig.Game[key] = value
		end
	end

	local function getThemeColor(key)
		return Theme[key] or SETTINGS.THEME_FALLBACKS[key] or Color3.fromRGB(255, 255, 255)
	end

	local doorFolderLookup = {}
	for _, folderName in ipairs(SETTINGS.DOOR_FOLDERS) do
		doorFolderLookup[folderName] = true
	end

	local prisonGunsLookup = {}
	for _, gunName in ipairs(SETTINGS.PRISON_GUNS) do
		prisonGunsLookup[gunName] = true
	end

	local doorCache = getgenv().B0XazDoorCache or {}
	getgenv().B0XazDoorCache = doorCache
	local doorPartsSet = getgenv().B0XazDoorParts or {}
	getgenv().B0XazDoorParts = doorPartsSet
	local gunCache = getgenv().B0XazGunCache or {}
	getgenv().B0XazGunCache = gunCache

	local Game = { Name = "Prison Life" }

	local macroLoopActive = false
	local macroThread = nil
	local currentToolIndex = 1
	local isKeyPressed = false
	local isTeleporting = false
	local hasAcceptedBannableWarning = false
	local lastPunchAuraTime = 0
	local lastSuperPunchTime = 0

	local MeleeEvent = ReplicatedStorage:FindFirstChild("meleeEvent")

	local function notify(title, message, duration, color)
		if Context and Context.UI and Context.UI.Notify then
			Context.UI:Notify(title, message, duration, color)
		end
	end

	local function fireMelee(targetPlayer)
		if not MeleeEvent then
			MeleeEvent = ReplicatedStorage:FindFirstChild("meleeEvent")
		end
		if MeleeEvent then
			pcall(function()
				if targetPlayer then
					MeleeEvent:FireServer(targetPlayer)
				else
					MeleeEvent:FireServer()
				end
			end)
		end
	end

	local function performWarpAction(targetPosition, waitTime, startMsg, successMsg, notifyTag)
		if isTeleporting then return end
		local root = Utils.GetRootPart and Utils.GetRootPart()
		if not root then
			notify(notifyTag, "Character root not found", nil, getThemeColor("Danger"))
			return
		end

		isTeleporting = true
		local originalCFrame = root.CFrame

		if startMsg then
			notify(notifyTag, startMsg, waitTime, getThemeColor("Accent"))
		end

		root.CFrame = CFrame.new(targetPosition)
		task.wait(waitTime)

		local currentRoot = Utils.GetRootPart and Utils.GetRootPart()
		if currentRoot then
			currentRoot.CFrame = originalCFrame
			if successMsg then
				notify(notifyTag, successMsg, 2, getThemeColor("Success"))
			end
		end

		isTeleporting = false
	end

	local function grabGun(gunName, targetPos)
		performWarpAction(
			targetPos,
			SETTINGS.LIMITS.GUN_GRAB_WAIT,
			"Acquiring " .. gunName .. "...",
			gunName .. " acquired!",
			"Gun Grabber"
		)
	end

	function Game.BecomeCriminalInside()
		performWarpAction(
			SETTINGS.CRIMINAL_BASE_POS,
			SETTINGS.LIMITS.CRIMINAL_SWITCH_WAIT,
			"Becoming Criminal (Returning in 3.5s)...",
			"Returned Inside as Criminal!",
			"Prison Life"
		)
	end

	function Game.BecomeCriminalOutside()
		if isTeleporting then return end
		local root = Utils.GetRootPart and Utils.GetRootPart()
		if not root then return end
		root.CFrame = CFrame.new(SETTINGS.CRIMINAL_BASE_POS)
		notify("Prison Life", "Warped Outside to Criminal Base!", 2, getThemeColor("Success"))
	end

	local function runPunchAura()
		if not FeatureConfig.Game.PunchAura then return end
		local now = os.clock()
		if (now - lastPunchAuraTime) < SETTINGS.LIMITS.PUNCH_AURA_INTERVAL then return end
		lastPunchAuraTime = now

		local myRoot = Utils.GetRootPart and Utils.GetRootPart()
		if not myRoot then return end

		local maxDist = math.clamp(
			FeatureConfig.Game.PunchAuraRange or SETTINGS.DEFAULTS.PunchAuraRange,
			SETTINGS.LIMITS.MIN_PUNCH_AURA_RANGE,
			SETTINGS.LIMITS.MAX_PUNCH_AURA_RANGE
		)

		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and Utils.IsAlive and Utils.IsAlive(player) and not (Utils.SameTeam and Utils.SameTeam(player)) then
				local character = player.Character
				local targetRoot = character and character:FindFirstChild("HumanoidRootPart")
				if targetRoot and (targetRoot.Position - myRoot.Position).Magnitude <= maxDist then
					fireMelee(player)
				end
			end
		end
	end

	local function isInsideVendingModel(object)
		local current = object
		while current and current ~= Workspace do
			if current:IsA("Model") and current.Name == "Model" and current.Parent and current.Parent.Name == "vending machine" then
				return true
			end
			current = current.Parent
		end
		return false
	end

	local function isDoorPart(part)
		if not part or not part:IsA("BasePart") then return false end
		if isInsideVendingModel(part) then return true end
		local current = part.Parent
		while current and current ~= Workspace do
			if doorFolderLookup[current.Name:lower()] then
				return true
			end
			current = current.Parent
		end
		return false
	end

	local function restorePart(part)
		local cached = doorCache[part]
		if cached and part and part.Parent then
			pcall(function()
				part.CanCollide = cached.CanCollide
				part.Transparency = cached.Transparency
				part.Color = cached.Color
				part.Material = cached.Material
			end)
		end
		doorCache[part] = nil
		doorPartsSet[part] = nil
	end

	local function restoreAllDoors()
		for part in pairs(doorCache) do
			restorePart(part)
		end
		table.clear(doorCache)
		table.clear(doorPartsSet)
	end

	local function cachePart(part)
		if doorCache[part] then return end
		doorCache[part] = {
			CanCollide = part.CanCollide,
			Transparency = part.Transparency,
			Color = part.Color,
			Material = part.Material,
		}
	end

	local function processPart(part)
		if not isDoorPart(part) then return end
		cachePart(part)
		doorPartsSet[part] = true
	end

	local function scanAllDoors()
		for _, folderName in ipairs(SETTINGS.DOOR_FOLDERS) do
			for _, child in ipairs(Workspace:GetChildren()) do
				if child.Name:lower() == folderName then
					for _, descendant in ipairs(child:GetDescendants()) do
						if descendant:IsA("BasePart") then
							processPart(descendant)
						end
					end
				end
			end
		end
		for _, object in ipairs(Workspace:GetDescendants()) do
			if object:IsA("BasePart") and isInsideVendingModel(object) then
				processPart(object)
			end
		end
	end

	local function enforcePart(part)
		local cached = doorCache[part]
		if not cached or not part or not part.Parent then
			doorPartsSet[part] = nil
			doorCache[part] = nil
			return
		end
		if not FeatureConfig.Game.DoorPhase then return end

		pcall(function()
			if part.CanCollide then
				part.CanCollide = false
			end
			local targetTrans = math.clamp(
				FeatureConfig.Game.PhaseTransparency or SETTINGS.DEFAULTS.PhaseTransparency,
				SETTINGS.LIMITS.MIN_PHASE_TRANSPARENCY,
				SETTINGS.LIMITS.MAX_PHASE_TRANSPARENCY
			)
			if math.abs(part.Transparency - targetTrans) > 0.01 then
				part.Transparency = targetTrans
			end
			if FeatureConfig.Game.DoorGlow then
				local glowColor = FeatureConfig.Game.GlowColor or SETTINGS.DEFAULTS.GlowColor
				if part.Material ~= Enum.Material.Neon then
					part.Material = Enum.Material.Neon
				end
				if part.Color ~= glowColor then
					part.Color = glowColor
				end
			else
				if part.Material ~= cached.Material then
					part.Material = cached.Material
				end
				if part.Color ~= cached.Color then
					part.Color = cached.Color
				end
			end
		end)
	end

	local function getGunContainers()
		local list = {}
		if LocalPlayer then
			local backpack = LocalPlayer:FindFirstChild("Backpack")
			if backpack then
				table.insert(list, backpack)
			end
			if LocalPlayer.Character then
				table.insert(list, LocalPlayer.Character)
			end
		end
		return list
	end

	local function cacheGunAttrs(instance)
		if gunCache[instance] then return end
		local entry = {}
		for _, name in ipairs(SETTINGS.GUN_ATTRIBUTES) do
			local val = instance:GetAttribute(name)
			if val ~= nil then
				entry[name] = val
			end
		end
		gunCache[instance] = entry
	end

	local function applyGunModsTo(instance)
		if not instance or not instance.Parent then return end

		local function modifyAttributes(obj)
			cacheGunAttrs(obj)
			if FeatureConfig.Game.NoSpread and obj:GetAttribute("SpreadRadius") ~= nil and obj:GetAttribute("SpreadRadius") ~= 0 then
				pcall(function() obj:SetAttribute("SpreadRadius", 0) end)
			end
			if FeatureConfig.Game.FastFire and obj:GetAttribute("FireRate") ~= nil then
				local rate = FeatureConfig.Game.FireRateValue or SETTINGS.DEFAULTS.FireRateValue
				if obj:GetAttribute("FireRate") ~= rate then
					pcall(function() obj:SetAttribute("FireRate", rate) end)
				end
			end
			if FeatureConfig.Game.ForceAuto and obj:GetAttribute("AutoFire") ~= nil and obj:GetAttribute("AutoFire") ~= true then
				pcall(function() obj:SetAttribute("AutoFire", true) end)
			end
			if FeatureConfig.Game.ForceRange and obj:GetAttribute("Range") ~= nil then
				local range = FeatureConfig.Game.RangeValue or SETTINGS.DEFAULTS.RangeValue
				if obj:GetAttribute("Range") ~= range then
					pcall(function() obj:SetAttribute("Range", range) end)
				end
			end
		end

		if instance:IsA("Tool") then
			modifyAttributes(instance)
			for _, descendant in ipairs(instance:GetDescendants()) do
				for _, attr in ipairs(SETTINGS.GUN_ATTRIBUTES) do
					if descendant:GetAttribute(attr) ~= nil then
						modifyAttributes(descendant)
						break
					end
				end
			end
		else
			for _, attr in ipairs(SETTINGS.GUN_ATTRIBUTES) do
				if instance:GetAttribute(attr) ~= nil then
					modifyAttributes(instance)
					break
				end
			end
		end
	end

	local function anyGunModEnabled()
		return FeatureConfig.Game.NoSpread
			or FeatureConfig.Game.FastFire
			or FeatureConfig.Game.ForceAuto
			or FeatureConfig.Game.ForceRange
	end

	local function scanGuns()
		for _, container in ipairs(getGunContainers()) do
			for _, child in ipairs(container:GetChildren()) do
				if child:IsA("Tool") then
					applyGunModsTo(child)
				end
			end
		end
	end

	local function restoreGuns()
		for instance, entry in pairs(gunCache) do
			if instance and instance.Parent and type(entry) == "table" then
				for name, original in pairs(entry) do
					pcall(function() instance:SetAttribute(name, original) end)
				end
			end
			gunCache[instance] = nil
		end
		table.clear(gunCache)
	end

	local function enforceGuns()
		if not anyGunModEnabled() then return end
		scanGuns()
	end

	local function runFakeMacroStep()
		local char = LocalPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
		if not hum or hum.Health <= 0 or not backpack then return end

		local guns = {}
		for _, tool in ipairs(backpack:GetChildren()) do
			if tool:IsA("Tool") and prisonGunsLookup[tool.Name] then
				table.insert(guns, tool)
			end
		end
		for _, tool in ipairs(char:GetChildren()) do
			if tool:IsA("Tool") and prisonGunsLookup[tool.Name] then
				table.insert(guns, tool)
			end
		end

		if #guns < 2 then return end

		currentToolIndex = currentToolIndex + 1
		if currentToolIndex > #guns then
			currentToolIndex = 1
		end

		local targetTool = guns[currentToolIndex]
		if targetTool and targetTool.Parent ~= char then
			pcall(function() hum:EquipTool(targetTool) end)
		end
	end

	local function stopFakeMacro()
		macroLoopActive = false
		if macroThread then
			pcall(function() task.cancel(macroThread) end)
			macroThread = nil
		end
	end

	local function startFakeMacro()
		if macroLoopActive then return end
		macroLoopActive = true
		macroThread = task.spawn(function()
			while macroLoopActive do
				pcall(runFakeMacroStep)
				local delayTime = math.clamp(
					FeatureConfig.Game.FakeMacroDelay or SETTINGS.DEFAULTS.FakeMacroDelay,
					SETTINGS.LIMITS.MIN_MACRO_DELAY,
					SETTINGS.LIMITS.MAX_MACRO_DELAY
				)
				task.wait(delayTime)
			end
		end)
	end

	local function handleFakeMacroInput(input, isBegan)
		if not FeatureConfig.Game.FakeMacro then return end
		local macroKey = FeatureConfig.Game.FakeMacroKey
		if not macroKey then return end

		local matched = false
		if typeof(macroKey) == "EnumItem" then
			if macroKey.EnumType == Enum.KeyCode then
				matched = (input.KeyCode == macroKey)
			elseif macroKey.EnumType == Enum.UserInputType then
				matched = (input.UserInputType == macroKey)
			end
		end
		if not matched then return end

		if FeatureConfig.Game.FakeMacroMode == "Toggle" then
			if isBegan then
				isKeyPressed = not isKeyPressed
				if isKeyPressed then
					startFakeMacro()
				else
					stopFakeMacro()
				end
			end
		elseif FeatureConfig.Game.FakeMacroMode == "Hold" then
			if isBegan then
				isKeyPressed = true
				startFakeMacro()
			else
				isKeyPressed = false
				stopFakeMacro()
			end
		end
	end

	local function showBannableWarningModal(onAccept, onCancel)
		local mainFrame = Context and Context.UI and Context.UI.Main
		if not mainFrame then
			if onAccept then onAccept() end
			return
		end

		local function createInstance(className, properties)
			local instance = Instance.new(className)
			if properties then
				for k, v in pairs(properties) do
					pcall(function() instance[k] = v end)
				end
			end
			return instance
		end

		local function createStroke(color, thickness)
			return createInstance("UIStroke", {
				Color = color or getThemeColor("Border"),
				Thickness = thickness or 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			})
		end

		local dim = createInstance("Frame", {
			Name = "B0XazBannableDim",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.55,
			BorderSizePixel = 0,
			ZIndex = 500,
			Parent = mainFrame,
		})

		local modal = createInstance("Frame", {
			Name = "ModalFrame",
			Size = UDim2.fromOffset(400, 240),
			Position = UDim2.new(0.5, -200, 0.5, -120),
			BackgroundColor3 = getThemeColor("Bg"),
			BorderSizePixel = 0,
			ZIndex = 501,
			Parent = dim,
		})
		createStroke(getThemeColor("Danger"), 1).Parent = modal

		local titleBar = createInstance("Frame", {
			Size = UDim2.new(1, 0, 0, 24),
			BackgroundColor3 = getThemeColor("Side"),
			BorderSizePixel = 0,
			ZIndex = 502,
			Parent = modal,
		})
		createInstance("Frame", {
			Size = UDim2.new(1, 0, 0, 1),
			Position = UDim2.new(0, 0, 1, -1),
			BackgroundColor3 = getThemeColor("Danger"),
			BorderSizePixel = 0,
			ZIndex = 503,
			Parent = titleBar,
		})
		createInstance("TextLabel", {
			Text = "  SECURITY ADVISORY // BAN RISK DETECTED",
			Font = Enum.Font.Code,
			TextSize = 11,
			TextColor3 = getThemeColor("Danger"),
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 504,
			Parent = titleBar,
		})

		local contentBody = createInstance("Frame", {
			Size = UDim2.new(1, -20, 0, 110),
			Position = UDim2.fromOffset(10, 34),
			BackgroundColor3 = getThemeColor("Panel"),
			BorderSizePixel = 0,
			ZIndex = 502,
			Parent = modal,
		})
		createStroke(getThemeColor("BorderDim"), 1).Parent = contentBody

		createInstance("TextLabel", {
			Text = "[!] WARNING: Features in this section send heavy, high-rate melee payloads directly to server remotes.\n\n"
				.. "[!] Using Punch Aura or Super Multi-Punch WILL trigger automatic server log bans on Prison Life.\n\n"
				.. "[!] Please wait 3s, then HOLD the button for 2s to unlock.",
			Font = Enum.Font.Code,
			TextSize = 10,
			TextColor3 = getThemeColor("TextDim"),
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(8, 8),
			Size = UDim2.new(1, -16, 1, -16),
			ZIndex = 503,
			Parent = contentBody,
		})

		local btnContainer = createInstance("Frame", {
			Size = UDim2.new(1, -20, 0, 70),
			Position = UDim2.fromOffset(10, 155),
			BackgroundTransparency = 1,
			ZIndex = 502,
			Parent = modal,
		})

		local holdBtn = createInstance("TextButton", {
			Size = UDim2.new(1, 0, 0, 30),
			Position = UDim2.fromOffset(0, 0),
			BackgroundColor3 = getThemeColor("Elem"),
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "[ LOCKED // WAIT 3s ]",
			Font = Enum.Font.Code,
			TextSize = 11,
			TextColor3 = getThemeColor("TextMuted"),
			ClipsDescendants = true,
			ZIndex = 503,
			Parent = btnContainer,
		})
		local holdStroke = createStroke(getThemeColor("Border"), 1)
		holdStroke.Parent = holdBtn

		local fillBar = createInstance("Frame", {
			Size = UDim2.new(0, 0, 1, 0),
			BackgroundColor3 = getThemeColor("Danger"),
			BackgroundTransparency = 0.4,
			BorderSizePixel = 0,
			ZIndex = 504,
			Parent = holdBtn,
		})

		local cancelBtn = createInstance("TextButton", {
			Size = UDim2.new(1, 0, 0, 24),
			Position = UDim2.fromOffset(0, 36),
			BackgroundColor3 = getThemeColor("Elem"),
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "[ ABORT & RETURN TO SAFE MODE ]",
			Font = Enum.Font.Code,
			TextSize = 10,
			TextColor3 = getThemeColor("Text"),
			ZIndex = 503,
			Parent = btnContainer,
		})
		createStroke(getThemeColor("Border"), 1).Parent = cancelBtn

		cancelBtn.MouseEnter:Connect(function()
			cancelBtn.BackgroundColor3 = getThemeColor("ElemHover")
		end)
		cancelBtn.MouseLeave:Connect(function()
			cancelBtn.BackgroundColor3 = getThemeColor("Elem")
		end)
		cancelBtn.MouseButton1Click:Connect(function()
			dim:Destroy()
			if onCancel then onCancel() end
		end)

		local canInteract = false
		task.spawn(function()
			for i = SETTINGS.LIMITS.WARNING_COUNTDOWN, 1, -1 do
				if not dim or not dim.Parent then return end
				holdBtn.Text = string.format("[ LOCKED // WAIT %ds ]", i)
				task.wait(1)
			end
			if not dim or not dim.Parent then return end
			canInteract = true
			holdBtn.Text = "[ HOLD 2.0s TO ACKNOWLEDGE & UNLOCK ]"
			holdBtn.TextColor3 = getThemeColor("Danger")
			holdStroke.Color = getThemeColor("Danger")
		end)

		local isHolding = false
		local holdTime = 0
		local holdConn = nil

		local function stopHolding()
			isHolding = false
			holdTime = 0
			fillBar.Size = UDim2.new(0, 0, 1, 0)
			if canInteract and dim and dim.Parent then
				holdBtn.Text = "[ HOLD 2.0s TO ACKNOWLEDGE & UNLOCK ]"
			end
			if holdConn then
				holdConn:Disconnect()
				holdConn = nil
			end
		end

		local function startHolding()
			if not canInteract or isHolding then return end
			isHolding = true
			holdTime = 0

			holdConn = RunService.RenderStepped:Connect(function(dt)
				if not isHolding then return end
				holdTime = holdTime + dt
				local progress = math.clamp(holdTime / SETTINGS.LIMITS.WARNING_HOLD_TIME, 0, 1)
				fillBar.Size = UDim2.new(progress, 0, 1, 0)
				holdBtn.Text = string.format("[ HOLDING: %.1fs / 2.0s ]", holdTime)

				if holdTime >= SETTINGS.LIMITS.WARNING_HOLD_TIME then
					stopHolding()
					hasAcceptedBannableWarning = true
					dim:Destroy()
					if onAccept then onAccept() end
				end
			end)
		end

		holdBtn.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				startHolding()
			end
		end)

		holdBtn.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				stopHolding()
			end
		end)
	end

	function Game.SetGlowColor(color)
		FeatureConfig.Game.GlowColor = color
		if FeatureConfig.Game.DoorPhase then
			scanAllDoors()
		end
	end

	if Connections and Connections.Add then
		if FeatureConfig.Game.DoorPhase then
			task.spawn(scanAllDoors)
		end

		Connections.Add(RunService.Heartbeat:Connect(function()
			runPunchAura()

			if FeatureConfig.Game.AntiRestrict then
				local hum = Utils.GetHumanoid and Utils.GetHumanoid()
				if hum then
					local flyActive = FeatureConfig.Movement and FeatureConfig.Movement.FlyEnabled
					if hum.WalkSpeed < SETTINGS.DEFAULT_WALKSPEED and not flyActive then
						hum.WalkSpeed = (FeatureConfig.Movement and FeatureConfig.Movement.Speed) or SETTINGS.DEFAULT_WALKSPEED
					end
					if hum.JumpPower < SETTINGS.DEFAULT_JUMPPOWER then
						hum.JumpPower = (FeatureConfig.Movement and FeatureConfig.Movement.JumpPower) or SETTINGS.DEFAULT_JUMPPOWER
					end
					if hum.PlatformStand then
						hum.PlatformStand = false
					end
				end

				local pGui = LocalPlayer:FindFirstChild("PlayerGui")
				if pGui then
					for _, guiName in ipairs(SETTINGS.RESTRICTED_GUIS) do
						local gui = pGui:FindFirstChild(guiName)
						if gui and gui.Enabled then
							gui.Enabled = false
						end
					end
				end
			end
		end))

		Connections.Add(RunService.Stepped:Connect(function()
			if FeatureConfig.Game.DoorPhase then
				for part in pairs(doorPartsSet) do
					enforcePart(part)
				end
			end
			if anyGunModEnabled() then
				enforceGuns()
			end
		end))

		Connections.Add(Workspace.DescendantAdded:Connect(function(descendant)
			if FeatureConfig.Game.DoorPhase and descendant:IsA("BasePart") then
				task.defer(function()
					processPart(descendant)
				end)
			end
		end))

		local function hookContainer(container)
			if not container then return end
			Connections.Add(container.ChildAdded:Connect(function(child)
				if anyGunModEnabled() and child:IsA("Tool") then
					task.defer(function()
						applyGunModsTo(child)
					end)
				end
			end))
		end

		if LocalPlayer:FindFirstChild("Backpack") then
			hookContainer(LocalPlayer.Backpack)
		end
		if LocalPlayer.Character then
			hookContainer(LocalPlayer.Character)
		end

		Connections.Add(LocalPlayer.CharacterAdded:Connect(function(char)
			hookContainer(char)
			task.wait(0.5)
			if anyGunModEnabled() then
				scanGuns()
			end
		end))

		Connections.Add(LocalPlayer.ChildAdded:Connect(function(child)
			if child.Name == "Backpack" then
				hookContainer(child)
			end
		end))

		Connections.Add(UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then return end
			handleFakeMacroInput(input, true)

			if FeatureConfig.Game.SuperPunch and input.UserInputType == Enum.UserInputType.MouseButton1 then
				local now = os.clock()
				if (now - lastSuperPunchTime) >= SETTINGS.LIMITS.SUPER_PUNCH_COOLDOWN then
					lastSuperPunchTime = now
					local char = LocalPlayer.Character
					if char and not char:FindFirstChildOfClass("Tool") then
						local rawHits = FeatureConfig.Game.SuperPunchHits or SETTINGS.DEFAULTS.SuperPunchHits
						local hits = math.clamp(rawHits, SETTINGS.LIMITS.MIN_SUPER_PUNCH_HITS, SETTINGS.LIMITS.MAX_SUPER_PUNCH_HITS)
						for _ = 1, hits do
							fireMelee()
						end
					end
				end
			end
		end))

		Connections.Add(UserInputService.InputEnded:Connect(function(input, gameProcessed)
			if gameProcessed then return end
			handleFakeMacroInput(input, false)
		end))
	end

	function Game.BuildUI(tab)
		local normalSections = {}
		local bannableSections = {}

		local navSec = tab:AddSection("Prison Life Categories")

		local function updateSubTabs(active)
			for _, sec in ipairs(normalSections) do
				if sec and sec.Frame then
					sec.Frame.Visible = (active == "Normal")
				end
			end
			for _, sec in ipairs(bannableSections) do
				if sec and sec.Frame then
					sec.Frame.Visible = (active == "Bannable")
				end
			end
		end

		navSec:AddButton("[ Mode: Normal Features ]", function()
			updateSubTabs("Normal")
			notify("Prison Life", "Switched to Normal Mode", 2, getThemeColor("Success"))
		end)

		navSec:AddButton("[ Mode: ⚠️ Bannable Exploits ]", function()
			if not hasAcceptedBannableWarning then
				showBannableWarningModal(
					function()
						updateSubTabs("Bannable")
						notify(
							"CRITICAL WARNING",
							"Any functions in this tab will get your account banned from Prison Life",
							6,
							getThemeColor("Danger")
						)
					end,
					function()
						updateSubTabs("Normal")
					end
				)
			else
				updateSubTabs("Bannable")
				notify(
					"CRITICAL WARNING",
					"Any functions in this tab will get your account banned from Prison Life",
					5,
					getThemeColor("Danger")
				)
			end
		end)

		local gunGrabSec = tab:AddSection("Gun Grabbers (Warp-Return)")
		table.insert(normalSections, gunGrabSec)
		for gunName, spawnPos in pairs(SETTINGS.GUN_SPAWNS) do
			gunGrabSec:AddButton("Grab " .. gunName, function()
				grabGun(gunName, spawnPos)
			end)
		end

		local combatSec = tab:AddSection("Combat Modifications")
		table.insert(normalSections, combatSec)
		UIRegistry.Game_NoSpread = combatSec:AddToggle("No Spread", FeatureConfig.Game.NoSpread, function(v)
			FeatureConfig.Game.NoSpread = v
			if anyGunModEnabled() then scanGuns() else restoreGuns() end
		end)
		UIRegistry.Game_FastFire = combatSec:AddToggle("Fast Fire", FeatureConfig.Game.FastFire, function(v)
			FeatureConfig.Game.FastFire = v
			if anyGunModEnabled() then scanGuns() else restoreGuns() end
		end)
		UIRegistry.Game_ForceAuto = combatSec:AddToggle("Force Automatic Fire", FeatureConfig.Game.ForceAuto, function(v)
			FeatureConfig.Game.ForceAuto = v
			if anyGunModEnabled() then scanGuns() else restoreGuns() end
		end)
		UIRegistry.Game_ForceRange = combatSec:AddToggle("Force Range", FeatureConfig.Game.ForceRange, function(v)
			FeatureConfig.Game.ForceRange = v
			if anyGunModEnabled() then scanGuns() else restoreGuns() end
		end)
		combatSec:AddButton("Force Apply Gun Mods", function()
			scanGuns()
			notify("Prison Life", "Gun mods enforced", nil, getThemeColor("Accent"))
		end)

		local macroSec = tab:AddSection("Fake Macro (Gun Spam)")
		table.insert(normalSections, macroSec)
		UIRegistry.Game_FakeMacro = macroSec:AddToggle("Enable Fake Macro", FeatureConfig.Game.FakeMacro, function(v)
			FeatureConfig.Game.FakeMacro = v
			if not v then
				stopFakeMacro()
				isKeyPressed = false
			end
		end)
		UIRegistry.Game_FakeMacroKey = macroSec:AddKeybind("Macro Activation Key", FeatureConfig.Game.FakeMacroKey, function(k)
			FeatureConfig.Game.FakeMacroKey = k
			stopFakeMacro()
			isKeyPressed = false
		end)
		UIRegistry.Game_FakeMacroMode = macroSec:AddDropdown("Activation Mode", { "Toggle", "Hold" }, function(v)
			FeatureConfig.Game.FakeMacroMode = v
			stopFakeMacro()
			isKeyPressed = false
		end, FeatureConfig.Game.FakeMacroMode)
		UIRegistry.Game_FakeMacroDelay = macroSec:AddSlider(
			"Macro Delay",
			math.floor((FeatureConfig.Game.FakeMacroDelay or SETTINGS.DEFAULTS.FakeMacroDelay) * 1000),
			math.floor(SETTINGS.LIMITS.MIN_MACRO_DELAY * 1000),
			math.floor(SETTINGS.LIMITS.MAX_MACRO_DELAY * 1000),
			function(v)
				FeatureConfig.Game.FakeMacroDelay = math.clamp(v / 1000, SETTINGS.LIMITS.MIN_MACRO_DELAY, SETTINGS.LIMITS.MAX_MACRO_DELAY)
			end,
			" ms"
		)

		local doorsSec = tab:AddSection("Doors & Obstacles")
		table.insert(normalSections, doorsSec)
		UIRegistry.Game_DoorPhase = doorsSec:AddToggle("Phase Doors, Fences & Vending", FeatureConfig.Game.DoorPhase, function(v)
			FeatureConfig.Game.DoorPhase = v
			if v then scanAllDoors() else restoreAllDoors() end
		end)
		UIRegistry.Game_DoorGlow = doorsSec:AddToggle("Obstacle Glow Effect", FeatureConfig.Game.DoorGlow, function(v)
			FeatureConfig.Game.DoorGlow = v
			if FeatureConfig.Game.DoorPhase then scanAllDoors() end
		end)
		UIRegistry.Game_PhaseTransparency = doorsSec:AddSlider(
			"Phase Transparency",
			math.floor((FeatureConfig.Game.PhaseTransparency or SETTINGS.DEFAULTS.PhaseTransparency) * 100),
			math.floor(SETTINGS.LIMITS.MIN_PHASE_TRANSPARENCY * 100),
			math.floor(SETTINGS.LIMITS.MAX_PHASE_TRANSPARENCY * 100),
			function(v)
				FeatureConfig.Game.PhaseTransparency = math.clamp(v / 100, SETTINGS.LIMITS.MIN_PHASE_TRANSPARENCY, SETTINGS.LIMITS.MAX_PHASE_TRANSPARENCY)
			end,
			"%"
		)
		UIRegistry.Game_GlowColor = doorsSec:AddColorPicker("Glow Color", FeatureConfig.Game.GlowColor, function(c)
			Game.SetGlowColor(c)
		end)

		local defSec = tab:AddSection("Defenses")
		table.insert(normalSections, defSec)
		UIRegistry.Game_AntiRestrict = defSec:AddToggle("Anti-Taser", FeatureConfig.Game.AntiRestrict, function(v)
			FeatureConfig.Game.AntiRestrict = v
		end)
		defSec:AddButton("Become Criminal (Inside)", function()
			Game.BecomeCriminalInside()
		end)
		defSec:AddButton("Become Criminal (Outside)", function()
			Game.BecomeCriminalOutside()
		end)

		local tpSec = tab:AddSection("Map Teleports")
		table.insert(normalSections, tpSec)
		for _, loc in ipairs(SETTINGS.LOCATIONS) do
			local name, cf = loc[1], loc[2]
			tpSec:AddButton(name, function()
				local root = Utils.GetRootPart and Utils.GetRootPart()
				if root then
					root.CFrame = cf
					notify("Teleport", "Moved to " .. name, nil, getThemeColor("Success"))
				end
			end)
		end

		local warnSec = tab:AddSection("⚠️ DETECTION WARNING")
		table.insert(bannableSections, warnSec)
		warnSec:AddButton("WARNING: High Ban Risk Functions", function()
			notify("DANGER", "These melee functions are heavily flagged by server logs!", 5, getThemeColor("Danger"))
		end)

		local meleeSec = tab:AddSection("Bannable Melee Exploits")
		table.insert(bannableSections, meleeSec)

		UIRegistry.Game_PunchAura = meleeSec:AddToggle("Punch Aura", FeatureConfig.Game.PunchAura, function(v)
			FeatureConfig.Game.PunchAura = v
		end)
		UIRegistry.Game_PunchAuraRange = meleeSec:AddSlider(
			"Punch Aura Range",
			FeatureConfig.Game.PunchAuraRange or SETTINGS.DEFAULTS.PunchAuraRange,
			SETTINGS.LIMITS.MIN_PUNCH_AURA_RANGE,
			SETTINGS.LIMITS.MAX_PUNCH_AURA_RANGE,
			function(v)
				FeatureConfig.Game.PunchAuraRange = math.clamp(v, SETTINGS.LIMITS.MIN_PUNCH_AURA_RANGE, SETTINGS.LIMITS.MAX_PUNCH_AURA_RANGE)
			end,
			" studs"
		)

		UIRegistry.Game_SuperPunch = meleeSec:AddToggle("Super Multi-Punch (Click)", FeatureConfig.Game.SuperPunch, function(v)
			FeatureConfig.Game.SuperPunch = v
		end)
		UIRegistry.Game_SuperPunchHits = meleeSec:AddSlider(
			"Multi-Hit Multiplier",
			FeatureConfig.Game.SuperPunchHits or SETTINGS.DEFAULTS.SuperPunchHits,
			SETTINGS.LIMITS.MIN_SUPER_PUNCH_HITS,
			SETTINGS.LIMITS.MAX_SUPER_PUNCH_HITS,
			function(v)
				FeatureConfig.Game.SuperPunchHits = math.clamp(v, SETTINGS.LIMITS.MIN_SUPER_PUNCH_HITS, SETTINGS.LIMITS.MAX_SUPER_PUNCH_HITS)
			end,
			" hits"
		)

		updateSubTabs("Normal")
	end

	function Game.Update(dt)
		if FeatureConfig.Game.DoorPhase then
			for part in pairs(doorPartsSet) do
				enforcePart(part)
			end
		end
		if anyGunModEnabled() then
			enforceGuns()
		end
	end

	function Game.Destroy()
		stopFakeMacro()
		restoreAllDoors()
		restoreGuns()
	end

	getgenv().B0XazRestoreDoors = restoreAllDoors
	getgenv().B0XazRestoreGuns = restoreGuns

	return Game
end
