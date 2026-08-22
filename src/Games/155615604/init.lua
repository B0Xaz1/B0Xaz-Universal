-- // src/Games/155615604/init.lua (Prison Life)
return function(Context)
	local Workspace = game:GetService("Workspace")
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local LocalPlayer = Players.LocalPlayer

	local FeatureConfig = Context.FeatureConfig or {}
	local Theme = Context.Theme or {}
	local Connections = Context.Connections or {}
	local UIRegistry = Context.UIRegistry or {}
	local Utils = Context.Utils or {}

	local DEFAULTS = {
		DoorPhase = false, DoorGlow = true,
		GlowColor = Color3.fromRGB(0, 200, 220),
		PhaseTransparency = 0.65,
		NoSpread = false, FastFire = false, ForceAuto = false, ForceRange = false,
		FireRateValue = 0.001, RangeValue = 10000,
		FakeMacro = false, FakeMacroKey = Enum.KeyCode.V,
		FakeMacroMode = "Toggle", FakeMacroDelay = 0.03,
		AntiRestrict = false,
		PunchAura = false, PunchAuraRange = 15,
		SuperPunch = false, SuperPunchHits = 10,
	}

	local LOCATIONS = {
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
	}

	local GUN_SPAWNS = {
		["MP5"] = Vector3.new(813.72, 102.50, 2229.37),
		["Remington 870"] = Vector3.new(820.27, 102.50, 2229.31),
		["AK-47"] = Vector3.new(-932, 100.74, 2039.5),
	}

	local DOOR_FOLDERS = { "doors", "glass", "celldoors", "prison_fences", "prison_gate" }
	local PRISON_GUNS = { "Remington 870", "M9", "AK-47", "Taser", "M4A1", "MP5" }
	local GUN_ATTRS = { "SpreadRadius", "FireRate", "AutoFire", "Range" }
	local RESTRICTED_GUIS = { "Taser", "Flashbang", "Cuffs" }
	local CRIM_POS = Vector3.new(-943, 95, 2058)

	if not FeatureConfig.Game then FeatureConfig.Game = {} end
	for k, v in pairs(DEFAULTS) do
		if FeatureConfig.Game[k] == nil then FeatureConfig.Game[k] = v end
	end

	local function theme(key)
		return Theme[key] or Color3.fromRGB(255, 255, 255)
	end

	local function notify(title, msg, dur, color)
		if Context.UI and Context.UI.Notify then
			Context.UI:Notify(title, msg, dur, color)
		end
	end

	local env = (getgenv and getgenv()) or _G
	local doorCache = env.B0XazDoorCache or {}
	env.B0XazDoorCache = doorCache
	local doorParts = env.B0XazDoorParts or {}
	env.B0XazDoorParts = doorParts
	local gunCache = env.B0XazGunCache or {}
	env.B0XazGunCache = gunCache

	local doorLookup = {}
	for _, n in ipairs(DOOR_FOLDERS) do doorLookup[n] = true end
	local gunLookup = {}
	for _, n in ipairs(PRISON_GUNS) do gunLookup[n] = true end

	local Game = { Name = "Prison Life" }
	local isTeleporting = false
	local lastPunch, lastSuper = 0, 0
	local MeleeEvent = ReplicatedStorage:FindFirstChild("meleeEvent")
	local macroActive, macroThread, toolIndex, keyPressed = false, nil, 1, false
	local hasAcceptedWarning = false

	local function fireMelee(target)
		if not MeleeEvent then MeleeEvent = ReplicatedStorage:FindFirstChild("meleeEvent") end
		if MeleeEvent then
			pcall(function()
				if target then MeleeEvent:FireServer(target) else MeleeEvent:FireServer() end
			end)
		end
	end

	local function warp(pos, waitTime, startMsg, okMsg, tag)
		if isTeleporting then return end
		local root = Utils.GetRootPart and Utils.GetRootPart()
		if not root then
			notify(tag, "Character root not found", nil, theme("Danger"))
			return
		end
		isTeleporting = true
		local orig = root.CFrame
		if startMsg then notify(tag, startMsg, waitTime, theme("Accent")) end
		root.CFrame = CFrame.new(pos)
		task.wait(waitTime)
		local cur = Utils.GetRootPart and Utils.GetRootPart()
		if cur then
			cur.CFrame = orig
			if okMsg then notify(tag, okMsg, 2, theme("Success")) end
		end
		isTeleporting = false
	end

	function Game.BecomeCriminalInside()
		warp(CRIM_POS, 3.5, "Becoming Criminal...", "Returned as Criminal!", "Prison Life")
	end

	function Game.BecomeCriminalOutside()
		if isTeleporting then return end
		local root = Utils.GetRootPart and Utils.GetRootPart()
		if not root then return end
		root.CFrame = CFrame.new(CRIM_POS)
		notify("Prison Life", "Warped to Criminal Base!", 2, theme("Success"))
	end

	-- Doors
	local function isDoorPart(part)
		if not part or not part:IsA("BasePart") then return false end
		local cur = part.Parent
		while cur and cur ~= Workspace do
			if doorLookup[cur.Name:lower()] then return true end
			-- vending machines
			if cur:IsA("Model") and cur.Name == "Model" and cur.Parent and cur.Parent.Name == "vending machine" then
				return true
			end
			cur = cur.Parent
		end
		return false
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

	local function restorePart(part)
		local c = doorCache[part]
		if c and part and part.Parent then
			pcall(function()
				part.CanCollide = c.CanCollide
				part.Transparency = c.Transparency
				part.Color = c.Color
				part.Material = c.Material
			end)
		end
		doorCache[part] = nil
		doorParts[part] = nil
	end

	local function restoreAllDoors()
		for part in pairs(doorCache) do restorePart(part) end
		table.clear(doorCache)
		table.clear(doorParts)
	end

	local function processPart(part)
		if not isDoorPart(part) then return end
		cachePart(part)
		doorParts[part] = true
	end

	local function scanDoors()
		for _, folderName in ipairs(DOOR_FOLDERS) do
			for _, child in ipairs(Workspace:GetChildren()) do
				if child.Name:lower() == folderName then
					for _, d in ipairs(child:GetDescendants()) do
						if d:IsA("BasePart") then processPart(d) end
					end
				end
			end
		end
	end

	local function enforcePart(part)
		local c = doorCache[part]
		if not c or not part or not part.Parent then
			doorParts[part] = nil
			doorCache[part] = nil
			return
		end
		if not FeatureConfig.Game.DoorPhase then return end
		pcall(function()
			if part.CanCollide then part.CanCollide = false end
			local t = math.clamp(FeatureConfig.Game.PhaseTransparency or 0.65, 0.1, 0.95)
			if math.abs(part.Transparency - t) > 0.01 then part.Transparency = t end
			if FeatureConfig.Game.DoorGlow then
				local gc = FeatureConfig.Game.GlowColor or DEFAULTS.GlowColor
				if part.Material ~= Enum.Material.Neon then part.Material = Enum.Material.Neon end
				if part.Color ~= gc then part.Color = gc end
			else
				if part.Material ~= c.Material then part.Material = c.Material end
				if part.Color ~= c.Color then part.Color = c.Color end
			end
		end)
	end

	-- Guns
	local function anyGunMod()
		local g = FeatureConfig.Game
		return g.NoSpread or g.FastFire or g.ForceAuto or g.ForceRange
	end

	local function applyGun(inst)
		if not inst or not inst.Parent then return end
		local function mod(obj)
			if not gunCache[obj] then
				local e = {}
				for _, n in ipairs(GUN_ATTRS) do
					local v = obj:GetAttribute(n)
					if v ~= nil then e[n] = v end
				end
				gunCache[obj] = e
			end
			local g = FeatureConfig.Game
			if g.NoSpread and obj:GetAttribute("SpreadRadius") ~= nil then
				pcall(function() obj:SetAttribute("SpreadRadius", 0) end)
			end
			if g.FastFire and obj:GetAttribute("FireRate") ~= nil then
				pcall(function() obj:SetAttribute("FireRate", g.FireRateValue or 0.001) end)
			end
			if g.ForceAuto and obj:GetAttribute("AutoFire") ~= nil then
				pcall(function() obj:SetAttribute("AutoFire", true) end)
			end
			if g.ForceRange and obj:GetAttribute("Range") ~= nil then
				pcall(function() obj:SetAttribute("Range", g.RangeValue or 10000) end)
			end
		end
		if inst:IsA("Tool") then
			mod(inst)
			for _, d in ipairs(inst:GetDescendants()) do
				for _, a in ipairs(GUN_ATTRS) do
					if d:GetAttribute(a) ~= nil then mod(d) break end
				end
			end
		end
	end

	local function scanGuns()
		local containers = {}
		if LocalPlayer then
			local bp = LocalPlayer:FindFirstChild("Backpack")
			if bp then table.insert(containers, bp) end
			if LocalPlayer.Character then table.insert(containers, LocalPlayer.Character) end
		end
		for _, c in ipairs(containers) do
			for _, child in ipairs(c:GetChildren()) do
				if child:IsA("Tool") then applyGun(child) end
			end
		end
	end

	local function restoreGuns()
		for inst, entry in pairs(gunCache) do
			if inst and inst.Parent and type(entry) == "table" then
				for n, v in pairs(entry) do
					pcall(function() inst:SetAttribute(n, v) end)
				end
			end
			gunCache[inst] = nil
		end
		table.clear(gunCache)
	end

	-- Punch aura
	local function runPunchAura()
		if not FeatureConfig.Game.PunchAura then return end
		local now = os.clock()
		if (now - lastPunch) < 0.1 then return end
		lastPunch = now
		local myRoot = Utils.GetRootPart and Utils.GetRootPart()
		if not myRoot then return end
		local range = math.clamp(FeatureConfig.Game.PunchAuraRange or 15, 5, 40)
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer and Utils.IsAlive and Utils.IsAlive(p) and not (Utils.SameTeam and Utils.SameTeam(p)) then
				local tr = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
				if tr and (tr.Position - myRoot.Position).Magnitude <= range then
					fireMelee(p)
				end
			end
		end
	end

	-- Macro
	local function stopMacro()
		macroActive = false
		if macroThread then pcall(function() task.cancel(macroThread) end) macroThread = nil end
	end

	local function startMacro()
		if macroActive then return end
		macroActive = true
		macroThread = task.spawn(function()
			while macroActive do
				pcall(function()
					local char = LocalPlayer.Character
					local hum = char and char:FindFirstChildOfClass("Humanoid")
					local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
					if not hum or hum.Health <= 0 or not bp then return end
					local guns = {}
					for _, t in ipairs(bp:GetChildren()) do
						if t:IsA("Tool") and gunLookup[t.Name] then table.insert(guns, t) end
					end
					for _, t in ipairs(char:GetChildren()) do
						if t:IsA("Tool") and gunLookup[t.Name] then table.insert(guns, t) end
					end
					if #guns < 2 then return end
					toolIndex = toolIndex % #guns + 1
					local target = guns[toolIndex]
					if target and target.Parent ~= char then
						pcall(function() hum:EquipTool(target) end)
					end
				end)
				task.wait(math.clamp(FeatureConfig.Game.FakeMacroDelay or 0.03, 0.01, 0.5))
			end
		end)
	end

	-- Connections
	if Connections and Connections.Add then
		if FeatureConfig.Game.DoorPhase then task.spawn(scanDoors) end

		Connections.Add(RunService.Heartbeat:Connect(function()
			runPunchAura()
			if FeatureConfig.Game.AntiRestrict then
				local hum = Utils.GetHumanoid and Utils.GetHumanoid()
				if hum then
					local fly = FeatureConfig.Movement and FeatureConfig.Movement.FlyEnabled
					if hum.WalkSpeed < 16 and not fly then
						hum.WalkSpeed = (FeatureConfig.Movement and FeatureConfig.Movement.Speed) or 16
					end
					if hum.JumpPower < 50 then
						hum.JumpPower = (FeatureConfig.Movement and FeatureConfig.Movement.JumpPower) or 50
					end
					if hum.PlatformStand then hum.PlatformStand = false end
				end
				local pgui = LocalPlayer:FindFirstChild("PlayerGui")
				if pgui then
					for _, n in ipairs(RESTRICTED_GUIS) do
						local g = pgui:FindFirstChild(n)
						if g and g.Enabled then g.Enabled = false end
					end
				end
			end
		end))

		Connections.Add(RunService.Stepped:Connect(function()
			if FeatureConfig.Game.DoorPhase then
				for part in pairs(doorParts) do enforcePart(part) end
			end
			if anyGunMod() then scanGuns() end
		end))

		Connections.Add(Workspace.DescendantAdded:Connect(function(d)
			if FeatureConfig.Game.DoorPhase and d:IsA("BasePart") then
				task.defer(function() processPart(d) end)
			end
		end))

		local function hookContainer(c)
			if not c then return end
			Connections.Add(c.ChildAdded:Connect(function(child)
				if anyGunMod() and child:IsA("Tool") then
					task.defer(function() applyGun(child) end)
				end
			end))
		end

		if LocalPlayer:FindFirstChild("Backpack") then hookContainer(LocalPlayer.Backpack) end
		if LocalPlayer.Character then hookContainer(LocalPlayer.Character) end
		Connections.Add(LocalPlayer.CharacterAdded:Connect(function(char)
			hookContainer(char)
			task.wait(0.5)
			if anyGunMod() then scanGuns() end
		end))

		Connections.Add(UserInputService.InputBegan:Connect(function(input, gp)
			if gp then return end
			if FeatureConfig.Game.FakeMacro then
				local mk = FeatureConfig.Game.FakeMacroKey
				local matched = typeof(mk) == "EnumItem" and (
					(mk.EnumType == Enum.KeyCode and input.KeyCode == mk)
					or (mk.EnumType == Enum.UserInputType and input.UserInputType == mk)
				)
				if matched then
					if FeatureConfig.Game.FakeMacroMode == "Toggle" then
						keyPressed = not keyPressed
						if keyPressed then startMacro() else stopMacro() end
					else
						keyPressed = true
						startMacro()
					end
				end
			end
			if FeatureConfig.Game.SuperPunch and input.UserInputType == Enum.UserInputType.MouseButton1 then
				local now = os.clock()
				if (now - lastSuper) >= 0.15 then
					lastSuper = now
					local char = LocalPlayer.Character
					if char and not char:FindFirstChildOfClass("Tool") then
						local hits = math.clamp(FeatureConfig.Game.SuperPunchHits or 10, 1, 30)
						for _ = 1, hits do fireMelee() end
					end
				end
			end
		end))

		Connections.Add(UserInputService.InputEnded:Connect(function(input)
			if FeatureConfig.Game.FakeMacro and FeatureConfig.Game.FakeMacroMode == "Hold" then
				local mk = FeatureConfig.Game.FakeMacroKey
				local matched = typeof(mk) == "EnumItem" and (
					(mk.EnumType == Enum.KeyCode and input.KeyCode == mk)
					or (mk.EnumType == Enum.UserInputType and input.UserInputType == mk)
				)
				if matched then
					keyPressed = false
					stopMacro()
				end
			end
		end))
	end

	function Game.BuildUI(tab)
		local gunSec = tab:AddSection("Gun Grabbers")
		for name, pos in pairs(GUN_SPAWNS) do
			gunSec:AddButton("Grab " .. name, function()
				warp(pos, 1.3, "Acquiring " .. name .. "...", name .. " acquired!", "Gun Grabber")
			end)
		end

		local combat = tab:AddSection("Combat Mods")
		UIRegistry.Game_NoSpread = combat:AddToggle("No Spread", FeatureConfig.Game.NoSpread, function(v)
			FeatureConfig.Game.NoSpread = v
			if anyGunMod() then scanGuns() else restoreGuns() end
		end)
		UIRegistry.Game_FastFire = combat:AddToggle("Fast Fire", FeatureConfig.Game.FastFire, function(v)
			FeatureConfig.Game.FastFire = v
			if anyGunMod() then scanGuns() else restoreGuns() end
		end)
		UIRegistry.Game_ForceAuto = combat:AddToggle("Force Auto", FeatureConfig.Game.ForceAuto, function(v)
			FeatureConfig.Game.ForceAuto = v
			if anyGunMod() then scanGuns() else restoreGuns() end
		end)
		UIRegistry.Game_ForceRange = combat:AddToggle("Force Range", FeatureConfig.Game.ForceRange, function(v)
			FeatureConfig.Game.ForceRange = v
			if anyGunMod() then scanGuns() else restoreGuns() end
		end)

		local doors = tab:AddSection("Doors & Obstacles")
		UIRegistry.Game_DoorPhase = doors:AddToggle("Phase Doors/Fences", FeatureConfig.Game.DoorPhase, function(v)
			FeatureConfig.Game.DoorPhase = v
			if v then scanDoors() else restoreAllDoors() end
		end)
		UIRegistry.Game_DoorGlow = doors:AddToggle("Glow Effect", FeatureConfig.Game.DoorGlow, function(v)
			FeatureConfig.Game.DoorGlow = v
		end)
		UIRegistry.Game_PhaseTransparency = doors:AddSlider("Transparency", math.floor((FeatureConfig.Game.PhaseTransparency or 0.65) * 100), 10, 95, function(v)
			FeatureConfig.Game.PhaseTransparency = v / 100
		end, "%")
		UIRegistry.Game_GlowColor = doors:AddColorPicker("Glow Color", FeatureConfig.Game.GlowColor, function(c)
			FeatureConfig.Game.GlowColor = c
		end)

		local def = tab:AddSection("Defenses & Teams")
		UIRegistry.Game_AntiRestrict = def:AddToggle("Anti-Taser", FeatureConfig.Game.AntiRestrict, function(v)
			FeatureConfig.Game.AntiRestrict = v
		end)
		def:AddButton("Become Criminal (Inside)", function() Game.BecomeCriminalInside() end)
		def:AddButton("Become Criminal (Outside)", function() Game.BecomeCriminalOutside() end)

		local tp = tab:AddSection("Map Teleports")
		for _, loc in ipairs(LOCATIONS) do
			local name, cf = loc[1], loc[2]
			tp:AddButton(name, function()
				local root = Utils.GetRootPart and Utils.GetRootPart()
				if root then
					root.CFrame = cf
					notify("Teleport", "Moved to " .. name, nil, theme("Success"))
				end
			end)
		end

		local macro = tab:AddSection("Fake Macro")
		UIRegistry.Game_FakeMacro = macro:AddToggle("Enable Macro", FeatureConfig.Game.FakeMacro, function(v)
			FeatureConfig.Game.FakeMacro = v
			if not v then stopMacro() keyPressed = false end
		end)
		UIRegistry.Game_FakeMacroKey = macro:AddKeybind("Macro Key", FeatureConfig.Game.FakeMacroKey, function(k)
			FeatureConfig.Game.FakeMacroKey = k
			stopMacro() keyPressed = false
		end)
		UIRegistry.Game_FakeMacroMode = macro:AddDropdown("Mode", { "Toggle", "Hold" }, function(v)
			FeatureConfig.Game.FakeMacroMode = v
			stopMacro() keyPressed = false
		end, FeatureConfig.Game.FakeMacroMode)

		local melee = tab:AddSection("Melee (Ban Risk)")
		UIRegistry.Game_PunchAura = melee:AddToggle("Punch Aura", FeatureConfig.Game.PunchAura, function(v)
			FeatureConfig.Game.PunchAura = v
		end)
		UIRegistry.Game_PunchAuraRange = melee:AddSlider("Aura Range", FeatureConfig.Game.PunchAuraRange or 15, 5, 40, function(v)
			FeatureConfig.Game.PunchAuraRange = v
		end, " studs")
		UIRegistry.Game_SuperPunch = melee:AddToggle("Super Punch", FeatureConfig.Game.SuperPunch, function(v)
			FeatureConfig.Game.SuperPunch = v
		end)
		UIRegistry.Game_SuperPunchHits = melee:AddSlider("Multi-Hit", FeatureConfig.Game.SuperPunchHits or 10, 1, 30, function(v)
			FeatureConfig.Game.SuperPunchHits = v
		end, " hits")
	end

	function Game.Update()
		if FeatureConfig.Game.DoorPhase then
			for part in pairs(doorParts) do enforcePart(part) end
		end
		if anyGunMod() then scanGuns() end
	end

	function Game.Destroy()
		stopMacro()
		restoreAllDoors()
		restoreGuns()
	end

	env.B0XazRestoreDoors = restoreAllDoors
	env.B0XazRestoreGuns = restoreGuns

	return Game
end
