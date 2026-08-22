-- src/Games/155615604/init.lua (Prison Life Specialized Module)
return function(Context)
	local Workspace = game:GetService("Workspace")
	local Players = game:GetService("Players")
	local RS = game:GetService("RunService")
	local UIS = game:GetService("UserInputService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local LocalPlayer = Players.LocalPlayer
	local FeatureConfig = Context and Context.FeatureConfig or {}
	local Theme = Context and Context.Theme or {}
	local Connections = Context and Context.Connections or {}
	local UIRegistry = Context and Context.UIRegistry or {}
	local Utils = Context and Context.Utils or {}

	-- Safe Defaults initialization
	if not FeatureConfig.Game then FeatureConfig.Game = {} end
	local defaults = {
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
		-- Bannable category features
		PunchAura = false,
		PunchAuraRange = 15,
		SuperPunch = false,
		SuperPunchHits = 10,
	}
	for k, v in pairs(defaults) do
		if FeatureConfig.Game[k] == nil then FeatureConfig.Game[k] = v end
	end

	local DOOR_FOLDERS = {"Doors", "glass", "CellDoors", "Prison_Fences", "Prison_Gate"}
	local PRISON_PL_GUNS = {"Remington 870", "M9", "AK-47", "Taser", "M4A1", "MP5"}

	-- Teleport Coordinates
	local PL_LOCATIONS = {
		{"Prison Cells", CFrame.new(920, 98, 2436)},
		{"Cafeteria", CFrame.new(920, 98, 2290)},
		{"Prison Yard", CFrame.new(779, 98, 2463)},
		{"Criminal Base", CFrame.new(-943, 95, 2058)},
		{"Police Armory", CFrame.new(831, 98, 2284)},
		{"Parking Lot", CFrame.new(745, 98, 2148)},
		{"Roof", CFrame.new(845, 130, 2235)},
		{"Secret Room", CFrame.new(674, 98, 2384)},
		{"Tunnels", CFrame.new(918, 80, 2284)},
		{"Outside of Prison", CFrame.new(451.67, 98.04, 2216.34)},
		{"Kitchen", CFrame.new(906.64, 99.99, 2237.67)},
		{"Break Room", CFrame.new(800.09, 99.99, 2266.72)},
	}

	-- Dispenser positions with +1.76 Y increase on MP5 and Remington 870
	local GUN_SPAWNS = {
		["MP5"] = Vector3.new(813.72, 102.50, 2229.37),
		["Remington 870"] = Vector3.new(820.27, 102.50, 2229.31),
		["AK-47"] = Vector3.new(-932, 100.74, 2039.5),
	}

	local _cache = getgenv().B0XazDoorCache or {}
	getgenv().B0XazDoorCache = _cache
	local _doorPartsSet = getgenv().B0XazDoorParts or {}
	getgenv().B0XazDoorParts = _doorPartsSet
	local _gunCache = getgenv().B0XazGunCache or {}
	getgenv().B0XazGunCache = _gunCache

	local Game = { Name = "Prison Life" }
	local ATTRS = { "SpreadRadius", "FireRate", "AutoFire", "Range" }

	-- Runtime states
	local macroLoopActive = false
	local macroThread = nil
	local currentToolIndex = 1
	local isKeyPressed = false
	local isGrabbingGun = false
	local isSwitchingCriminal = false
	local hasAcceptedBannableWarning = false

	-- Remotes
	local MeleeEvent = ReplicatedStorage:FindFirstChild("meleeEvent")

	----------------------------------------------------------------
	-- GUN TELEPORT ENGINE (Touch-Teleport Return)
	----------------------------------------------------------------
	local function grabGun(gunName, targetPos)
		if isGrabbingGun then return end
		local root = Utils.GetRootPart()
		if not root then
			if Context.UI then Context.UI:Notify("Gun Grabber", "Character root not found", nil, Theme.Danger) end
			return
		end

		isGrabbingGun = true
		local originalPos = root.CFrame

		if Context.UI then
			Context.UI:Notify("Gun Grabber", "Acquiring " .. gunName .. "...", 1.5, Theme.Accent)
		end

		root.CFrame = CFrame.new(targetPos)
		task.wait(1.3)

		local currentRoot = Utils.GetRootPart()
		if currentRoot then
			currentRoot.CFrame = originalPos
			if Context.UI then
				Context.UI:Notify("Gun Grabber", gunName .. " acquired!", 2, Theme.Success)
			end
		end
		isGrabbingGun = false
	end

	----------------------------------------------------------------
	-- BECOME CRIMINAL ROUTINES
	----------------------------------------------------------------
	function Game.BecomeCriminalInside()
		if isSwitchingCriminal then return end
		local root = Utils.GetRootPart()
		if not root then return end

		isSwitchingCriminal = true
		local originalPos = root.CFrame

		if Context.UI then
			Context.UI:Notify("Prison Life", "Becoming Criminal (Returning in 3.5s)...", 3.5, Theme.Accent)
		end

		root.CFrame = CFrame.new(-943, 95, 2058)
		task.wait(3.5)

		local currentRoot = Utils.GetRootPart()
		if currentRoot then
			currentRoot.CFrame = originalPos
			if Context.UI then
				Context.UI:Notify("Prison Life", "Returned Inside as Criminal!", 2, Theme.Success)
			end
		end
		isSwitchingCriminal = false
	end

	function Game.BecomeCriminalOutside()
		local root = Utils.GetRootPart()
		if not root then return end
		root.CFrame = CFrame.new(-943, 95, 2058)
		if Context.UI then
			Context.UI:Notify("Prison Life", "Warped Outside to Criminal Base!", 2, Theme.Success)
		end
	end

	----------------------------------------------------------------
	-- BANNABLE MELEE / PUNCH AURA LOGIC
	----------------------------------------------------------------
	local function runPunchAura()
		if not FeatureConfig.Game.PunchAura or not MeleeEvent then return end
		local myRoot = Utils.GetRootPart()
		if not myRoot then return end

		local maxDist = FeatureConfig.Game.PunchAuraRange or 15

		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer and Utils.IsAlive(p) and not Utils.SameTeam(p) then
				local tRoot = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
				if tRoot and (tRoot.Position - myRoot.Position).Magnitude <= maxDist then
					pcall(function()
						MeleeEvent:FireServer(p)
					end)
				end
			end
		end
	end

	----------------------------------------------------------------
	-- DOORS & VENDING MACHINES ENGINE
	----------------------------------------------------------------
	local function isInsideVendingModel(obj)
		local cur = obj
		while cur and cur ~= Workspace do
			if cur:IsA("Model") and cur.Name == "Model" and cur.Parent and cur.Parent.Name == "vending machine" then
				return true
			end
			cur = cur.Parent
		end
		return false
	end

	local function isDoorFolder(folderName)
		for _, name in ipairs(DOOR_FOLDERS) do
			if name:lower() == folderName:lower() then return true end
		end
		return false
	end

	local function isDoorPart(part)
		if not part or not part:IsA("BasePart") then return false end
		if isInsideVendingModel(part) then return true end
		local current = part.Parent
		while current and current ~= Workspace do
			if isDoorFolder(current.Name) then return true end
			current = current.Parent
		end
		return false
	end

	local function restorePart(part)
		local c = _cache[part]
		if c and part and part.Parent then
			pcall(function()
				part.CanCollide = c.CanCollide
				part.Transparency = c.Transparency
				part.Color = c.Color
				part.Material = c.Material
			end)
		end
		_cache[part] = nil
		_doorPartsSet[part] = nil
	end

	local function restoreAllDoors()
		for part, _ in pairs(_cache) do restorePart(part) end
		table.clear(_cache)
		table.clear(_doorPartsSet)
	end

	local function cachePart(part)
		if _cache[part] then return end
		_cache[part] = {
			CanCollide = part.CanCollide,
			Transparency = part.Transparency,
			Color = part.Color,
			Material = part.Material,
		}
	end

	local function processPart(part)
		if not isDoorPart(part) then return end
		cachePart(part)
		_doorPartsSet[part] = true
	end

	local function scanAllDoors()
		for _, folderName in ipairs(DOOR_FOLDERS) do
			local folder = Workspace:FindFirstChild(folderName)
			if folder then
				for _, desc in ipairs(folder:GetDescendants()) do
					if desc:IsA("BasePart") then processPart(desc) end
				end
			end
		end
		for _, obj in ipairs(Workspace:GetDescendants()) do
			if obj:IsA("BasePart") and isInsideVendingModel(obj) then
				processPart(obj)
			end
		end
	end

	local function enforcePart(part)
		local c = _cache[part]
		if not c or not part or not part.Parent then
			_doorPartsSet[part] = nil
			_cache[part] = nil
			return
		end
		if not FeatureConfig.Game.DoorPhase then return end

		pcall(function()
			if part.CanCollide then part.CanCollide = false end
			local targetTrans = FeatureConfig.Game.PhaseTransparency or 0.65
			if math.abs(part.Transparency - targetTrans) > 0.01 then
				part.Transparency = targetTrans
			end
			if FeatureConfig.Game.DoorGlow then
				if part.Material ~= Enum.Material.Neon then part.Material = Enum.Material.Neon end
				if part.Color ~= FeatureConfig.Game.GlowColor then part.Color = FeatureConfig.Game.GlowColor end
			else
				if part.Material ~= c.Material then part.Material = c.Material end
				if part.Color ~= c.Color then part.Color = c.Color end
			end
		end)
	end

	----------------------------------------------------------------
	-- GUN MODIFICATIONS ENGINE
	----------------------------------------------------------------
	local function getGunContainers()
		local list = {}
		if LocalPlayer then
			local bp = LocalPlayer:FindFirstChild("Backpack")
			if bp then table.insert(list, bp) end
			if LocalPlayer.Character then table.insert(list, LocalPlayer.Character) end
		end
		return list
	end

	local function cacheGunAttrs(inst)
		if _gunCache[inst] then return end
		local entry = {}
		for _, name in ipairs(ATTRS) do
			local v = inst:GetAttribute(name)
			if v ~= nil then entry[name] = v end
		end
		_gunCache[inst] = entry
	end

	local function setAttr(inst, name, value)
		pcall(function() inst:SetAttribute(name, value) end)
	end

	local function applyGunModsTo(inst)
		if not inst or not inst.Parent then return end
		local function touch(obj)
			cacheGunAttrs(obj)
			if FeatureConfig.Game.NoSpread and obj:GetAttribute("SpreadRadius") ~= nil and obj:GetAttribute("SpreadRadius") ~= 0 then
				setAttr(obj, "SpreadRadius", 0)
			end
			if FeatureConfig.Game.FastFire and obj:GetAttribute("FireRate") ~= nil then
				local fr = FeatureConfig.Game.FireRateValue or 0.001
				if obj:GetAttribute("FireRate") ~= fr then setAttr(obj, "FireRate", fr) end
			end
			if FeatureConfig.Game.ForceAuto and obj:GetAttribute("AutoFire") ~= nil and obj:GetAttribute("AutoFire") ~= true then
				setAttr(obj, "AutoFire", true)
			end
			if FeatureConfig.Game.ForceRange and obj:GetAttribute("Range") ~= nil then
				local rng = FeatureConfig.Game.RangeValue or 10000
				if obj:GetAttribute("Range") ~= rng then setAttr(obj, "Range", rng) end
			end
		end

		if inst:IsA("Tool") then
			touch(inst)
			for _, d in ipairs(inst:GetDescendants()) do
				if d:GetAttribute("SpreadRadius") ~= nil or d:GetAttribute("FireRate") ~= nil or d:GetAttribute("AutoFire") ~= nil or d:GetAttribute("Range") ~= nil then
					touch(d)
				end
			end
		else
			if inst:GetAttribute("SpreadRadius") ~= nil or inst:GetAttribute("FireRate") ~= nil or inst:GetAttribute("AutoFire") ~= nil or inst:GetAttribute("Range") ~= nil then
				touch(inst)
			end
		end
	end

	local function scanGuns()
		for _, container in ipairs(getGunContainers()) do
			for _, child in ipairs(container:GetChildren()) do
				if child:IsA("Tool") then applyGunModsTo(child) end
			end
		end
	end

	local function restoreGuns()
		for inst, entry in pairs(_gunCache) do
			if inst and inst.Parent and type(entry) == "table" then
				for name, original in pairs(entry) do
					pcall(function() inst:SetAttribute(name, original) end)
				end
			end
			_gunCache[inst] = nil
		end
		table.clear(_gunCache)
	end

	local function anyGunModEnabled()
		return FeatureConfig.Game.NoSpread or FeatureConfig.Game.FastFire
			or FeatureConfig.Game.ForceAuto or FeatureConfig.Game.ForceRange
	end

	local function enforceGuns()
		if not anyGunModEnabled() then return end
		scanGuns()
	end

	----------------------------------------------------------------
	-- FAKE MACRO SYSTEM
	----------------------------------------------------------------
	local function runFakeMacroStep()
		local char = LocalPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
		if not hum or hum.Health <= 0 or not bp then return end

		local guns = {}
		for _, tool in ipairs(bp:GetChildren()) do
			if tool:IsA("Tool") and table.find(PRISON_PL_GUNS, tool.Name) then table.insert(guns, tool) end
		end
		for _, tool in ipairs(char:GetChildren()) do
			if tool:IsA("Tool") and table.find(PRISON_PL_GUNS, tool.Name) then table.insert(guns, tool) end
		end

		if #guns < 2 then return end

		currentToolIndex = currentToolIndex + 1
		if currentToolIndex > #guns then currentToolIndex = 1 end

		local targetTool = guns[currentToolIndex]
		if targetTool and targetTool.Parent ~= char then
			pcall(function() hum:EquipTool(targetTool) end)
		end
	end

	local function startFakeMacro()
		if macroLoopActive then return end
		macroLoopActive = true
		macroThread = task.spawn(function()
			while macroLoopActive do
				pcall(runFakeMacroStep)
				task.wait(FeatureConfig.Game.FakeMacroDelay or 0.03)
			end
		end)
	end

	local function stopFakeMacro()
		macroLoopActive = false
		if macroThread then
			pcall(function() task.cancel(macroThread) end)
			macroThread = nil
		end
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
				if isKeyPressed then startFakeMacro() else stopFakeMacro() end
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

	----------------------------------------------------------------
	-- WARNING MODAL OVERLAY (Pure B0Xaz Theme Style)
	----------------------------------------------------------------
	local function showBannableWarningModal(onAccept, onCancel)
		local mainFrame = Context and Context.UI and Context.UI.Main
		if not mainFrame then
			onAccept()
			return
		end

		local function create(class, props)
			local inst = Instance.new(class)
			if props then
				for k, v in pairs(props) do pcall(function() inst[k] = v end) end
			end
			return inst
		end

		local function stroke(color, thick)
			return create("UIStroke", {
				Color = color or Theme.Border,
				Thickness = thick or 0.1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			})
		end

		local dim = create("Frame", {
			Name = "B0XazBannableDim",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.55,
			BorderSizePixel = 0,
			ZIndex = 500,
			Parent = mainFrame,
		})

		local modal = create("Frame", {
			Name = "ModalFrame",
			Size = UDim2.fromOffset(400, 240),
			Position = UDim2.new(0.5, -200, 0.5, -120),
			BackgroundColor3 = Theme.Bg,
			BorderSizePixel = 0,
			ZIndex = 501,
			Parent = dim,
		})
		stroke(Theme.Danger or Color3.fromRGB(220, 80, 80), 1).Parent = modal

		local titleBar = create("Frame", {
			Size = UDim2.new(1, 0, 0, 24),
			BackgroundColor3 = Theme.Side,
			BorderSizePixel = 0,
			ZIndex = 502,
			Parent = modal,
		})
		local titleLine = create("Frame", {
			Size = UDim2.new(1, 0, 0, 1),
			Position = UDim2.new(0, 0, 1, -1),
			BackgroundColor3 = Theme.Danger or Color3.fromRGB(220, 80, 80),
			BorderSizePixel = 0,
			ZIndex = 503,
			Parent = titleBar,
		})
		local titleLbl = create("TextLabel", {
			Text = "  SECURITY ADVISORY // BAN RISK DETECTED",
			Font = Enum.Font.Code,
			TextSize = 11,
			TextColor3 = Theme.Danger or Color3.fromRGB(220, 80, 80),
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 504,
			Parent = titleBar,
		})

		local contentBody = create("Frame", {
			Size = UDim2.new(1, -20, 0, 110),
			Position = UDim2.fromOffset(10, 34),
			BackgroundColor3 = Theme.Panel,
			BorderSizePixel = 0,
			ZIndex = 502,
			Parent = modal,
		})
		stroke(Theme.BorderDim, 1).Parent = contentBody

		local descLbl = create("TextLabel", {
			Text = "[!] WARNING: Features in this section send heavy, high-rate melee payloads directly to server remotes.\n\n"
				.. "[!] Using Punch Aura or Super Multi-Punch WILL trigger automatic server log bans on Prison Life.\n\n"
				.. "[!] Please wait 3s, then HOLD the button for 2s to unlock.",
			Font = Enum.Font.Code,
			TextSize = 10,
			TextColor3 = Theme.TextDim,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(8, 8),
			Size = UDim2.new(1, -16, 1, -16),
			ZIndex = 503,
			Parent = contentBody,
		})

		local btnContainer = create("Frame", {
			Size = UDim2.new(1, -20, 0, 70),
			Position = UDim2.fromOffset(10, 155),
			BackgroundTransparency = 1,
			ZIndex = 502,
			Parent = modal,
		})

		local holdBtn = create("TextButton", {
			Size = UDim2.new(1, 0, 0, 30),
			Position = UDim2.fromOffset(0, 0),
			BackgroundColor3 = Theme.Elem,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "[ LOCKED // WAIT 3s ]",
			Font = Enum.Font.Code,
			TextSize = 11,
			TextColor3 = Theme.TextMuted,
			ClipsDescendants = true,
			ZIndex = 503,
			Parent = btnContainer,
		})
		local holdStroke = stroke(Theme.Border, 1)
		holdStroke.Parent = holdBtn

		local fillBar = create("Frame", {
			Size = UDim2.new(0, 0, 1, 0),
			BackgroundColor3 = Theme.Danger or Color3.fromRGB(220, 80, 80),
			BackgroundTransparency = 0.4,
			BorderSizePixel = 0,
			ZIndex = 504,
			Parent = holdBtn,
		})

		local cancelBtn = create("TextButton", {
			Size = UDim2.new(1, 0, 0, 24),
			Position = UDim2.fromOffset(0, 36),
			BackgroundColor3 = Theme.Elem,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "[ ABORT & RETURN TO SAFE MODE ]",
			Font = Enum.Font.Code,
			TextSize = 10,
			TextColor3 = Theme.Text,
			ZIndex = 503,
			Parent = btnContainer,
		})
		stroke(Theme.Border, 1).Parent = cancelBtn

		cancelBtn.MouseEnter:Connect(function()
			cancelBtn.BackgroundColor3 = Theme.ElemHover
		end)
		cancelBtn.MouseLeave:Connect(function()
			cancelBtn.BackgroundColor3 = Theme.Elem
		end)
		cancelBtn.MouseButton1Click:Connect(function()
			dim:Destroy()
			if onCancel then onCancel() end
		end)

		local canInteract = false
		task.spawn(function()
			for i = 3, 1, -1 do
				if not dim or not dim.Parent then return end
				holdBtn.Text = string.format("[ LOCKED // WAIT %ds ]", i)
				task.wait(1)
			end
			if not dim or not dim.Parent then return end
			canInteract = true
			holdBtn.Text = "[ HOLD 2.0s TO ACKNOWLEDGE & UNLOCK ]"
			holdBtn.TextColor3 = Theme.Danger or Color3.fromRGB(220, 80, 80)
			holdStroke.Color = Theme.Danger or Color3.fromRGB(220, 80, 80)
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

			holdConn = RS.RenderStepped:Connect(function(dt)
				if not isHolding then return end
				holdTime = holdTime + dt
				local progress = math.clamp(holdTime / 2.0, 0, 1)
				fillBar.Size = UDim2.new(progress, 0, 1, 0)
				holdBtn.Text = string.format("[ HOLDING: %.1fs / 2.0s ]", holdTime)

				if holdTime >= 2.0 then
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

	----------------------------------------------------------------
	-- CONNECTIONS / RUNTIME HOOKS
	----------------------------------------------------------------
	if Connections and Connections.Add then
		if FeatureConfig.Game.DoorPhase then
			task.spawn(scanAllDoors)
		end

		Connections.Add(RS.Heartbeat:Connect(function()
			-- Bannable Melee / Punch Aura
			runPunchAura()

			-- Anti-Taser / Anti-Restrict Engine
			if FeatureConfig.Game.AntiRestrict then
				local hum = Utils.GetHumanoid()
				if hum then
					if hum.WalkSpeed < 16 and not FeatureConfig.Movement.FlyEnabled then
						hum.WalkSpeed = FeatureConfig.Movement.Speed or 16
					end
					if hum.JumpPower < 50 then
						hum.JumpPower = FeatureConfig.Movement.JumpPower or 50
					end
					if hum.PlatformStand then hum.PlatformStand = false end
				end

				local pGui = LocalPlayer:FindFirstChild("PlayerGui")
				if pGui then
					for _, guiName in ipairs({"Taser", "Flashbang", "Cuffs"}) do
						local gui = pGui:FindFirstChild(guiName)
						if gui and gui.Enabled then
							gui.Enabled = false
						end
					end
				end
			end
		end))

		Connections.Add(RS.Stepped:Connect(function()
			if FeatureConfig.Game.DoorPhase then
				for part, _ in pairs(_doorPartsSet) do enforcePart(part) end
			end
			if anyGunModEnabled() then enforceGuns() end
		end))

		Connections.Add(Workspace.DescendantAdded:Connect(function(desc)
			if FeatureConfig.Game.DoorPhase and desc:IsA("BasePart") then
				task.defer(function() processPart(desc) end)
			end
		end))

		local function hookContainer(container)
			if not container then return end
			Connections.Add(container.ChildAdded:Connect(function(child)
				if anyGunModEnabled() and child:IsA("Tool") then
					task.defer(function() applyGunModsTo(child) end)
				end
			end))
		end

		if LocalPlayer:FindFirstChild("Backpack") then hookContainer(LocalPlayer.Backpack) end
		if LocalPlayer.Character then hookContainer(LocalPlayer.Character) end

		Connections.Add(LocalPlayer.CharacterAdded:Connect(function(char)
			hookContainer(char)
			task.wait(0.5)
			if anyGunModEnabled() then scanGuns() end
		end))

		Connections.Add(LocalPlayer.ChildAdded:Connect(function(child)
			if child.Name == "Backpack" then hookContainer(child) end
		end))

		Connections.Add(UIS.InputBegan:Connect(function(input, gp)
			if gp then return end
			handleFakeMacroInput(input, true)

			-- Super Multi-Punch Listener (Bannable)
			if FeatureConfig.Game.SuperPunch and input.UserInputType == Enum.UserInputType.MouseButton1 then
				local char = LocalPlayer.Character
				if MeleeEvent and char and not char:FindFirstChildOfClass("Tool") then
					local hits = FeatureConfig.Game.SuperPunchHits or 10
					for _ = 1, hits do
						pcall(function() MeleeEvent:FireServer() end)
					end
				end
			end
		end))

		Connections.Add(UIS.InputEnded:Connect(function(input, gp)
			if gp then return end
			handleFakeMacroInput(input, false)
		end))
	end

	----------------------------------------------------------------
	-- UI BUILDER FOR PRISON LIFE (Normal & Bannable Sub-Tabs)
	----------------------------------------------------------------
	function Game.BuildUI(tab)
		local normalSections = {}
		local bannableSections = {}

		local navSec = tab:AddSection("Prison Life Categories")

		local function updateSubTabs(active)
			for _, sec in ipairs(normalSections) do
				if sec and sec.Frame then sec.Frame.Visible = (active == "Normal") end
			end
			for _, sec in ipairs(bannableSections) do
				if sec and sec.Frame then sec.Frame.Visible = (active == "Bannable") end
			end
		end

		navSec:AddButton("[ Mode: Normal Features ]", function()
			updateSubTabs("Normal")
			if Context and Context.UI then
				Context.UI:Notify("Prison Life", "Switched to Normal Mode", 2, Theme.Success)
			end
		end)

		navSec:AddButton("[ Mode: ⚠️ Bannable Exploits ]", function()
			if not hasAcceptedBannableWarning then
				showBannableWarningModal(
					function()
						updateSubTabs("Bannable")
						if Context and Context.UI then
							Context.UI:Notify(
								"CRITICAL WARNING",
								"Any functions in this tab will get your account banned from Prison Life",
								6,
								Theme.Danger
							)
						end
					end,
					function()
						updateSubTabs("Normal")
					end
				)
			else
				updateSubTabs("Bannable")
				if Context and Context.UI then
					Context.UI:Notify(
						"CRITICAL WARNING",
						"Any functions in this tab will get your account banned from Prison Life",
						5,
						Theme.Danger
					)
				end
			end
		end)

		------------------------------------------------------------
		-- 1. NORMAL SUB-TAB SECTIONS
		------------------------------------------------------------
		local gunGrabSec = tab:AddSection("Gun Grabbers (Warp-Return)")
		table.insert(normalSections, gunGrabSec)
		gunGrabSec:AddButton("Grab MP5", function()
			grabGun("MP5", GUN_SPAWNS["MP5"])
		end)
		gunGrabSec:AddButton("Grab Remington 870", function()
			grabGun("Remington 870", GUN_SPAWNS["Remington 870"])
		end)
		gunGrabSec:AddButton("Grab AK-47", function()
			grabGun("AK-47", GUN_SPAWNS["AK-47"])
		end)

		local combatSec = tab:AddSection("Combat Modifications")
		table.insert(normalSections, combatSec)
		UIRegistry.Game_NoSpread = combatSec:AddToggle("No Spread", FeatureConfig.Game.NoSpread, function(v)
			FeatureConfig.Game.NoSpread = v
			if anyGunModEnabled() then scanGuns() else restoreGuns() end
		end)
		UIRegistry.Game_FastFire = combatSec:AddToggle("Fast Fire (0.001s)", FeatureConfig.Game.FastFire, function(v)
			FeatureConfig.Game.FastFire = v
			if anyGunModEnabled() then scanGuns() else restoreGuns() end
		end)
		UIRegistry.Game_ForceAuto = combatSec:AddToggle("Force Automatic Fire", FeatureConfig.Game.ForceAuto, function(v)
			FeatureConfig.Game.ForceAuto = v
			if anyGunModEnabled() then scanGuns() else restoreGuns() end
		end)
		UIRegistry.Game_ForceRange = combatSec:AddToggle("Force Range (10,000)", FeatureConfig.Game.ForceRange, function(v)
			FeatureConfig.Game.ForceRange = v
			if anyGunModEnabled() then scanGuns() else restoreGuns() end
		end)
		combatSec:AddButton("Force Apply Gun Mods", function()
			scanGuns()
			if Context and Context.UI then Context.UI:Notify("Prison Life", "Gun mods enforced", nil, Theme.Accent) end
		end)

		local macroSec = tab:AddSection("Fake Macro (Gun Spam)")
		table.insert(normalSections, macroSec)
		UIRegistry.Game_FakeMacro = macroSec:AddToggle("Enable Fake Macro", FeatureConfig.Game.FakeMacro, function(v)
			FeatureConfig.Game.FakeMacro = v
			if not v then stopFakeMacro(); isKeyPressed = false end
		end)
		UIRegistry.Game_FakeMacroKey = macroSec:AddKeybind("Macro Activation Key", FeatureConfig.Game.FakeMacroKey, function(k)
			FeatureConfig.Game.FakeMacroKey = k
			stopFakeMacro()
			isKeyPressed = false
		end)
		UIRegistry.Game_FakeMacroMode = macroSec:AddDropdown("Activation Mode", {"Toggle", "Hold"}, function(v)
			FeatureConfig.Game.FakeMacroMode = v
			stopFakeMacro()
			isKeyPressed = false
		end, FeatureConfig.Game.FakeMacroMode)
		UIRegistry.Game_FakeMacroDelay = macroSec:AddSlider("Macro Delay", math.floor((FeatureConfig.Game.FakeMacroDelay or 0.03) * 1000), 10, 200, function(v)
			FeatureConfig.Game.FakeMacroDelay = v / 1000
		end, " ms")

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
		UIRegistry.Game_PhaseTransparency = doorsSec:AddSlider("Phase Transparency", math.floor((FeatureConfig.Game.PhaseTransparency or 0.65) * 100), 10, 95, function(v)
			FeatureConfig.Game.PhaseTransparency = v / 100
		end, "%")
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
		for _, loc in ipairs(PL_LOCATIONS) do
			local name, cf = loc[1], loc[2]
			tpSec:AddButton(name, function()
				local r = Utils.GetRootPart()
				if r then
					r.CFrame = cf
					if Context and Context.UI then Context.UI:Notify("Teleport", "Moved to " .. name, nil, Theme.Success) end
				end
			end)
		end

		------------------------------------------------------------
		-- 2. BANNABLE SUB-TAB SECTIONS
		------------------------------------------------------------
		local warnSec = tab:AddSection("⚠️ DETECTION WARNING")
		table.insert(bannableSections, warnSec)
		warnSec:AddButton("WARNING: High Ban Risk Functions", function()
			if Context and Context.UI then
				Context.UI:Notify("DANGER", "These melee functions are heavily flagged by server logs!", 5, Theme.Danger)
			end
		end)

		local meleeSec = tab:AddSection("Bannable Melee Exploits")
		table.insert(bannableSections, meleeSec)

		UIRegistry.Game_PunchAura = meleeSec:AddToggle("Punch Aura", FeatureConfig.Game.PunchAura, function(v)
			FeatureConfig.Game.PunchAura = v
		end)
		UIRegistry.Game_PunchAuraRange = meleeSec:AddSlider("Punch Aura Range", FeatureConfig.Game.PunchAuraRange or 15, 5, 40, function(v)
			FeatureConfig.Game.PunchAuraRange = v
		end, " studs")

		UIRegistry.Game_SuperPunch = meleeSec:AddToggle("Super Multi-Punch (Click)", FeatureConfig.Game.SuperPunch, function(v)
			FeatureConfig.Game.SuperPunch = v
		end)
		UIRegistry.Game_SuperPunchHits = meleeSec:AddSlider("Multi-Hit Multiplier", FeatureConfig.Game.SuperPunchHits or 10, 2, 30, function(v)
			FeatureConfig.Game.SuperPunchHits = v
		end, " hits")

		-- Start with Normal visible by default
		updateSubTabs("Normal")
	end

	function Game.Update(dt)
		if FeatureConfig.Game.DoorPhase then
			for part, _ in pairs(_doorPartsSet) do enforcePart(part) end
		end
		if anyGunModEnabled() then enforceGuns() end
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
