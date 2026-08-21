-- src/Games/155615604/init.lua
return function(Context)
	local Workspace = game:GetService("Workspace")
	local RS = game:GetService("RunService")

	local FeatureConfig = Context and Context.FeatureConfig or {}
	local Theme = Context and Context.Theme or {}
	local Connections = Context and Context.Connections or {}

	local DOOR_FOLDERS = {
		"Doors",
		"glass",
		"CellDoors",
		"Prison_Fences",
		"Prison_Gate",
	}

	-- Global Cache for Re-Exec / Cleanup
	local _cache = getgenv().B0XazDoorCache
	if type(_cache) ~= "table" then
		_cache = {}
		getgenv().B0XazDoorCache = _cache
	end

	local _doorPartsSet = getgenv().B0XazDoorParts
	if type(_doorPartsSet) ~= "table" then
		_doorPartsSet = {}
		getgenv().B0XazDoorParts = _doorPartsSet
	end

	FeatureConfig.Game = FeatureConfig.Game or {}
	FeatureConfig.Game.DoorPhase = FeatureConfig.Game.DoorPhase or false
	FeatureConfig.Game.DoorGlow = FeatureConfig.Game.DoorGlow ~= false
	FeatureConfig.Game.GlowColor = FeatureConfig.Game.GlowColor or Color3.fromRGB(0, 200, 220)
	FeatureConfig.Game.PhaseTransparency = FeatureConfig.Game.PhaseTransparency or 0.65

	local Game = { Name = "Prison Life" }

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

	local function restoreAll()
		for part, _ in pairs(_cache) do
			restorePart(part)
		end
		table.clear(_cache)
		table.clear(_doorPartsSet)
	end

	-- Restore previous session visuals immediately on script execute
	restoreAll()

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

		if FeatureConfig.Game.DoorPhase then
			-- 1. Always Non-Collidable
			if part.CanCollide then
				part.CanCollide = false
			end

			-- 2. Always See-Through Phase Transparency
			local targetTrans = FeatureConfig.Game.PhaseTransparency or 0.65
			if math.abs(part.Transparency - targetTrans) > 0.01 then
				part.Transparency = targetTrans
			end

			-- 3. Apply Glow vs Normal Material
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
	end

	if Connections and Connections.Add then
		Connections.Add(RS.Stepped:Connect(function()
			if not FeatureConfig.Game.DoorPhase then return end
			for part, _ in pairs(_doorPartsSet) do
				enforcePart(part)
			end
		end))

		Connections.Add(Workspace.DescendantAdded:Connect(function(desc)
			if FeatureConfig.Game.DoorPhase and desc:IsA("BasePart") then
				task.defer(function()
					processPart(desc)
				end)
			end
		end))
	end

	function Game.SetDoorPhase(enabled)
		FeatureConfig.Game.DoorPhase = enabled and true or false
		if FeatureConfig.Game.DoorPhase then
			scanAllDoors()
		else
			restoreAll()
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
		if FeatureConfig.Game.DoorPhase and FeatureConfig.Game.DoorGlow then
			for part, _ in pairs(_doorPartsSet) do
				if part and part.Parent then
					part.Color = color
				end
			end
		end
	end

	function Game.BuildUI(tab)
		local doors = tab:AddSection("Doors & Fences")

		doors:AddToggle("Phase Through Doors", FeatureConfig.Game.DoorPhase, function(v)
			Game.SetDoorPhase(v)
			if Context and Context.UI then
				Context.UI:Notify("Prison Life", v and "Door phase enabled" or "Door phase disabled", nil, Theme and Theme.Success)
			end
		end)

		doors:AddToggle("Door Glow (Neon)", FeatureConfig.Game.DoorGlow, function(v)
			Game.SetDoorGlow(v)
		end)

		doors:AddSlider("Door Transparency", math.floor((FeatureConfig.Game.PhaseTransparency or 0.65) * 100), 10, 95, function(v)
			FeatureConfig.Game.PhaseTransparency = v / 100
			if FeatureConfig.Game.DoorPhase then
				for part, _ in pairs(_doorPartsSet) do
					if part and part.Parent then
						part.Transparency = FeatureConfig.Game.PhaseTransparency
					end
				end
			end
		end, "%")

		doors:AddColorPicker("Glow Color", FeatureConfig.Game.GlowColor, function(c)
			Game.SetGlowColor(c)
		end)

		doors:AddButton("Refresh Door List", function()
			if FeatureConfig.Game.DoorPhase then
				scanAllDoors()
				if Context and Context.UI then
					Context.UI:Notify("Prison Life", "Doors refreshed", nil, Theme and Theme.Success)
				end
			end
		end)
	end

	function Game.Update(dt)
		if not FeatureConfig.Game.DoorPhase then return end
		for part, _ in pairs(_doorPartsSet) do
			enforcePart(part)
		end
	end

	function Game.Destroy()
		restoreAll()
	end

	getgenv().B0XazRestoreDoors = restoreAll

	return Game
end
