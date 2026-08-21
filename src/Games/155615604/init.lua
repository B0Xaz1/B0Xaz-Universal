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

	FeatureConfig.Game = FeatureConfig.Game or {}
	FeatureConfig.Game.DoorPhase = FeatureConfig.Game.DoorPhase or false
	FeatureConfig.Game.DoorGlow = FeatureConfig.Game.DoorGlow ~= false
	FeatureConfig.Game.GlowColor = FeatureConfig.Game.GlowColor or Color3.fromRGB(0, 200, 220)

	local _cache = {}
	local _doorPartsSet = {}

	local Game = {
		Name = "Prison Life",
	}

	-- Helper: check if a part belongs to a door folder
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

		if FeatureConfig.Game.DoorPhase then
			part.CanCollide = false
			if FeatureConfig.Game.DoorGlow then
				part.Material = Enum.Material.Neon
				part.Color = FeatureConfig.Game.GlowColor
				part.Transparency = 0.25
			end
		end
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

	local function restoreAll()
		for part, c in pairs(_cache) do
			if part and part.Parent then
				pcall(function()
					part.CanCollide = c.CanCollide
					part.Transparency = c.Transparency
					part.Color = c.Color
					part.Material = c.Material
				end)
			end
		end
		table.clear(_cache)
		table.clear(_doorPartsSet)
	end

	-- Pre-Physics Frame Loop: Overrides Prison Life's DoorScript every frame
	if Connections and Connections.Add then
		Connections.Add(RS.Stepped:Connect(function()
			if not FeatureConfig.Game.DoorPhase then return end

			for part, _ in pairs(_doorPartsSet) do
				if part and part.Parent then
					-- Force non-collidable
					if part.CanCollide then
						part.CanCollide = false
					end

					-- Force Neon & Color continuously
					if FeatureConfig.Game.DoorGlow then
						if part.Material ~= Enum.Material.Neon then
							part.Material = Enum.Material.Neon
						end
						if part.Color ~= FeatureConfig.Game.GlowColor then
							part.Color = FeatureConfig.Game.GlowColor
						end
						if part.Transparency > 0.4 or part.Transparency < 0.1 then
							part.Transparency = 0.25
						end
					end
				else
					_doorPartsSet[part] = nil
					_cache[part] = nil
				end
			end
		end))

		-- Automatically catch newly spawned doors/fences
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
			if not FeatureConfig.Game.DoorGlow then
				-- Revert material and color back to original, but keep non-collidable
				for part, c in pairs(_cache) do
					if part and part.Parent then
						part.Material = c.Material
						part.Color = c.Color
						part.Transparency = c.Transparency
					end
				end
			else
				scanAllDoors()
			end
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

		doors:AddColorPicker("Glow Color", FeatureConfig.Game.GlowColor, function(c)
			Game.SetGlowColor(c)
		end)

		doors:AddButton("Refresh Door List", function()
			if FeatureConfig.Game.DoorPhase then
				scanAllDoors()
				if Context and Context.UI then Context.UI:Notify("Prison Life", "Doors refreshed", nil, Theme and Theme.Success) end
			end
		end)
	end

	function Game.Update(dt)
		if not FeatureConfig.Game.DoorPhase then return end
		for part, _ in pairs(_doorPartsSet) do
			if part and part.Parent and part.CanCollide then
				part.CanCollide = false
			end
		end
	end

	function Game.Destroy()
		restoreAll()
	end

	return Game
end
