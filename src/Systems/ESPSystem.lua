local SETTINGS = {
	DRAWING_DEFAULTS = {
		BOX_THICKNESS = 2,
		TRACER_THICKNESS = 1.5,
		SKELETON_THICKNESS = 1,
		NAME_SIZE = 13,
		DIST_SIZE = 11,
		HEAD_DOT_RADIUS = 4,
		LOOK_LINE_THICKNESS = 2,
		HEALTH_BAR_WIDTH = 3,
		HEALTH_BAR_OFFSET_X = 6,
		HEALTH_BAR_BG_TRANSPARENCY = 0.5,
		HIGHLIGHT_FILL_TRANSPARENCY = 0.5,
	},
	OFFSETS = {
		HEAD_VERTICAL = Vector3.new(0, 0.5, 0),
		FEET_VERTICAL = Vector3.new(0, 3, 0),
		LOOK_VECTOR_LENGTH = 4.5,
		BOX_WIDTH_RATIO = 0.55,
		BOX_HEIGHT_RATIO = 0.5,
		NAME_Y_OFFSET = 24,
		DIST_Y_OFFSET = 3,
	},
	LIMITS = {
		MAX_SKELETON_LINES = 6,
		DEFAULT_MAX_DIST = 500,
		CHARACTER_WAIT_DELAY = 0.2,
		MIN_HEALTH = 1,
		HEALTH_HUE_SCALE = 0.33,
	},
	COLORS = {
		BLACK = Color3.new(0, 0, 0),
		WHITE = Color3.new(1, 1, 1),
	},
}

return function(Context)
	local Players = game:GetService("Players")
	local Workspace = game:GetService("Workspace")
	local LocalPlayer = Players.LocalPlayer

	local FeatureConfig = (Context and Context.FeatureConfig) or {}
	local CONFIG = (Context and Context.CONFIG) or {}
	local Utils = (Context and Context.Utils) or {}
	local DrawingManager = (Context and Context.DrawingManager) or {}
	local Connections = (Context and Context.Connections) or {}

	local DrawingESP = {}
	getgenv().B0XazDrawingESP = DrawingESP

	local Highlights = {}
	getgenv().B0XazHighlights = Highlights

	local ESPSystem = {}
	local SessionId = getgenv().B0XazSessionId or 0

	local function getCamera()
		return Workspace.CurrentCamera
	end

	local function isSessionAlive()
		return getgenv().B0XazSessionId == SessionId
	end

	local function destroyESPData(data)
		if type(data) ~= "table" or not DrawingManager.SafeRemove then return end
		DrawingManager.SafeRemove(data.Box)
		DrawingManager.SafeRemove(data.Name)
		DrawingManager.SafeRemove(data.Health)
		DrawingManager.SafeRemove(data.HealthBG)
		DrawingManager.SafeRemove(data.Distance)
		DrawingManager.SafeRemove(data.HeadDot)
		DrawingManager.SafeRemove(data.LookLine)
		DrawingManager.SafeRemove(data.Tracer)
		if type(data.Skeleton) == "table" then
			for _, line in ipairs(data.Skeleton) do
				DrawingManager.SafeRemove(line)
			end
		end
	end

	local function hidePlayerDrawings(data)
		if not data then return end
		if data.Box then data.Box.Visible = false end
		if data.Name then data.Name.Visible = false end
		if data.Health then data.Health.Visible = false end
		if data.HealthBG then data.HealthBG.Visible = false end
		if data.Distance then data.Distance.Visible = false end
		if data.HeadDot then data.HeadDot.Visible = false end
		if data.LookLine then data.LookLine.Visible = false end
		if data.Tracer then data.Tracer.Visible = false end
		if data.Skeleton then
			for index = 1, #data.Skeleton do
				local line = data.Skeleton[index]
				if line then line.Visible = false end
			end
		end
	end

	function ESPSystem.CreatePlayerESP(player)
		if not isSessionAlive() or player == LocalPlayer or not DrawingManager.Available then return end

		if DrawingESP[player] then
			destroyESPData(DrawingESP[player])
			DrawingESP[player] = nil
		end

		local defaultColor = (FeatureConfig.ESP and FeatureConfig.ESP.Color) or SETTINGS.COLORS.WHITE
		local skeletonThickness = CONFIG.ESP_SKELETON_THICKNESS or SETTINGS.DRAWING_DEFAULTS.SKELETON_THICKNESS
		local tracerThickness = CONFIG.ESP_TRACER_THICKNESS or SETTINGS.DRAWING_DEFAULTS.TRACER_THICKNESS
		local nameSize = CONFIG.ESP_TEXT_SIZE_NAME or SETTINGS.DRAWING_DEFAULTS.NAME_SIZE
		local distSize = CONFIG.ESP_TEXT_SIZE_DIST or SETTINGS.DRAWING_DEFAULTS.DIST_SIZE

		local skeletonLines = table.create(SETTINGS.LIMITS.MAX_SKELETON_LINES)
		for _ = 1, SETTINGS.LIMITS.MAX_SKELETON_LINES do
			local line = DrawingManager.NewLine({ Thickness = skeletonThickness, Color = defaultColor })
			if line then
				table.insert(skeletonLines, line)
			end
		end

		DrawingESP[player] = {
			Box = DrawingManager.NewSquare({ Thickness = SETTINGS.DRAWING_DEFAULTS.BOX_THICKNESS, Color = defaultColor }),
			Name = DrawingManager.NewText({ Size = nameSize, Color = defaultColor }),
			Health = DrawingManager.NewSquare({ Filled = true }),
			HealthBG = DrawingManager.NewSquare({ Filled = true }),
			Distance = DrawingManager.NewText({ Size = distSize, Color = defaultColor }),
			HeadDot = DrawingManager.NewCircle({ Radius = SETTINGS.DRAWING_DEFAULTS.HEAD_DOT_RADIUS, Filled = true, Color = defaultColor }),
			LookLine = DrawingManager.NewLine({ Thickness = SETTINGS.DRAWING_DEFAULTS.LOOK_LINE_THICKNESS, Color = defaultColor }),
			Tracer = DrawingManager.NewLine({ Thickness = tracerThickness, Color = defaultColor }),
			Skeleton = skeletonLines,
		}
	end

	function ESPSystem.RemovePlayerESP(player)
		local data = DrawingESP[player]
		if data then
			destroyESPData(data)
			DrawingESP[player] = nil
		end
		ESPSystem.RemoveHighlight(player)
	end

	function ESPSystem.AddHighlight(player)
		if not isSessionAlive() or Highlights[player] then return end
		local character = player and player.Character
		if not character or not character.Parent then return end

		local chamsConfig = FeatureConfig.Chams or {}
		local success, highlight = pcall(function()
			local instance = Instance.new("Highlight")
			instance.Name = "B0XazChams"
			instance.Adornee = character
			instance.FillColor = chamsConfig.FillColor or SETTINGS.COLORS.WHITE
			instance.OutlineColor = chamsConfig.OutlineColor or SETTINGS.COLORS.BLACK
			instance.FillTransparency = SETTINGS.DRAWING_DEFAULTS.HIGHLIGHT_FILL_TRANSPARENCY
			instance.Parent = character
			return instance
		end)

		if success and highlight then
			Highlights[player] = highlight
		end
	end

	function ESPSystem.RemoveHighlight(player)
		local highlight = Highlights[player]
		if highlight then
			pcall(function() highlight:Destroy() end)
			Highlights[player] = nil
		end
	end

	local function getBones(character, humanoid)
		local isR15 = humanoid and humanoid.RigType == Enum.HumanoidRigType.R15
		local bones = {}
		local head = character:FindFirstChild("Head")
		if not head then return bones end

		if isR15 then
			local upperTorso = character:FindFirstChild("UpperTorso")
			local lowerTorso = character:FindFirstChild("LowerTorso")
			if upperTorso and lowerTorso then
				table.insert(bones, { head, upperTorso })
				table.insert(bones, { upperTorso, lowerTorso })
				local lua = character:FindFirstChild("LeftUpperArm")
				local rua = character:FindFirstChild("RightUpperArm")
				local lul = character:FindFirstChild("LeftUpperLeg")
				local rul = character:FindFirstChild("RightUpperLeg")
				if lua then table.insert(bones, { upperTorso, lua }) end
				if rua then table.insert(bones, { upperTorso, rua }) end
				if lul then table.insert(bones, { lowerTorso, lul }) end
				if rul then table.insert(bones, { lowerTorso, rul }) end
			end
		else
			local torso = character:FindFirstChild("Torso")
			if torso then
				table.insert(bones, { head, torso })
				local la = character:FindFirstChild("Left Arm")
				local ra = character:FindFirstChild("Right Arm")
				local ll = character:FindFirstChild("Left Leg")
				local rl = character:FindFirstChild("Right Leg")
				if la then table.insert(bones, { torso, la }) end
				if ra then table.insert(bones, { torso, ra }) end
				if ll then table.insert(bones, { torso, ll }) end
				if rl then table.insert(bones, { torso, rl }) end
			end
		end
		return bones
	end

	local function hookPlayer(player)
		if not isSessionAlive() or player == LocalPlayer then return end
		ESPSystem.CreatePlayerESP(player)

		if Connections and Connections.Add then
			Connections.Add(player.CharacterAdded:Connect(function()
				if not isSessionAlive() then return end
				task.wait(SETTINGS.LIMITS.CHARACTER_WAIT_DELAY)
				if FeatureConfig.Chams and FeatureConfig.Chams.Enabled then
					ESPSystem.RemoveHighlight(player)
					ESPSystem.AddHighlight(player)
				end
			end))

			Connections.Add(player.CharacterRemoving:Connect(function()
				if not isSessionAlive() then return end
				ESPSystem.RemoveHighlight(player)
				if DrawingESP[player] then
					hidePlayerDrawings(DrawingESP[player])
				end
			end))
		end
	end

	function ESPSystem.DestroyAll()
		for player in pairs(DrawingESP) do
			ESPSystem.RemovePlayerESP(player)
		end
		table.clear(DrawingESP)
		for player in pairs(Highlights) do
			ESPSystem.RemoveHighlight(player)
		end
		table.clear(Highlights)
	end

	function ESPSystem.InitializeAll()
		if not isSessionAlive() then return end
		ESPSystem.DestroyAll()

		for _, player in ipairs(Players:GetPlayers()) do
			task.spawn(hookPlayer, player)
		end

		if Connections and Connections.Add then
			Connections.Add(Players.PlayerAdded:Connect(function(player)
				if not isSessionAlive() then return end
				hookPlayer(player)
			end))
			Connections.Add(Players.PlayerRemoving:Connect(function(player)
				if not isSessionAlive() then return end
				ESPSystem.RemovePlayerESP(player)
			end))
		end
	end

	function ESPSystem.Update()
		if not isSessionAlive() then return end

		local camera = getCamera()
		if not camera then return end

		local espCfg = FeatureConfig.ESP
		local chamsCfg = FeatureConfig.Chams

		local hasESP = espCfg and espCfg.Enabled and (
			espCfg.Box or espCfg.Name or espCfg.Health or espCfg.Distance or
			espCfg.Tracers or espCfg.Skeleton or espCfg.HeadDot or espCfg.LookDir
		)
		local hasChams = chamsCfg and chamsCfg.Enabled

		if not hasESP and not hasChams then
			for _, data in pairs(DrawingESP) do
				hidePlayerDrawings(data)
			end
			for player in pairs(Highlights) do
				ESPSystem.RemoveHighlight(player)
			end
			return
		end

		local myAssets = Utils.GetPlayerAssets and Utils.GetPlayerAssets(LocalPlayer)
		local myPos = myAssets and myAssets.RootPart and myAssets.RootPart.Position
		local espColor = (espCfg and espCfg.Color) or SETTINGS.COLORS.WHITE
		local maxDist = (espCfg and espCfg.MaxDist) or SETTINGS.LIMITS.DEFAULT_MAX_DIST
		local teamCheck = espCfg and espCfg.TeamCheck

		local viewportSize = camera.ViewportSize
		local screenBottom = Vector2.new(viewportSize.X * 0.5, viewportSize.Y)

		for player, data in pairs(DrawingESP) do
			if not isSessionAlive() then return end

			local assets = Utils.GetPlayerAssets and Utils.GetPlayerAssets(player)
			if not (assets and assets.Character and assets.RootPart and assets.Head and assets.Humanoid) then
				hidePlayerDrawings(data)
				continue
			end

			if teamCheck and Utils.SameTeam and Utils.SameTeam(player) then
				hidePlayerDrawings(data)
				ESPSystem.RemoveHighlight(player)
				continue
			end

			local rootPos = assets.RootPart.Position
			local dist3D = myPos and (myPos - rootPos).Magnitude or 0
			if dist3D > maxDist then
				hidePlayerDrawings(data)
				continue
			end

			if hasChams then
				local highlight = Highlights[player]
				if not highlight or not highlight.Parent or highlight.Adornee ~= assets.Character then
					ESPSystem.RemoveHighlight(player)
					ESPSystem.AddHighlight(player)
				else
					highlight.FillColor = chamsCfg.FillColor or SETTINGS.COLORS.WHITE
					highlight.OutlineColor = chamsCfg.OutlineColor or SETTINGS.COLORS.BLACK
				end
			else
				ESPSystem.RemoveHighlight(player)
			end

			if not hasESP then
				hidePlayerDrawings(data)
				continue
			end

			local rootScreen, rootOnScreen = camera:WorldToViewportPoint(rootPos)
			if not rootOnScreen or rootScreen.Z <= 0 then
				hidePlayerDrawings(data)
				continue
			end

			local headPos = assets.Head.Position
			local headScreen = camera:WorldToViewportPoint(headPos + SETTINGS.OFFSETS.HEAD_VERTICAL)
			local feetScreen = camera:WorldToViewportPoint(rootPos - SETTINGS.OFFSETS.FEET_VERTICAL)

			local height = math.abs(headScreen.Y - feetScreen.Y)
			local width = height * SETTINGS.OFFSETS.BOX_WIDTH_RATIO
			local halfWidth = width * 0.5
			local halfHeight = height * SETTINGS.OFFSETS.BOX_HEIGHT_RATIO
			local rootScreenPos = Vector2.new(rootScreen.X, rootScreen.Y)
			local headScreenPos = Vector2.new(headScreen.X, headScreen.Y)

			if espCfg.Box and data.Box then
				data.Box.Size = Vector2.new(width, height)
				data.Box.Position = Vector2.new(rootScreenPos.X - halfWidth, rootScreenPos.Y - halfHeight)
				data.Box.Color = espColor
				data.Box.Visible = true
			elseif data.Box then
				data.Box.Visible = false
			end

			if espCfg.Name and data.Name then
				data.Name.Text = player.DisplayName or player.Name
				data.Name.Position = Vector2.new(rootScreenPos.X, headScreenPos.Y - SETTINGS.OFFSETS.NAME_Y_OFFSET)
				data.Name.Color = espColor
				data.Name.Visible = true
			elseif data.Name then
				data.Name.Visible = false
			end

			if espCfg.Health and data.Health and data.HealthBG then
				local humanoid = assets.Humanoid
				local maxHealth = math.max(humanoid.MaxHealth, SETTINGS.LIMITS.MIN_HEALTH)
				local healthRatio = math.clamp(humanoid.Health / maxHealth, 0, 1)
				local barX = rootScreenPos.X - halfWidth - SETTINGS.DRAWING_DEFAULTS.HEALTH_BAR_OFFSET_X
				local barY = rootScreenPos.Y - halfHeight

				data.HealthBG.Size = Vector2.new(SETTINGS.DRAWING_DEFAULTS.HEALTH_BAR_WIDTH, height)
				data.HealthBG.Position = Vector2.new(barX, barY)
				data.HealthBG.Color = SETTINGS.COLORS.BLACK
				data.HealthBG.Transparency = SETTINGS.DRAWING_DEFAULTS.HEALTH_BAR_BG_TRANSPARENCY
				data.HealthBG.Visible = true

				data.Health.Size = Vector2.new(SETTINGS.DRAWING_DEFAULTS.HEALTH_BAR_WIDTH, height * healthRatio)
				data.Health.Position = Vector2.new(barX, barY + height * (1 - healthRatio))
				data.Health.Color = Color3.fromHSV(healthRatio * SETTINGS.LIMITS.HEALTH_HUE_SCALE, 1, 1)
				data.Health.Visible = true
			elseif data.Health then
				data.Health.Visible = false
				if data.HealthBG then
					data.HealthBG.Visible = false
				end
			end

			if espCfg.Distance and data.Distance then
				data.Distance.Text = string.format("%dm", math.floor(dist3D))
				data.Distance.Position = Vector2.new(rootScreenPos.X, feetScreen.Y + SETTINGS.OFFSETS.DIST_Y_OFFSET)
				data.Distance.Color = espColor
				data.Distance.Visible = true
			elseif data.Distance then
				data.Distance.Visible = false
			end

			if espCfg.HeadDot and data.HeadDot then
				data.HeadDot.Position = headScreenPos
				data.HeadDot.Color = espColor
				data.HeadDot.Visible = true
			elseif data.HeadDot then
				data.HeadDot.Visible = false
			end

			if espCfg.LookDir and data.LookLine then
				local lookEndPos = headPos + (assets.Head.CFrame.LookVector * SETTINGS.OFFSETS.LOOK_VECTOR_LENGTH)
				local lookWorld = camera:WorldToViewportPoint(lookEndPos)
				data.LookLine.From = headScreenPos
				data.LookLine.To = Vector2.new(lookWorld.X, lookWorld.Y)
				data.LookLine.Color = espColor
				data.LookLine.Visible = true
			elseif data.LookLine then
				data.LookLine.Visible = false
			end

			if espCfg.Tracers and data.Tracer then
				data.Tracer.From = screenBottom
				data.Tracer.To = rootScreenPos
				data.Tracer.Color = espColor
				data.Tracer.Visible = true
			elseif data.Tracer then
				data.Tracer.Visible = false
			end

			if espCfg.Skeleton and data.Skeleton then
				local bones = getBones(assets.Character, assets.Humanoid)
				for index = 1, #data.Skeleton do
					local line = data.Skeleton[index]
					local bonePair = bones[index]
					if bonePair and bonePair[1] and bonePair[2] and bonePair[1].Parent and bonePair[2].Parent then
						local screen1, onScreen1 = camera:WorldToViewportPoint(bonePair[1].Position)
						local screen2, onScreen2 = camera:WorldToViewportPoint(bonePair[2].Position)
						if screen1.Z > 0 and screen2.Z > 0 and (onScreen1 or onScreen2) then
							line.From = Vector2.new(screen1.X, screen1.Y)
							line.To = Vector2.new(screen2.X, screen2.Y)
							line.Color = espColor
							line.Visible = true
						else
							line.Visible = false
						end
					else
						line.Visible = false
					end
				end
			elseif data.Skeleton then
				for index = 1, #data.Skeleton do
					data.Skeleton[index].Visible = false
				end
			end
		end
	end

	return ESPSystem
end
