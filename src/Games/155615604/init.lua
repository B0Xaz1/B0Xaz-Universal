-- src/Games/155615604/init.lua (Prison Life Specialized Module)
return function(Context)
	local Workspace = game:GetService("Workspace")
	local Players = game:GetService("Players")
	local RS = game:GetService("RunService")
	local UIS = game:GetService("UserInputService")

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

	-- Macro state
	local macroLoopActive = false
	local macroThread = nil
	local currentToolIndex = 1
	local isKeyPressed = false
	local isGrabbingGun = false
	local isSwitchingCriminal = false

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
			Context.UI:Notify("Prison Life", "Becoming Criminal (Returning inside in 3.5s)...", 3.5, Theme.Accent)
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
	-- CONNECTIONS / RUNTIME HOOKS
	----------------------------------------------------------------
	if Connections and Connections.Add then
		if FeatureConfig.Game.DoorPhase then
			task.spawn(scanAllDoors)
		end

		Connections.Add(RS.Heartbeat:Connect(function()
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
		end))

		Connections.Add(UIS.InputEnded:Connect(function(input, gp)
			if gp then return end
			handleFakeMacroInput(input, false)
		end))
	end

	----------------------------------------------------------------
	-- UI BUILDER FOR PRISON LIFE
	----------------------------------------------------------------
	function Game.BuildUI(tab)
		-- Section 1: Gun Grabbers (Touch-Teleport)
		local gunGrabSec = tab:AddSection("Gun Grabbers (Warp-Return)")
		gunGrabSec:AddButton("Grab MP5", function()
			grabGun("MP5", GUN_SPAWNS["MP5"])
		end)
		gunGrabSec:AddButton("Grab Remington 870", function()
			grabGun("Remington 870", GUN_SPAWNS["Remington 870"])
		end)
		gunGrabSec:AddButton("Grab AK-47", function()
			grabGun("AK-47", GUN_SPAWNS["AK-47"])
		end)

		-- Section 2: Combat Modifications
		local combat = tab:AddSection("Combat Modifications")
		UIRegistry.Game_NoSpread = combat:AddToggle("No Spread", FeatureConfig.Game.NoSpread, function(v)
			FeatureConfig.Game.NoSpread = v
			if anyGunModEnabled() then scanGuns() else restoreGuns() end
		end)
		UIRegistry.Game_FastFire = combat:AddToggle("Fast Fire (0.001s)", FeatureConfig.Game.FastFire, function(v)
			FeatureConfig.Game.FastFire = v
			if anyGunModEnabled() then scanGuns() else restoreGuns() end
		end)
		UIRegistry.Game_ForceAuto = combat:AddToggle("Force Automatic Fire", FeatureConfig.Game.ForceAuto, function(v)
			FeatureConfig.Game.ForceAuto = v
			if anyGunModEnabled() then scanGuns() else restoreGuns() end
		end)
		UIRegistry.Game_ForceRange = combat:AddToggle("Force Range (10,000)", FeatureConfig.Game.ForceRange, function(v)
			FeatureConfig.Game.ForceRange = v
			if anyGunModEnabled() then scanGuns() else restoreGuns() end
		end)
		combat:AddButton("Force Apply Gun Mods", function()
			scanGuns()
			if Context and Context.UI then Context.UI:Notify("Prison Life", "Gun mods enforced", nil, Theme.Accent) end
		end)

		-- Section 3: Fake Macro
		local macroSec = tab:AddSection("Fake Macro (Gun Spam)")
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

		-- Section 4: Doors & Obstacles
		local doors = tab:AddSection("Doors & Obstacles")
		UIRegistry.Game_DoorPhase = doors:AddToggle("Phase Doors, Fences & Vending", FeatureConfig.Game.DoorPhase, function(v)
			FeatureConfig.Game.DoorPhase = v
			if v then scanAllDoors() else restoreAllDoors() end
		end)
		UIRegistry.Game_DoorGlow = doors:AddToggle("Obstacle Glow Effect", FeatureConfig.Game.DoorGlow, function(v)
			FeatureConfig.Game.DoorGlow = v
			if FeatureConfig.Game.DoorPhase then scanAllDoors() end
		end)
		UIRegistry.Game_PhaseTransparency = doors:AddSlider("Phase Transparency", math.floor((FeatureConfig.Game.PhaseTransparency or 0.65) * 100), 10, 95, function(v)
			FeatureConfig.Game.PhaseTransparency = v / 100
		end, "%")
		UIRegistry.Game_GlowColor = doors:AddColorPicker("Glow Color", FeatureConfig.Game.GlowColor, function(c)
			Game.SetGlowColor(c)
		end)

		-- Section 5: Defenses
		local defSec = tab:AddSection("Defenses")
		UIRegistry.Game_AntiRestrict = defSec:AddToggle("Anti-Taser", FeatureConfig.Game.AntiRestrict, function(v)
			FeatureConfig.Game.AntiRestrict = v
		end)
		defSec:AddButton("Become Criminal (Inside)", function()
			Game.BecomeCriminalInside()
		end)
		defSec:AddButton("Become Criminal (Outside)", function()
			Game.BecomeCriminalOutside()
		end)

		-- Section 6: Map Teleports
		local tpSec = tab:AddSection("Map Teleports")
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
