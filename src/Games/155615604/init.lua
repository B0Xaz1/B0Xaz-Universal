-- src/Games/155615604/init.lua (Prison Life Full Functional Module)
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
		PunchAura = false,
		PunchAuraRange = 15,
		SuperPunch = false,
		SuperPunchHits = 10,
		AntiTaser = false,
		AntiArrest = false,
	}
	for k, v in pairs(defaults) do
		if FeatureConfig.Game[k] == nil then FeatureConfig.Game[k] = v end
	end

	local DOOR_FOLDERS = {"Doors", "glass", "CellDoors", "Prison_Fences", "Prison_Gate"}
	local PRISON_PL_GUNS = {"Remington 870", "M9", "AK-47", "Taser", "M4A1"}

	-- Teleport Coordinates for Prison Life
	local PL_LOCATIONS = {
		["Yard"] = CFrame.new(779, 98, 2465),
		["Armory / Guard Room"] = CFrame.new(837, 100, 2270),
		["Criminal Base"] = CFrame.new(-975, 110, 2055),
		["Cell Block"] = CFrame.new(918, 100, 2445),
		["Cafeteria"] = CFrame.new(935, 100, 2300),
		["Roof"] = CFrame.new(825, 119, 2330),
		["Sewers Exit"] = CFrame.new(917, 78, 2246),
		["Police Spawn"] = CFrame.new(615, 99, 2480),
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

	-- Remotes
	local ItemHandler = Workspace:FindFirstChild("Remote") and Workspace.Remote:FindFirstChild("ItemHandler")
	local TeamEvent = Workspace:FindFirstChild("Remote") and Workspace.Remote:FindFirstChild("TeamEvent")
	local MeleeEvent = ReplicatedStorage:FindFirstChild("meleeEvent")

	----------------------------------------------------------------
	-- ITEM GIVER ENGINE
	----------------------------------------------------------------
	local function giveItem(itemName)
		pcall(function()
			local giver = Workspace:FindFirstChild("Prison_ITEMS") and Workspace.Prison_ITEMS:FindFirstChild("giver")
			if giver and giver:FindFirstChild(itemName) then
				local pickup = giver[itemName]:FindFirstChild("ITEMPICKUP")
				if pickup and ItemHandler then
					ItemHandler:InvokeServer(pickup)
					return
				end
			end
			-- Fallback: Check single items (e.g., Key card)
			local single = Workspace:FindFirstChild("Prison_ITEMS") and Workspace.Prison_ITEMS:FindFirstChild("single")
			if single and single:FindFirstChild(itemName) then
				local pickup = single[itemName]:FindFirstChild("ITEMPICKUP")
				if pickup and ItemHandler then
					ItemHandler:InvokeServer(pickup)
					return
				end
			end
		end)
	end

	function Game.GiveRemington() giveItem("Remington 870") end
	function Game.GiveAK47() giveItem("AK-47") end
	function Game.GiveM9() giveItem("M9") end
	function Game.GiveTaser() giveItem("Taser") end
	function Game.GiveRiotShield() giveItem("Riot Shield") end
	function Game.GiveKeycard() giveItem("Key card") end
	function Game.GiveAllGuns()
		Game.GiveRemington()
		task.wait(0.05)
		Game.GiveAK47()
		task.wait(0.05)
		Game.GiveM9()
		task.wait(0.05)
		Game.GiveKeycard()
	end

	----------------------------------------------------------------
	-- TEAM SWITCHER & AUTO-CRIMINAL
	----------------------------------------------------------------
	function Game.SetTeam(teamColor)
		pcall(function()
			if TeamEvent then
				TeamEvent:FireServer(teamColor)
			end
		end)
	end

	function Game.BecomeCriminal()
		local myRoot = Utils.GetRootPart()
		if not myRoot then return end
		local oldPos = myRoot.CFrame
		-- Teleport to criminal spawn pad, touch it, then return
		myRoot.CFrame = PL_LOCATIONS["Criminal Base"]
		task.wait(0.3)
		myRoot.CFrame = oldPos
	end

	----------------------------------------------------------------
	-- COMBAT & MELEE LOGIC
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
	-- DOORS ENGINE
	----------------------------------------------------------------
	local function isDoorFolder(folderName)
		for _, name in ipairs(DOOR_FOLDERS) do
			if name:lower() == folderName:lower() then return true end
		end
		return false
	end

	local function isDoorPart(part)
		if not part or not part:IsA("BasePart") then return false end
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
			for _, obj in ipairs(Workspace:GetChildren()) do
				if obj.Name:lower() == folderName:lower() then
					for _, desc in ipairs(obj:GetDescendants()) do
						if desc:IsA("BasePart") then processPart(desc) end
					end
				end
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
	-- GUN MODS ENGINE
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
	-- CONNECTIONS / RUNTIME
	----------------------------------------------------------------
	if Connections and Connections.Add then
		if FeatureConfig.Game.DoorPhase then
			task.spawn(scanAllDoors)
		end

		Connections.Add(RS.Heartbeat:Connect(function()
			runPunchAura()

			-- Anti-Taser Defense
			if FeatureConfig.Game.AntiTaser and LocalPlayer.Character then
				local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
				if hum then
					pcall(function()
						hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
						hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
						if hum.PlatformStand then hum.PlatformStand = false end
					end)
				end
			end

			-- Anti-Arrest Defense (breaks handcuffs)
			if FeatureConfig.Game.AntiArrest and LocalPlayer.Character then
				local cuffs = LocalPlayer.Character:FindFirstChild("Handcuffs")
				if cuffs then
					pcall(function() cuffs:Destroy() end)
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

		-- Super Punch listener
		Connections.Add(UIS.InputBegan:Connect(function(input, gp)
			if gp then return end
			handleFakeMacroInput(input, true)

			if FeatureConfig.Game.SuperPunch and input.UserInputType == Enum.UserInputType.MouseButton1 then
				if MeleeEvent and not LocalPlayer.Character:FindFirstChildOfClass("Tool") then
					local hits = FeatureConfig.Game.SuperPunchHits or 10
					for _ = 1, hits do
						MeleeEvent:FireServer()
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
	-- UI BUILDER FOR PRISON LIFE
	----------------------------------------------------------------
	function Game.BuildUI(tab)
		-- Section 1: Item & Weapon Givers
		local weaponsSec = tab:AddSection("Weapons & Item Giver")
		weaponsSec:AddButton("Get All Weapons + Card", function()
			Game.GiveAllGuns()
			if Context and Context.UI then Context.UI:Notify("Prison Life", "Inventory filled!", nil, Theme.Success) end
		end)
		weaponsSec:AddButton("Get Remington 870 (Shotgun)", function() Game.GiveRemington() end)
		weaponsSec:AddButton("Get AK-47 (Rifle)", function() Game.GiveAK47() end)
		weaponsSec:AddButton("Get M9 (Pistol)", function() Game.GiveM9() end)
		weaponsSec:AddButton("Get Taser", function() Game.GiveTaser() end)
		weaponsSec:AddButton("Get Riot Shield", function() Game.GiveRiotShield() end)
		weaponsSec:AddButton("Get Keycard", function() Game.GiveKeycard() end)

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

		-- Section 3: Melee & Punch Enhancements
		local meleeSec = tab:AddSection("Melee & Auras")
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

		-- Section 4: Defenses & Team Control
		local defSec = tab:AddSection("Defenses & Team")
		UIRegistry.Game_AntiTaser = defSec:AddToggle("Anti-Taser (No Ragdoll)", FeatureConfig.Game.AntiTaser, function(v)
			FeatureConfig.Game.AntiTaser = v
		end)
		UIRegistry.Game_AntiArrest = defSec:AddToggle("Anti-Arrest (Break Cuffs)", FeatureConfig.Game.AntiArrest, function(v)
			FeatureConfig.Game.AntiArrest = v
		end)
		defSec:AddButton("Instant Become Criminal", function()
			Game.BecomeCriminal()
			if Context and Context.UI then Context.UI:Notify("Prison Life", "Switched to Criminal", nil, Theme.Success) end
		end)
		defSec:AddButton("Join Inmates Team", function() Game.SetTeam("Bright orange") end)
		defSec:AddButton("Join Guards Team", function() Game.SetTeam("Bright blue") end)
		defSec:AddButton("Join Neutral Team", function() Game.SetTeam("Medium stone grey") end)

		-- Section 5: Doors & Fences
		local doors = tab:AddSection("Doors & Fences")
		UIRegistry.Game_DoorPhase = doors:AddToggle("Phase Through Doors & Fences", FeatureConfig.Game.DoorPhase, function(v)
			FeatureConfig.Game.DoorPhase = v
			if v then scanAllDoors() else restoreAllDoors() end
		end)
		UIRegistry.Game_DoorGlow = doors:AddToggle("Door Glow Effect", FeatureConfig.Game.DoorGlow, function(v)
			FeatureConfig.Game.DoorGlow = v
			if FeatureConfig.Game.DoorPhase then scanAllDoors() end
		end)
		UIRegistry.Game_PhaseTransparency = doors:AddSlider("Phase Transparency", math.floor((FeatureConfig.Game.PhaseTransparency or 0.65) * 100), 10, 95, function(v)
			FeatureConfig.Game.PhaseTransparency = v / 100
		end, "%")
		UIRegistry.Game_GlowColor = doors:AddColorPicker("Glow Color", FeatureConfig.Game.GlowColor, function(c)
			FeatureConfig.Game.GlowColor = c
		end)

		-- Section 6: Fake Macro
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

		-- Section 7: Map Teleports
		local tpSec = tab:AddSection("Map Teleports")
		for name, cf in pairs(PL_LOCATIONS) do
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
