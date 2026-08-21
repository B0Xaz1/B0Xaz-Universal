-- src/Games/155615604/init.lua (Prison Life)
return function(Context)
	local Workspace = game:GetService("Workspace")
	local Players = game:GetService("Players")
	local RS = game:GetService("RunService")

	local LocalPlayer = Players.LocalPlayer
	local FeatureConfig = Context and Context.FeatureConfig or {}
	local Theme = Context and Context.Theme or {}
	local Connections = Context and Context.Connections or {}
	local UIRegistry = Context and Context.UIRegistry or {}

	local DOOR_FOLDERS = {
		"Doors",
		"glass",
		"CellDoors",
		"Prison_Fences",
		"Prison_Gate",
	}

	local _cache = getgenv().B0XazDoorCache or {}
	getgenv().B0XazDoorCache = _cache

	local _doorPartsSet = getgenv().B0XazDoorParts or {}
	getgenv().B0XazDoorParts = _doorPartsSet

	local _gunCache = getgenv().B0XazGunCache or {}
	getgenv().B0XazGunCache = _gunCache

	local Game = { Name = "Prison Life" }
	local ATTRS = { "SpreadRadius", "FireRate", "AutoFire", "Range" }

	local function isDoorFolder(folderName)
		for _, name in ipairs(DOOR_FOLDERS) do
			if name:lower() == folderName:lower() then
				return true
			end
		end
		return false
	end

	local function isDoorPart(part)
		if not part or not part:IsA("BasePart") then return false end
		local current = part.Parent
		while current and current ~= Workspace do
			if isDoorFolder(current.Name) then
				return true
			end
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
		for part, _ in pairs(_cache) do
			restorePart(part)
		end
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
						if desc:IsA("BasePart") then
							processPart(desc)
						end
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

		if part.CanCollide then
			part.CanCollide = false
		end

		local targetTrans = FeatureConfig.Game.PhaseTransparency or 0.65
		if math.abs(part.Transparency - targetTrans) > 0.01 then
			part.Transparency = targetTrans
		end

		if FeatureConfig.Game.DoorGlow then
			if part.Material ~= Enum.Material.Neon then
				part.Material = Enum.Material.Neon
			end
			if part.Color ~= FeatureConfig.Game.GlowColor then
				part.Color = FeatureConfig.Game.GlowColor
			end
		else
			if part.Material ~= c.Material then
				part.Material = c.Material
			end
			if part.Color ~= c.Color then
				part.Color = c.Color
			end
		end
	end

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
			if v ~= nil then
				entry[name] = v
			end
		end
		_gunCache[inst] = entry
	end

	local function setAttr(inst, name, value)
		pcall(function()
			inst:SetAttribute(name, value)
		end)
	end

	local function applyGunModsTo(inst)
		if not inst or not inst.Parent then return end

		local function touch(obj)
			cacheGunAttrs(obj)

			if FeatureConfig.Game.NoSpread and obj:GetAttribute("SpreadRadius") ~= nil then
				if obj:GetAttribute("SpreadRadius") ~= 0 then
					setAttr(obj, "SpreadRadius", 0)
				end
			end

			if FeatureConfig.Game.FastFire and obj:GetAttribute("FireRate") ~= nil then
				local fr = FeatureConfig.Game.FireRateValue or 0.001
				if obj:GetAttribute("FireRate") ~= fr then
					setAttr(obj, "FireRate", fr)
				end
			end

			if FeatureConfig.Game.ForceAuto and obj:GetAttribute("AutoFire") ~= nil then
				if obj:GetAttribute("AutoFire") ~= true then
					setAttr(obj, "AutoFire", true)
				end
			end

			if FeatureConfig.Game.ForceRange and obj:GetAttribute("Range") ~= nil then
				local rng = FeatureConfig.Game.RangeValue or 10000
				if obj:GetAttribute("Range") ~= rng then
					setAttr(obj, "Range", rng)
				end
			end
		end

		if inst:IsA("Tool") then
			touch(inst)
			for _, d in ipairs(inst:GetDescendants()) do
				if d:GetAttribute("SpreadRadius") ~= nil
					or d:GetAttribute("FireRate") ~= nil
					or d:GetAttribute("AutoFire") ~= nil
					or d:GetAttribute("Range") ~= nil then
					touch(d)
				end
			end
		else
			if inst:GetAttribute("SpreadRadius") ~= nil
				or inst:GetAttribute("FireRate") ~= nil
				or inst:GetAttribute("AutoFire") ~= nil
				or inst:GetAttribute("Range") ~= nil then
				touch(inst)
			end
		end
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
		for inst, entry in pairs(_gunCache) do
			if inst and inst.Parent and type(entry) == "table" then
				for name, original in pairs(entry) do
					pcall(function()
						inst:SetAttribute(name, original)
					end)
				end
			end
			_gunCache[inst] = nil
		end
		table.clear(_gunCache)
	end

	local function anyGunModEnabled()
		return FeatureConfig.Game.NoSpread
			or FeatureConfig.Game.FastFire
			or FeatureConfig.Game.ForceAuto
			or FeatureConfig.Game.ForceRange
	end

	local function enforceGuns()
		if not anyGunModEnabled() then return end
		scanGuns()
	end

	if Connections and Connections.Add then
		Connections.Add(RS.Stepped:Connect(function()
			if FeatureConfig.Game.DoorPhase then
				for part, _ in pairs(_doorPartsSet) do
					enforcePart(part)
				end
			end
			if anyGunModEnabled() then
				enforceGuns()
			end
		end))

		Connections.Add(Workspace.DescendantAdded:Connect(function(desc)
			if FeatureConfig.Game.DoorPhase and desc:IsA("BasePart") then
				task.defer(function()
					processPart(desc)
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
	end

	function Game.SetDoorPhase(enabled)
		FeatureConfig.Game.DoorPhase = enabled and true or false
		if FeatureConfig.Game.DoorPhase then
			scanAllDoors()
		else
			restoreAllDoors()
		end
	end

	function Game.SetDoorGlow(enabled)
		FeatureConfig.Game.DoorGlow = enabled and true or false
		if FeatureConfig.Game.DoorPhase then
			scanAllDoors()
		end
	end

	function Game.SetGlowColor(color)
		FeatureConfig.Game.GlowColor = color
	end

	local function afterGunToggle()
		if anyGunModEnabled() then
			scanGuns()
		else
			restoreGuns()
		end
	end

	function Game.SetNoSpread(enabled)
		FeatureConfig.Game.NoSpread = enabled and true or false
		afterGunToggle()
	end

	function Game.SetFastFire(enabled)
		FeatureConfig.Game.FastFire = enabled and true or false
		afterGunToggle()
	end

	function Game.SetForceAuto(enabled)
		FeatureConfig.Game.ForceAuto = enabled and true or false
		afterGunToggle()
	end

	function Game.SetForceRange(enabled)
		FeatureConfig.Game.ForceRange = enabled and true or false
		afterGunToggle()
	end

	function Game.BuildUI(tab)
		local doors = tab:AddSection("Doors & Fences")

		UIRegistry.Game_DoorPhase = doors:AddToggle("Phase Through Doors", FeatureConfig.Game.DoorPhase, function(v)
			Game.SetDoorPhase(v)
			if Context and Context.UI then
				Context.UI:Notify("Prison Life", v and "Door phase enabled" or "Door phase disabled", nil, Theme.Success)
			end
		end)

		UIRegistry.Game_DoorGlow = doors:AddToggle("Door Glow (Neon)", FeatureConfig.Game.DoorGlow, function(v)
			Game.SetDoorGlow(v)
		end)

		UIRegistry.Game_PhaseTransparency = doors:AddSlider("Door Transparency", math.floor((FeatureConfig.Game.PhaseTransparency or 0.65) * 100), 10, 95, function(v)
			FeatureConfig.Game.PhaseTransparency = v / 100
		end, "%")

		UIRegistry.Game_GlowColor = doors:AddColorPicker("Glow Color", FeatureConfig.Game.GlowColor, function(c)
			Game.SetGlowColor(c)
		end)

		doors:AddButton("Refresh Door List", function()
			if FeatureConfig.Game.DoorPhase then
				scanAllDoors()
				if Context and Context.UI then
					Context.UI:Notify("Prison Life", "Doors refreshed", nil, Theme.Success)
				end
			end
		end)

		local combat = tab:AddSection("Combat")

		UIRegistry.Game_NoSpread = combat:AddToggle("No Spread", FeatureConfig.Game.NoSpread, function(v)
			Game.SetNoSpread(v)
			if Context and Context.UI then
				Context.UI:Notify("Prison Life", v and "Spread removed" or "Spread restored", nil, Theme.Success)
			end
		end)

		UIRegistry.Game_FastFire = combat:AddToggle("Fast Fire", FeatureConfig.Game.FastFire, function(v)
			Game.SetFastFire(v)
			if Context and Context.UI then
				Context.UI:Notify("Prison Life", v and "Fast fire enabled" or "Fire rate restored", nil, Theme.Success)
			end
		end)

		UIRegistry.Game_ForceAuto = combat:AddToggle("Force AutoFire", FeatureConfig.Game.ForceAuto, function(v)
			Game.SetForceAuto(v)
			if Context and Context.UI then
				Context.UI:Notify("Prison Life", v and "Auto-fire enabled" or "Auto-fire restored", nil, Theme.Success)
			end
		end)

		UIRegistry.Game_ForceRange = combat:AddToggle("Force Range (10k)", FeatureConfig.Game.ForceRange, function(v)
			Game.SetForceRange(v)
			if Context and Context.UI then
				Context.UI:Notify("Prison Life", v and "Range extended" or "Range restored", nil, Theme.Success)
			end
		end)

		combat:AddButton("Force Apply Gun Mods", function()
			scanGuns()
			if Context and Context.UI then
				Context.UI:Notify("Prison Life", "Gun mods enforced", nil, Theme.Accent)
			end
		end)
	end

	function Game.Update(dt)
		if FeatureConfig.Game.DoorPhase then
			for part, _ in pairs(_doorPartsSet) do
				enforcePart(part)
			end
		end
		if anyGunModEnabled() then
			enforceGuns()
		end
	end

	function Game.Destroy()
		restoreAllDoors()
		restoreGuns()
	end

	getgenv().B0XazRestoreDoors = restoreAllDoors
	getgenv().B0XazRestoreGuns = restoreGuns

	return Game
end
