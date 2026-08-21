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
			
