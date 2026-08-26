-- ════════════════════════════════════════════════════════════════════════════
-- Services/OverlayService.lua
-- FOV reticle visualizer, Speed Lines FX, and on-screen metrics HUD
-- ════════════════════════════════════════════════════════════════════════════

local StatsService = game:GetService("Stats")

local OverlayService = {}
OverlayService.__index = OverlayService

function OverlayService.new()
	local self = setmetatable({}, OverlayService)
	self._fovCircle = nil
	self._fpsLabel = nil
	self._pingLabel = nil
	self._speedLines = {}
	self._speedData = {}
	self._fpsCount = 0
	self._fpsTimer = 0
	self._currentFps = 0
	self._fovHue = 0
	return self
end

function OverlayService:Init(container)
	self._config = container:Get("ConfigService")
	self._input = container:Get("InputService")
	self._spatial = container:Get("SpatialUtil")
	self._scheduler = container:Get("Scheduler")

	if not (Drawing and Drawing.new) then return end

	-- FOV Circle
	self._fovCircle = Drawing.new("Circle")
	self._fovCircle.Thickness = 2
	self._fovCircle.NumSides = 64
	self._fovCircle.Filled = false
	self._fovCircle.Visible = false

	-- Performance Labels
	self._fpsLabel = Drawing.new("Text")
	self._fpsLabel.Size = 14
	self._fpsLabel.Position = Vector2.new(10, 10)
	self._fpsLabel.Color = Color3.new(1, 1, 1)
	self._fpsLabel.Outline = true
	self._fpsLabel.Visible = false

	self._pingLabel = Drawing.new("Text")
	self._pingLabel.Size = 14
	self._pingLabel.Position = Vector2.new(10, 28)
	self._pingLabel.Color = Color3.new(1, 1, 1)
	self._pingLabel.Outline = true
	self._pingLabel.Visible = false

	-- Initialize Speed Lines
	for i = 1, 25 do
		local line = Drawing.new("Line")
		line.Thickness = 1
		line.Color = Color3.fromRGB(200, 230, 255)
		line.Visible = false
		table.insert(self._speedLines, line)
		self._speedData[i] = { angle = math.random() * math.pi * 2, dist = math.random(100, 400) }
	end

	self._scheduler:AddTask("Render", "Overlay_Update", function(dt)
		self:_update(dt)
	end)
end

function OverlayService:_update(dt)
	-- Update FOV Reticle
	local aimEnabled = self._config:Get("Aimbot.Enabled")
	local showFov = self._config:Get("Aimbot.FOV.Show")
	
	if aimEnabled and showFov and self._fovCircle then
		local mouse = self._input:GetMouseViewportPosition()
		self._fovCircle.Position = mouse
		self._fovCircle.Radius = self._config:Get("Aimbot.FOV.Size") or 150
		self._fovCircle.Thickness = self._config:Get("Aimbot.FOV.Thickness") or 2
		self._fovCircle.Filled = self._config:Get("Aimbot.FOV.Filled") == true

		if self._config:Get("Aimbot.FOV.Rainbow") then
			self._fovHue = (self._fovHue + dt * 0.5) % 1
			self._fovCircle.Color = Color3.fromHSV(self._fovHue, 1, 1)
		else
			self._fovCircle.Color = self._config:Get("ESP.Color") or Color3.fromRGB(0, 200, 255)
		end
		self._fovCircle.Visible = true
	elseif self._fovCircle then
		self._fovCircle.Visible = false
	end

	-- Update FPS & Ping Labels
	self._fpsCount = self._fpsCount + 1
	self._fpsTimer = self._fpsTimer + dt
	if self._fpsTimer >= 1.0 then
		self._currentFps = self._fpsCount
		self._fpsCount = 0
		self._fpsTimer = 0
	end

	if self._fpsLabel then
		local showFPS = self._config:Get("Settings.ShowFPS")
		self._fpsLabel.Visible = showFPS
		if showFPS then self._fpsLabel.Text = string.format("FPS: %d", self._currentFps) end
	end

	if self._pingLabel then
		local showPing = self._config:Get("Settings.ShowPing")
		self._pingLabel.Visible = showPing
		if showPing then
			local ping = 0
			pcall(function() ping = math.floor(StatsService.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
			self._pingLabel.Text = string.format("Ping: %dms", ping)
		end
	end

	-- Update Speed Lines
	local showSpeed = self._config:Get("Extras.SpeedLines")
	local center = self._spatial.GetScreenBottomCenter()
	center = Vector2.new(center.X, center.Y * 0.5)

	for i, line in ipairs(self._speedLines) do
		if showSpeed then
			local data = self._speedData[i]
			data.dist = data.dist + dt * 600
			if data.dist > 600 then
				data.dist = math.random(50, 150)
				data.angle = math.random() * math.pi * 2
			end
			local c, s = math.cos(data.angle), math.sin(data.angle)
			line.From = Vector2.new(center.X + c * data.dist, center.Y + s * data.dist)
			line.To = Vector2.new(center.X + c * (data.dist + 50), center.Y + s * (data.dist + 50))
			line.Visible = true
		else
			line.Visible = false
		end
	end
end

function OverlayService:Destroy()
	if self._fovCircle then pcall(self._fovCircle.Remove, self._fovCircle) end
	if self._fpsLabel then pcall(self._fpsLabel.Remove, self._fpsLabel) end
	if self._pingLabel then pcall(self._pingLabel.Remove, self._pingLabel) end
	for _, line in ipairs(self._speedLines) do pcall(line.Remove, line) end
	table.clear(self._speedLines)
	table.clear(self._speedData)
end

return OverlayService
