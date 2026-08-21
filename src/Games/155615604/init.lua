-- src/Games/155615604/init.lua
return function(Context)
	local Workspace = game:GetService("Workspace")
	local FeatureConfig = Context and Context.FeatureConfig or {}
	local Theme = Context and Context.Theme or {}

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

	local Game = {
		Name = "Prison Life",
	}

	-- Case-insensitive search for door folders in Workspace
	local function collectDoorParts()
		local parts = {}
		local seen = {}
		for _, folderName in ipairs(DOOR_FOLDERS) do
			for _, obj in ipairs(Workspace:GetChildren()) do
				if obj.Name:lower() == folderName:lower() then
					for _, desc in ipairs(obj:GetDescendants()) do
						if desc:IsA("BasePart") and not seen[desc] then
							seen[desc] = true
							table.insert(parts, desc)
						end
					end
				end
			end
		end
		return parts
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

	local function applyPart(part)
		if not part or not part.Parent then return end
		cachePart(part)

		if FeatureConfig.Game.DoorPhase then
			part.CanCollide = false
			if FeatureConfig.Game.DoorGlow then
				part.Material = Enum.Material.Neon
				part.Color = FeatureConfig.Game.GlowColor
				part.Transparency = 0.25
			else
				local c = _cache[part]
				if c then
					part.Material = c.Material
					part.Color = c.Color
					part.Transparency = c.Transparency
				end
			end
		end
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
	end

	local function applyAll()
		for _, part in ipairs(collectDoorParts()) do
			applyPart(part)
		end
	end

	local function restoreAll()
		for part, _ in pairs(_cache) do
			restorePart(part)
		end
		table.clear(_cache)
	end

	function Game.SetDoorPhase(enabled)
		FeatureConfig.Game.DoorPhase = enabled and true or false
		if FeatureConfig.Game.DoorPhase then
			applyAll()
		else
			restoreAll()
		end
	end

	function Game.SetDoorGlow(enabled)
		FeatureConfig.Game.DoorGlow = enabled and true or false
		if FeatureConfig.Game.DoorPhase then
			applyAll()
		else
			-- If phase is still on but glow turned off, revert material/color
			for part, c in pairs(_cache) do
				if part and part.Parent then
					part.Material = c.Material
					part.Color = c.Color
					part.Transparency = c.Transparency
				end
			end
		end
	end

	function Game.SetGlowColor(color)
		FeatureConfig.Game.GlowColor = color
		if FeatureConfig.Game.DoorPhase and FeatureConfig.Game.DoorGlow then
			applyAll()
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
				applyAll()
				if Context and Context.UI then Context.UI:Notify("Prison Life", "Doors refreshed", nil, Theme and Theme.Success) end
			end
		end)
	end

	-- Runtime loop enforces non-collidable and neon material if Prison Life script attempts to reset them
	function Game.Update(dt)
		if not FeatureConfig.Game.DoorPhase then return end
		for part, _ in pairs(_cache) do
			if part and part.Parent then
				if part.CanCollide then
					part.CanCollide = false
				end
				if FeatureConfig.Game.DoorGlow and part.Material ~= Enum.Material.Neon then
					part.Material = Enum.Material.Neon
					part.Color = FeatureConfig.Game.GlowColor
				end
			end
		end
	end

	function Game.Destroy()
		restoreAll()
	end

	return Game
end
