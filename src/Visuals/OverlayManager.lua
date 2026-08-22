-- // src/Visuals/OverlayManager.lua
return function(Context)
	local FeatureConfig = Context.FeatureConfig or {}
	local State = Context.State or {}
	local CONFIG = Context.CONFIG or {}
	local Utils = Context.Utils or {}
	local DrawingManager = Context.DrawingManager or {}

	local env = (getgenv and getgenv()) or _G
	local sessionId = env.B0XazSessionId or 0

	local function alive()
		return env.B0XazSessionId == sessionId
	end

	env.B0XazDrawings = env.B0XazDrawings or {}

	local function track(obj)
		if obj then table.insert(env.B0XazDrawings, obj) end
		return obj
	end

	local fovCircle = track(DrawingManager.NewCircle and DrawingManager.NewCircle({
		Radius = 100, Color = Color3.fromRGB(0, 200, 255), Thickness = 2, NumSides = 64,
	}))

	local fpsLabel = track(DrawingManager.NewText and DrawingManager.NewText({
		Size = 14, Color = Color3.new(1, 1, 1),
	}))
	if fpsLabel then
		fpsLabel.Center = false
		fpsLabel.Outline = true
		fpsLabel.Text = ""
	end

	local pingLabel = track(DrawingManager.NewText and DrawingManager.NewText({
		Size = 14, Color = Color3.new(1, 1, 1),
	}))
	if pingLabel then
		pingLabel.Center = false
		pingLabel.Outline = true
		pingLabel.Text = ""
	end

	local crosshairLines = {}
	if DrawingManager.Available and DrawingManager.NewLine then
		for _ = 1, 4 do
			local line = track(DrawingManager.NewLine({ Thickness = 2 }))
			if line then table.insert(crosshairLines, line) end
		end
	end

	local speedLines, speedData = {}, {}
	if DrawingManager.Available and DrawingManager.NewLine then
		local count = CONFIG.SPEED_LINES_COUNT or 30
		for i = 1, count do
			local line = track(DrawingManager.NewLine({
				Thickness = 1, Color = Color3.fromRGB(200, 230, 255),
			}))
			if line then
				line.Transparency = 0.5
				table.insert(speedLines, line)
				speedData[i] = {
					angle = math.random() * math.pi * 2,
					dist = math.random(150, 500),
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
		if not alive() or not fovCircle then return end
		local aim = FeatureConfig.Aimbot or {}
		local fov = aim.FOV or {}
		dt = dt or (1 / 60)

		if Utils.GetMousePosition then
			fovCircle.Position = Utils.GetMousePosition()
		end

		if fov.Rainbow then
			State.FOVHue = (State.FOVHue + dt * 0.5) % 1
			fovCircle.Color = Color3.fromHSV(State.FOVHue, 1, 1)
		else
			local esp = FeatureConfig.ESP or {}
			fovCircle.Color = esp.Color or Color3.fromRGB(0, 200, 255)
		end

		local base = fov.Size or 100
		if fov.Pulse then
			fovCircle.Radius = base + math.sin(State.FOVPulse) * 20
			State.FOVPulse = State.FOVPulse + dt * 3
		else
			fovCircle.Radius = base
		end

		fovCircle.Thickness = fov.Thickness or 2
		fovCircle.Filled = fov.Filled == true
		fovCircle.NumSides = fov.Sides or 64
		fovCircle.Visible = (fov.Show == true) and (aim.Enabled == true)
	end

	function OverlayManager.UpdateCrosshair()
		if not alive() then return end
		local cross = (FeatureConfig.Extras and FeatureConfig.Extras.Crosshair) or {}
		local show = cross.Visible == true and #crosshairLines >= 4

		if not show then
			for _, line in ipairs(crosshairLines) do line.Visible = false end
			return
		end

		local center = Utils.GetScreenCenter and Utils.GetScreenCenter() or Vector2.zero
		local cx, cy = center.X, center.Y
		local size = cross.Size or 10
		local gap = cross.Gap or 5
		local color = cross.Color or Color3.new(1, 1, 1)
		local thick = cross.Thickness or 2

		crosshairLines[1].From = Vector2.new(cx - size - gap, cy)
		crosshairLines[1].To   = Vector2.new(cx - gap, cy)
		crosshairLines[2].From = Vector2.new(cx + gap, cy)
		crosshairLines[2].To   = Vector2.new(cx + size + gap, cy)
		crosshairLines[3].From = Vector2.new(cx, cy - size - gap)
		crosshairLines[3].To   = Vector2.new(cx, cy - gap)
		crosshairLines[4].From = Vector2.new(cx, cy + gap)
		crosshairLines[4].To   = Vector2.new(cx, cy + size + gap)

		for _, line in ipairs(crosshairLines) do
			line.Color = color
			line.Thickness = thick
			line.Visible = true
		end
	end

	function OverlayManager.UpdateSpeedLines(dt)
		if not alive() then return end
		local extras = FeatureConfig.Extras or {}
		if not extras.SpeedLines or #speedLines == 0 then
			for _, line in ipairs(speedLines) do line.Visible = false end
			return
		end

		local center = Utils.GetScreenCenter and Utils.GetScreenCenter() or Vector2.zero
		dt = dt or (1 / 60)
		local speed = CONFIG.SPEED_LINES_SPEED or 600
		local maxRange = CONFIG.SPEED_LINES_MAX_RANGE or 700
		local length = CONFIG.SPEED_LINES_LENGTH or 60

		for i, line in ipairs(speedLines) do
			local data = speedData[i]
			if data then
				data.dist = data.dist + dt * speed
				if data.dist > maxRange then
					data.dist = math.random(50, 150)
					data.angle = math.random() * math.pi * 2
				end
				local c, s = math.cos(data.angle), math.sin(data.angle)
				local endDist = data.dist + length
				line.From = Vector2.new(center.X + c * data.dist, center.Y + s * data.dist)
				line.To = Vector2.new(center.X + c * endDist, center.Y + s * endDist)
				line.Transparency = math.clamp(1 - (data.dist / maxRange), 0.1, 1)
				line.Visible = true
			end
		end
	end

	return OverlayManager
end
