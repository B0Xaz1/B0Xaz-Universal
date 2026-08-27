local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

type ESPRecord = {
	Player: Player,
	Box: any,
	Name: any,
	Health: any,
	HealthBG: any,
	Distance: any,
	Tool: any,
	Backpack: any,
	HeadDot: any,
	LookLine: any,
	Tracer: any,
	Skeleton: { any },
	Highlight: Highlight?,
	Character: Model?,
	SkeletonParts: { BasePart? }?,
	LastInventorySig: string,
	LastBackpackText: string,
}

local FONT_INDICES = {
	["UI"] = 0,
	["System"] = 1,
	["Plex"] = 2,
	["Monospace"] = 3,
}

return function(services: any)
	local StateStore = services:Get("StateStore")
	local TaskScheduler = services:Get("TaskScheduler")
	local Disposer = services:Get("Disposer")
	local PlayerTracker = services:Get("PlayerTracker")
	local DrawingPool = services:Get("DrawingPool")
	local TargetFilter = services:Get("TargetFilter")

	local LocalPlayer = Players.LocalPlayer
	local ESPController = {
		_records = {} :: { [Player]: ESPRecord },
		_throttleTimer = 0,
	}

	-- Six bone segments for the 2D skeleton: head->torso, torso->root,
	-- root->each arm and leg. Missing parts simply skip their segment.
	local SKELETON_SEGMENTS = {
		{ "Head", "Torso" },
		{ "Torso", "Root" },
		{ "Root", "LeftArm" },
		{ "Root", "RightArm" },
		{ "Root", "LeftLeg" },
		{ "Root", "RightLeg" },
	}

	local function resolveSkeletonParts(character: Model): { BasePart? }
		local isR15 = character:FindFirstChild("UpperTorso") ~= nil
		local names = {
			Head = "Head",
			Torso = isR15 and "UpperTorso" or "Torso",
			Root = "HumanoidRootPart",
			LeftArm = isR15 and "LeftUpperArm" or "Left Arm",
			RightArm = isR15 and "RightUpperArm" or "Right Arm",
			LeftLeg = isR15 and "LeftUpperLeg" or "Left Leg",
			RightLeg = isR15 and "RightUpperLeg" or "Right Leg",
		}
		local parts: { BasePart? } = {}
		for key, partName in pairs(names) do
			local part = character:FindFirstChild(partName)
			parts[key] = (part and part:IsA("BasePart")) and (part :: BasePart) or nil
		end
		return parts
	end

	local function createRecord(player: Player): ESPRecord
		local skeletonLines = {}
		for _ = 1, 6 do
			local line = DrawingPool:Acquire("Line")
			if line then table.insert(skeletonLines, line) end
		end

		return {
			Player = player,
			Box = DrawingPool:Acquire("Square"),
			Name = DrawingPool:Acquire("Text"),
			Health = DrawingPool:Acquire("Square"),
			HealthBG = DrawingPool:Acquire("Square"),
			Distance = DrawingPool:Acquire("Text"),
			Tool = DrawingPool:Acquire("Text"),
			Backpack = DrawingPool:Acquire("Text"),
			HeadDot = DrawingPool:Acquire("Circle"),
			LookLine = DrawingPool:Acquire("Line"),
			Tracer = DrawingPool:Acquire("Line"),
			Skeleton = skeletonLines,
			Highlight = nil,
			Character = nil,
			SkeletonParts = nil,
			LastInventorySig = "",
			LastBackpackText = "",
		}
	end

	local function hideRecord(record: ESPRecord)
		if record.Box then record.Box.Visible = false end
		if record.Name then record.Name.Visible = false end
		if record.Health then record.Health.Visible = false end
		if record.HealthBG then record.HealthBG.Visible = false end
		if record.Distance then record.Distance.Visible = false end
		if record.Tool then record.Tool.Visible = false end
		if record.Backpack then record.Backpack.Visible = false end
		if record.HeadDot then record.HeadDot.Visible = false end
		if record.LookLine then record.LookLine.Visible = false end
		if record.Tracer then record.Tracer.Visible = false end
		for _, line in ipairs(record.Skeleton) do line.Visible = false end
		if record.Highlight then record.Highlight.Enabled = false end
	end

	local function destroyRecord(record: ESPRecord)
		hideRecord(record)
		DrawingPool:Release(record.Box)
		DrawingPool:Release(record.Name)
		DrawingPool:Release(record.Health)
		DrawingPool:Release(record.HealthBG)
		DrawingPool:Release(record.Distance)
		DrawingPool:Release(record.Tool)
		DrawingPool:Release(record.Backpack)
		DrawingPool:Release(record.HeadDot)
		DrawingPool:Release(record.LookLine)
		DrawingPool:Release(record.Tracer)
		for _, line in ipairs(record.Skeleton) do DrawingPool:Release(line) end
		if record.Highlight then
			pcall(function() record.Highlight:Destroy() end)
			record.Highlight = nil
		end
	end

	local function onRenderUpdate(dt: number)
		local espSettings = StateStore:Get("ESP")
		local chamsSettings = StateStore:Get("Chams")
		local isESPEnabled = espSettings and espSettings.Enabled and StateStore:HasPermission("ESP.Enabled")
		local isChamsEnabled = chamsSettings and chamsSettings.Enabled and StateStore:HasPermission("Chams.Enabled")

		if not isESPEnabled and not isChamsEnabled then
			for _, rec in pairs(ESPController._records) do hideRecord(rec) end
			return
		end

		local cam = Workspace.CurrentCamera
		if not cam then return end

		local viewportSize = cam.ViewportSize
		local screenBottom = Vector2.new(viewportSize.X * 0.5, viewportSize.Y)
		local myAssets = PlayerTracker:GetLocalAssets()
		local myPos = myAssets and myAssets.RootPart and myAssets.RootPart.Position

		local espColor: Color3 = espSettings.Color or Color3.fromRGB(0, 200, 255)
		local fontIndex = FONT_INDICES[espSettings.Font] or 3
		local hasOutline = espSettings.Outline ~= false
		local maxDistSq = (espSettings.MaxDist or 500) ^ 2

		for player, record in pairs(ESPController._records) do
			local assets = PlayerTracker:GetPlayerAssets(player)

			if not assets or not assets.Character or not assets.RootPart or not assets.Head or assets.Humanoid.Health <= 0 then
				hideRecord(record)
			elseif espSettings.TeamCheck and TargetFilter:IsTeammate(player) then
				hideRecord(record)
			else
				local rootPos = assets.RootPart.Position
				local distSq = myPos and (myPos - rootPos).Magnitude ^ 2 or 0

				if distSq > maxDistSq then
					hideRecord(record)
				else
					-- Chams live on the character model and must be rebuilt
					-- if the record's highlight was lost (e.g. respawn).
					if isChamsEnabled then
						if not record.Highlight or not record.Highlight.Parent then
							local hl = Instance.new("Highlight")
							hl.Name = "B0XazChams"
							hl.Adornee = assets.Character
							hl.Parent = assets.Character
							record.Highlight = hl
						end
						record.Highlight.FillColor = chamsSettings.UseTeamColor and TargetFilter:GetTeamColor(player) or chamsSettings.FillColor
						record.Highlight.OutlineColor = chamsSettings.OutlineColor
						record.Highlight.DepthMode = (chamsSettings.DepthMode == "Occluded") and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop
						record.Highlight.Enabled = true
					elseif record.Highlight then
						record.Highlight.Enabled = false
					end

					if isESPEnabled then
						local headPos = assets.Head.Position + Vector3.new(0, 0.5, 0)
						local feetPos = rootPos - Vector3.new(0, 3, 0)

						local headScreen, headOn = cam:WorldToViewportPoint(headPos)
						local feetScreen, feetOn = cam:WorldToViewportPoint(feetPos)
						local rootScreen, rootOn = cam:WorldToViewportPoint(rootPos)

						if not headOn or not feetOn or headScreen.Z <= 0 then
							hideRecord(record)
						else
							local height = math.clamp(math.abs(headScreen.Y - feetScreen.Y), 6, viewportSize.Y * 1.5)
							local width = height * 0.55
							local halfW, halfH = width * 0.5, height * 0.5
							local rootV = Vector2.new(rootScreen.X, rootScreen.Y)
							local headV = Vector2.new(headScreen.X, headScreen.Y)

							if espSettings.Box and record.Box then
								record.Box.Size = Vector2.new(width, height)
								record.Box.Position = Vector2.new(rootV.X - halfW, rootV.Y - halfH)
								record.Box.Color = espColor
								record.Box.Visible = true
							elseif record.Box then record.Box.Visible = false end

							if espSettings.Name and record.Name then
								record.Name.Text = player.DisplayName
								record.Name.Position = Vector2.new(rootV.X, headV.Y - 18)
								record.Name.Color = espColor
								record.Name.Font = fontIndex
								record.Name.Outline = hasOutline
								record.Name.Visible = true
							elseif record.Name then record.Name.Visible = false end

							if espSettings.Health and record.Health and record.HealthBG then
								local healthRatio = math.clamp(assets.Humanoid.Health / math.max(assets.Humanoid.MaxHealth, 1), 0, 1)
								local barX = rootV.X - halfW - 6
								local barY = rootV.Y - halfH
								record.HealthBG.Size = Vector2.new(3, height)
								record.HealthBG.Position = Vector2.new(barX, barY)
								record.HealthBG.Color = Color3.new(0, 0, 0)
								record.HealthBG.Filled = true
								record.HealthBG.Visible = true

								record.Health.Size = Vector2.new(3, height * healthRatio)
								record.Health.Position = Vector2.new(barX, barY + height * (1 - healthRatio))
								record.Health.Color = Color3.fromHSV(healthRatio * 0.33, 1, 1)
								record.Health.Filled = true
								record.Health.Visible = true
							else
								if record.Health then record.Health.Visible = false end
								if record.HealthBG then record.HealthBG.Visible = false end
							end

							local bottomOffset = 2
							if espSettings.Distance and record.Distance then
								record.Distance.Text = string.format("%dm", math.floor(math.sqrt(distSq)))
								record.Distance.Position = Vector2.new(rootV.X, feetScreen.Y + bottomOffset)
								record.Distance.Color = espColor
								record.Distance.Font = fontIndex
								record.Distance.Outline = hasOutline
								record.Distance.Visible = true
								bottomOffset += 13
							elseif record.Distance then record.Distance.Visible = false end

							if espSettings.Tool and record.Tool then
								local tool = assets.Character:FindFirstChildOfClass("Tool")
								if tool then
									record.Tool.Text = string.format("[%s]", tool.Name)
									record.Tool.Position = Vector2.new(rootV.X, feetScreen.Y + bottomOffset)
									record.Tool.Font = fontIndex
									record.Tool.Outline = hasOutline
									record.Tool.Visible = true
									bottomOffset += 13
								else
									record.Tool.Visible = false
								end
							elseif record.Tool then record.Tool.Visible = false end

							-- 2D skeleton: project both ends of each bone
							if espSettings.Skeleton then
								-- Parts are cached per character instance so the
								-- FindFirstChild lookups run once per respawn.
								if record.Character ~= assets.Character then
									record.Character = assets.Character
									record.SkeletonParts = resolveSkeletonParts(assets.Character)
								end
								local parts = record.SkeletonParts
								for i, segment in ipairs(SKELETON_SEGMENTS) do
									local line = record.Skeleton[i]
									if line and parts then
										local fromPart = parts[segment[1]]
										local toPart = parts[segment[2]]
										if fromPart and toPart then
											local fromScreen, fromOn = cam:WorldToViewportPoint(fromPart.Position)
											local toScreen, toOn = cam:WorldToViewportPoint(toPart.Position)
											if fromOn and toOn and fromScreen.Z > 0 then
												line.From = Vector2.new(fromScreen.X, fromScreen.Y)
												line.To = Vector2.new(toScreen.X, toScreen.Y)
												line.Color = espColor
												line.Visible = true
												continue
											end
										end
									end
									if line then line.Visible = false end
								end
							else
								for _, line in ipairs(record.Skeleton) do
									if line then line.Visible = false end
								end
							end

							-- Look direction: a short ray from the head along
							-- the head's current facing
							if espSettings.LookDir and record.LookLine then
								local headCF = assets.Head.CFrame
								local lookStart = headCF.Position
								local lookEnd = lookStart + headCF.LookVector * 6
								local startScreen, startOn = cam:WorldToViewportPoint(lookStart)
								local endScreen, endOn = cam:WorldToViewportPoint(lookEnd)
								if startOn and endOn and startScreen.Z > 0 then
									record.LookLine.From = Vector2.new(startScreen.X, startScreen.Y)
									record.LookLine.To = Vector2.new(endScreen.X, endScreen.Y)
									record.LookLine.Color = espColor
									record.LookLine.Visible = true
								else
									record.LookLine.Visible = false
								end
							elseif record.LookLine then record.LookLine.Visible = false end

							if espSettings.Tracers and record.Tracer then
								record.Tracer.From = screenBottom
								record.Tracer.To = rootV
								record.Tracer.Color = espColor
								record.Tracer.Visible = true
							elseif record.Tracer then record.Tracer.Visible = false end

							if espSettings.HeadDot and record.HeadDot then
								record.HeadDot.Position = headV
								record.HeadDot.Color = espColor
								record.HeadDot.Radius = 3
								record.HeadDot.Filled = true
								record.HeadDot.Visible = true
							elseif record.HeadDot then record.HeadDot.Visible = false end
						end
					end
				end
			end
		end
	end

	function ESPController:Initialize()
		TaskScheduler:RegisterRender("ESPUpdate", 10, onRenderUpdate)

		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer then
				self._records[player] = createRecord(player)
			end
		end

		PlayerTracker:OnPlayerAdded(function(player)
			if player ~= LocalPlayer and not self._records[player] then
				self._records[player] = createRecord(player)
			end
		end)

		PlayerTracker:OnPlayerRemoving(function(player)
			local rec = self._records[player]
			if rec then
				destroyRecord(rec)
				self._records[player] = nil
			end
		end)

		-- Highlights are parented to other players' characters, so releasing
		-- the drawing pool alone would leave them on screen after an unload.
		Disposer:Add(function()
			for _, rec in pairs(self._records) do
				destroyRecord(rec)
			end
			table.clear(self._records)
		end)
	end

	return ESPController
end
