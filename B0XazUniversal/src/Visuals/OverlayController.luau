--!strict

local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local StatsService = game:GetService("Stats")

type SpeedLine = {
	Primitive: any,
	Direction: Vector2,
	Distance: number,
}

return function(services: any)
	local StateStore = services:Get("StateStore")
	local TaskScheduler = services:Get("TaskScheduler")
	local DrawingPool = services:Get("DrawingPool")

	local OverlayController = {
		_fovCircle = nil :: any,
		_fpsLabel = nil :: any,
		_pingLabel = nil :: any,
		_speedLines = {} :: { SpeedLine },
		_lastFps = 0,
		_lastPing = 0,
		_fpsTimer = 0,
		_pingTimer = 0,
		_fpsCount = 0,
		_fovPulseAngle = 0,
	}

	local function isMobile(): boolean
		return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	end

	-- Lines are pre-allocated with random directions; each frame they move
	-- outward and respawn inward, so the effect has a constant memory cost.
	local function initSpeedLines()
		if not DrawingPool.Available then return end
		local LINE_COUNT = 30
		for _ = 1, LINE_COUNT do
			local primitive = DrawingPool:Acquire("Line")
			if primitive then
				primitive.Thickness = 1
				primitive.Color = Color3.fromRGB(200, 230, 255)
				primitive.Transparency = 0.5
				local angle = math.random() * math.pi * 2
				table.insert(OverlayController._speedLines, {
					Primitive = primitive,
					Direction = Vector2.new(math.cos(angle), math.sin(angle)),
					Distance = math.random(100, 400),
				})
			end
		end
	end

	local function onRenderUpdate(dt: number)
		local cam = Workspace.CurrentCamera
		if not cam then return end

		local aimbotSettings = StateStore:Get("Aimbot")
		local fovSettings = aimbotSettings and aimbotSettings.FOV
		local isAimbotActive = aimbotSettings and aimbotSettings.Enabled and StateStore:HasPermission("Aimbot.Enabled")

		if OverlayController._fovCircle then
			if isAimbotActive and fovSettings and fovSettings.Show then
				local mousePos = isMobile()
					and Vector2.new(cam.ViewportSize.X * 0.5, cam.ViewportSize.Y * 0.5)
					or UserInputService:GetMouseLocation()

				local radius = tonumber(fovSettings.Size) or 150
				if fovSettings.Pulse then
					OverlayController._fovPulseAngle += dt * 3
					radius += math.sin(OverlayController._fovPulseAngle) * 20
				end

				local circleColor = fovSettings.Rainbow
					and Color3.fromHSV((os.clock() * 0.2) % 1, 1, 1)
					or (StateStore:Get("ESP.Color") or Color3.fromRGB(0, 200, 255))

				OverlayController._fovCircle.Position = mousePos
				OverlayController._fovCircle.Radius = math.clamp(radius, 5, 1000)
				OverlayController._fovCircle.Color = circleColor
				OverlayController._fovCircle.Thickness = math.clamp(tonumber(fovSettings.Thickness) or 1, 1, 10)
				OverlayController._fovCircle.Filled = fovSettings.Filled == true
				OverlayController._fovCircle.NumSides = math.clamp(tonumber(fovSettings.Sides) or 64, 16, 128)
				OverlayController._fovCircle.Visible = true
			else
				OverlayController._fovCircle.Visible = false
			end
		end

		local drawSpeedLines = StateStore:Get("Extras.SpeedLines") == true
		local center = Vector2.new(cam.ViewportSize.X * 0.5, cam.ViewportSize.Y * 0.5)

		for _, line in ipairs(OverlayController._speedLines) do
			if drawSpeedLines then
				line.Distance += dt * 600
				if line.Distance > 700 then
					line.Distance = math.random(50, 150)
					local newAngle = math.random() * math.pi * 2
					line.Direction = Vector2.new(math.cos(newAngle), math.sin(newAngle))
				end

				local startPos = center + (line.Direction * line.Distance)
				local endPos = center + (line.Direction * (line.Distance + 60))

				line.Primitive.From = startPos
				line.Primitive.To = endPos
				line.Primitive.Transparency = math.clamp(1 - (line.Distance / 700), 0.1, 0.8)
				line.Primitive.Visible = true
			else
				line.Primitive.Visible = false
			end
		end

		-- Telemetry is sampled once per second instead of every frame
		OverlayController._fpsCount += 1
		OverlayController._fpsTimer += dt
		if OverlayController._fpsTimer >= 1.0 then
			OverlayController._lastFps = OverlayController._fpsCount
			OverlayController._fpsCount = 0
			OverlayController._fpsTimer = 0

			if OverlayController._fpsLabel and StateStore:Get("Settings.ShowFPS") then
				OverlayController._fpsLabel.Text = string.format("FPS: %d", OverlayController._lastFps)
				OverlayController._fpsLabel.Visible = true
			elseif OverlayController._fpsLabel then
				OverlayController._fpsLabel.Visible = false
			end
		end

		OverlayController._pingTimer += dt
		if OverlayController._pingTimer >= 1.0 then
			OverlayController._pingTimer = 0
			-- The stats item is missing on some servers, so the read is pcalled
			pcall(function()
				OverlayController._lastPing = math.floor(StatsService.Network.ServerStatsItem["Data Ping"]:GetValue())
			end)

			if OverlayController._pingLabel and StateStore:Get("Settings.ShowPing") then
				OverlayController._pingLabel.Text = string.format("Ping: %dms", OverlayController._lastPing)
				OverlayController._pingLabel.Visible = true
			elseif OverlayController._pingLabel then
				OverlayController._pingLabel.Visible = false
			end
		end
	end

	function OverlayController:Initialize()
		if DrawingPool.Available then
			self._fovCircle = DrawingPool:Acquire("Circle")
			self._fpsLabel = DrawingPool:Acquire("Text")
			if self._fpsLabel then
				self._fpsLabel.Position = Vector2.new(10, 10)
				self._fpsLabel.Size = 14
				self._fpsLabel.Outline = true
				self._fpsLabel.Color = Color3.new(1, 1, 1)
			end

			self._pingLabel = DrawingPool:Acquire("Text")
			if self._pingLabel then
				self._pingLabel.Position = Vector2.new(10, 26)
				self._pingLabel.Size = 14
				self._pingLabel.Outline = true
				self._pingLabel.Color = Color3.new(1, 1, 1)
			end

			initSpeedLines()
		end

		TaskScheduler:RegisterRender("OverlayUpdate", 15, onRenderUpdate)
	end

	return OverlayController
end
