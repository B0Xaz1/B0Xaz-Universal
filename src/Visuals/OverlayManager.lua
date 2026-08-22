local SETTINGS = {
	DEFAULTS = {
		FOV_RADIUS = 100,
		FOV_THICKNESS = 2,
		FOV_SIDES = 64,
		FOV_COLOR = Color3.fromRGB(0, 200, 255),
		TEXT_SIZE = 14,
		TEXT_COLOR = Color3.fromRGB(255, 255, 255),
		CROSSHAIR_THICKNESS = 2,
		CROSSHAIR_SIZE = 10,
		CROSSHAIR_GAP = 5,
		CROSSHAIR_COLOR = Color3.fromRGB(255, 255, 255),
		SPEED_LINES_COUNT = 30,
		SPEED_LINES_COLOR = Color3.fromRGB(200, 230, 255),
		SPEED_LINES_THICKNESS = 1,
		SPEED_LINES_MIN_DIST = 150,
		SPEED_LINES_MAX_DIST = 500,
		SPEED_LINES_SPEED = 600,
		SPEED_LINES_MAX_RANGE = 700,
		SPEED_LINES_SPAWN_MIN = 50,
		SPEED_LINES_SPAWN_MAX = 150,
		SPEED_LINES_LENGTH = 60,
		DEFAULT_DT = 0.016666666666667,
		RAINBOW_SPEED = 0.5,
		PULSE_SPEED = 3,
		PULSE_AMPLITUDE = 20,
	},
	LIMITS = {
		MIN_TRANSPARENCY = 0.1,
		MAX_TRANSPARENCY = 1.0,
		CROSSHAIR_LINES_COUNT = 4,
	},
}

return function(Context)
	local FeatureConfig = (Context and Context.FeatureConfig) or {}
	local State = (Context and Context.State) or {}
	local CONFIG = (Context and Context.CONFIG) or {}
	local Utils = (Context and Context.Utils) or {}
	local DrawingManager = (Context and Context.DrawingManager) or {}

	local SessionId = getgenv().B0XazSessionId or 0
	local function isSessionAlive()
		return getgenv().B0XazSessionId == SessionId
	end

	getgenv().B0XazDrawings = {}

	local fovCircle = DrawingManager.NewCircle and DrawingManager.NewCircle({
		Radius = SETTINGS.DEFAULTS.FOV_RADIUS,
		Color = SETTINGS.DEFAULTS.FOV_COLOR,
		Thickness = SETTINGS.DEFAULTS.FOV_THICKNESS,
		NumSides = SETTINGS.DEFAULTS.FOV_SIDES,
	})
	if fovCircle then
		table.insert(getgenv().B0XazDrawings, fovCircle)
	end

	local fpsLabel = DrawingManager.NewText and DrawingManager.NewText({
		Size = SETTINGS.DEFAULTS.TEXT_SIZE,
		Color = SETTINGS.DEFAULTS.TEXT_COLOR,
	})
	local pingLabel = DrawingManager.NewText and DrawingManager.NewText({
		Size = SETTINGS.DEFAULTS.TEXT_SIZE,
		Color = SETTINGS.DEFAULTS.TEXT_COLOR,
	})

	if fpsLabel then
		fpsLabel.Center = false
		fpsLabel.Outline = true
		fpsLabel.Text = ""
		table.insert(getgenv().B0XazDrawings, fpsLabel)
	end

	if pingLabel then
		pingLabel.Center = false
		pingLabel.Outline = true
		pingLabel.Text = ""
		table.insert(getgenv().B0XazDrawings, pingLabel)
	end

	local crosshairLines = {}
	if DrawingManager.Available and DrawingManager.NewLine then
		for _ = 1, SETTINGS.LIMITS.CROSSHAIR_LINES_COUNT do
			local line = DrawingManager.NewLine({ Thickness = SETTINGS.DEFAULTS.CROSSHAIR_THICKNESS })
			if line then
				table.insert(crosshairLines, line)
				table.insert(getgenv().B0XazDrawings, line)
			end
		end
	end

	local speedLines, speedLineData = {}, {}
	if DrawingManager.Available and DrawingManager.NewLine then
		local count = CONFIG.SPEED_LINES_COUNT or SETTINGS.DEFAULTS.SPEED_LINES_COUNT
		local minDist = CONFIG.SPEED_LINES_MIN_DIST or SETTINGS.DEFAULTS.SPEED_LINES_MIN_DIST
		local maxDist = CONFIG.SPEED_LINES_MAX_DIST or SETTINGS.DEFAULTS.SPEED_LINES_MAX_DIST

		for index = 1, count do
			local line = DrawingManager.NewLine({
				Thickness = SETTINGS.DEFAULTS.SPEED_LINES_THICKNESS,
				Color = SETTINGS.DEFAULTS.SPEED_LINES_COLOR,
			})
			if line then
				line.Transparency = 0.5
				table.insert(speedLines, line)
				table.insert(getgenv().B0XazDrawings, line)
				speedLineData[index] = {
					angle = math.random() * math.pi * 2,
					dist = math.random(minDist, maxDist),
				}
			end
		end
	end

	State.FOVHue = State.FOVHue or 0
	State.FOVPulse = State.FOVPulse or 0

	local OverlayManager = {
		FPSLabel = fpsLabel,
		PingLabel = pingLabel,
	}

	function OverlayManager.UpdateFOVCircle(dt)
		if not isSessionAlive() or not fovCircle then return end

		local aimConfig = FeatureConfig.Aimbot or {}
		local fovConfig = aimConfig.FOV or {}
		local deltaTime = dt or SETTINGS.DEFAULTS.DEFAULT_DT

		if Utils.GetMousePosition then
			fovCircle.Position = Utils.GetMousePosition()
		end

		if fovConfig.Rainbow then
			State.FOVHue = (State.FOVHue + deltaTime * SETTINGS.DEFAULTS.RAINBOW_SPEED) % 1
			fovCircle.Color = Color3.fromHSV(State.FOVHue, 1, 1)
		else
			local espConfig = FeatureConfig.ESP or {}
			fovCircle.Color = espConfig.Color or SETTINGS.DEFAULTS.FOV_COLOR
		end

		local baseRadius = fovConfig.Size or SETTINGS.DEFAULTS.FOV_RADIUS
		if fovConfig.Pulse then
			fovCircle.Radius = baseRadius + math.sin(State.FOVPulse) * SETTINGS.DEFAULTS.PULSE_AMPLITUDE
			State.FOVPulse = State.FOVPulse + deltaTime * SETTINGS.DEFAULTS.PULSE_SPEED
		else
			fovCircle.Radius = baseRadius
		end

		fovCircle.Thickness = fovConfig.Thickness or SETTINGS.DEFAULTS.FOV_THICKNESS
		fovCircle.Filled = fovConfig.Filled or false
		fovCircle.NumSides = fovConfig.Sides or SETTINGS.DEFAULTS.FOV_SIDES
		fovCircle.Visible = (fovConfig.Show == true) and (aimConfig.Enabled == true)
	end

	function OverlayManager.UpdateCrosshair()
		if not isSessionAlive() then return end

		local extras = FeatureConfig.Extras or {}
		local crosshairConfig = extras.Crosshair or {}
		local isVisible = crosshairConfig.Visible == true and #crosshairLines >= SETTINGS.LIMITS.CROSSHAIR_LINES_COUNT

		if not isVisible then
			for _, line in ipairs(crosshairLines) do
				line.Visible = false
			end
			return
		end

		local center = Utils.GetScreenCenter and Utils.GetScreenCenter() or Vector2.zero
		local cx, cy = center.X, center.Y
		local size = crosshairConfig.Size or SETTINGS.DEFAULTS.CROSSHAIR_SIZE
		local gap = crosshairConfig.Gap or SETTINGS.DEFAULTS.CROSSHAIR_GAP
		local color = crosshairConfig.Color or SETTINGS.DEFAULTS.CROSSHAIR_COLOR
		local thickness = crosshairConfig.Thickness or SETTINGS.DEFAULTS.CROSSHAIR_THICKNESS

		crosshairLines[1].From = Vector2.new(cx - size - gap, cy)
		crosshairLines[1].To = Vector2.new(cx - gap, cy)

		crosshairLines[2].From = Vector2.new(cx + gap, cy)
		crosshairLines[2].To = Vector2.new(cx + size + gap, cy)

		crosshairLines[3].From = Vector2.new(cx, cy - size - gap)
		crosshairLines[3].To = Vector2.new(cx, cy - gap)

		crosshairLines[4].From = Vector2.new(cx, cy + gap)
		crosshairLines[4].To = Vector2.new(cx, cy + size + gap)

		for _, line in ipairs(crosshairLines) do
			line.Color = color
			line.Thickness = thickness
			line.Visible = true
		end
	end

	function OverlayManager.UpdateSpeedLines(dt)
		if not isSessionAlive() then return end

		local extras = FeatureConfig.Extras or {}
		if not extras.SpeedLines or #speedLines == 0 then
			for _, line in ipairs(speedLines) do
				line.Visible = false
			end
			return
		end

		local center = Utils.GetScreenCenter and Utils.GetScreenCenter() or Vector2.zero
		local deltaTime = dt or SETTINGS.DEFAULTS.DEFAULT_DT
		local speed = CONFIG.SPEED_LINES_SPEED or SETTINGS.DEFAULTS.SPEED_LINES_SPEED
		local maxRange = CONFIG.SPEED_LINES_MAX_RANGE or SETTINGS.DEFAULTS.SPEED_LINES_MAX_RANGE
		local spawnMin = CONFIG.SPEED_LINES_SPAWN_MIN or SETTINGS.DEFAULTS.SPEED_LINES_SPAWN_MIN
		local spawnMax = CONFIG.SPEED_LINES_SPAWN_MAX or SETTINGS.DEFAULTS.SPEED_LINES_SPAWN_MAX
		local lineLength = CONFIG.SPEED_LINES_LENGTH or SETTINGS.DEFAULTS.SPEED_LINES_LENGTH

		for index, line in ipairs(speedLines) do
			local data = speedLineData[index]
			if data then
				data.dist = data.dist + deltaTime * speed
				if data.dist > maxRange then
					data.dist = math.random(spawnMin, spawnMax)
					data.angle = math.random() * math.pi * 2
				end

				local cosAngle = math.cos(data.angle)
				local sinAngle = math.sin(data.angle)
				local endDist = data.dist + lineLength

				line.From = Vector2.new(center.X + cosAngle * data.dist, center.Y + sinAngle * data.dist)
				line.To = Vector2.new(center.X + cosAngle * endDist, center.Y + sinAngle * endDist)
				line.Transparency = math.clamp(1 - (data.dist / maxRange), SETTINGS.LIMITS.MIN_TRANSPARENCY, SETTINGS.LIMITS.MAX_TRANSPARENCY)
				line.Visible = true
			end
		end
	end

	return OverlayManager
end
