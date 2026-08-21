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
	local _highlights = {}

	local Game = {
		Name = "Prison Life",
	}

	local function collectDoorParts()
		local parts = {}
		for _, folderName in ipairs(DOOR_FOLDERS) do
			local folder = Workspace:FindFirstChild(folderName)
			if folder then
				for _, desc in ipairs(folder:GetDescendants()) do
					if desc:IsA("BasePart") then
						table.insert(parts, desc)
					end
				end
			end
		end
		return parts
	end

	local function applyGlow(part, on)
		if on then
			if _highlights[part] and _highlights[part].Parent then
				pcall(function()
					_highlights[part].FillColor = FeatureConfig.Game.GlowColor
					_highlights[part].OutlineColor = FeatureConfig.Game.GlowColor
				end)
				return
			end
			pcall(function()
				local h = Instance.new("Highlight")
				h.Name = "B0XazDoorGlow"
				h.Adornee = part
				h.FillColor = FeatureConfig.Game.GlowColor
				h.OutlineColor = FeatureConfig.Game.GlowColor
				h.FillTransparency = 0.55
				h.OutlineTransparency = 0
				pcall(function() h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop end)
				h.Parent = part
				_highlights[part] = h
			end)
		else
			if _highlights[part] then
				pcall(function() _highlights[part]:Destroy() end)
				_highlights[part] = nil
			end
		end
	end

	local function applyPart(part)
		if not part or not part.Parent then return end
		if not _cache[part] then
			_cache[part] = {
				CanCollide = part.CanCollide,
				Transparency = part.Transparency,
			}
		end

		if FeatureConfig.Game.DoorPhase then
			part.CanCollide = false
			if FeatureConfig.Game.DoorGlow then
				part.Transparency = math.max(part.Transparency, 0.35)
				applyGlow(part, true)
			else
				applyGlow(part, false)
			end
		end
	end

	local function restorePart(part)
		local c = _cache[part]
		if c and part and part.Parent then
			pcall(function()
				part.CanCollide = c.CanCollide
				part.Transparency = c.Transparency
			end)
		end
		applyGlow(part, false)
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
		for part, h in pairs(_highlights) do
			pcall(function() if h then h:Destroy() end end)
			_highlights[part] = nil
		end
		table.clear(_cache)
		table.clear(_highlights)
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
		if FeatureConfig.Game.DoorPhase then applyAll() end
	end

	function Game.SetGlowColor(color)
		FeatureConfig.Game.GlowColor = color
		if FeatureConfig.Game.DoorPhase and FeatureConfig.Game.DoorGlow then
			for part, h in pairs(_highlights) do
				if h then
					pcall(function()
						h.FillColor = color
						h.OutlineColor = color
					end)
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

		doors:AddToggle("Door Glow", FeatureConfig.Game.DoorGlow, function(v)
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

		local info = tab:AddSection("Folders Detected")
		for _, name in ipairs(DOOR_FOLDERS) do
			local exists = Workspace:FindFirstChild(name) ~= nil
			info:AddButton(name .. (exists and "  [Found]" or "  [Missing]"), function() end)
		end
	end

	function Game.Update(dt)
		if not FeatureConfig.Game.DoorPhase then return end
		for part, _ in pairs(_cache) do
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
