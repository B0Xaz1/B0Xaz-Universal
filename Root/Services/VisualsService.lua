-- ════════════════════════════════════════════════════════════════════════════
-- Services/VisualsService.lua
-- Object-pooled 2D Drawing overlays and 3D Adornee Chams engine
-- ════════════════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local VisualsService = {}
VisualsService.__index = VisualsService

local FONT_MAP = { UI = 0, System = 1, Plex = 2, Monospace = 3 }

function VisualsService.new()
	local self = setmetatable({}, VisualsService)
	self._drawings = {}
	self._highlights = {}
	return self
end

function VisualsService:Init(container)
	self._config = container:Get("ConfigService")
	self._entity = container:Get("EntityService")
	self._spatial = container:Get("SpatialUtil")
	self._scheduler = container:Get("Scheduler")
	self._localPlayer = Players.LocalPlayer

	-- Register 30 FPS Render Task for ESP
	self._scheduler:AddTask("Render", "Visuals_ESPUpdate", function()
		self:_updateVisuals()
	end, 30)

	Players.PlayerRemoving:Connect(function(p)
		self:_removePlayerVisuals(p)
	end)
end

function VisualsService:_createDrawing(className, props)
	if not (Drawing and Drawing.new) then return nil end
	local ok, inst = pcall(Drawing.new, className)
	if not ok or not inst then return nil end
	inst.Visible = false
	if props then
		for k, v in pairs(props) do
			pcall(function() inst[k] = v end)
		end
	end
	return inst
end

function VisualsService:_getOrCreateVisuals(player)
	if self._drawings[player] then return self._drawings[player] end

	local color = self._config:Get("ESP.Color") or Color3.fromRGB(0, 200, 255)
	local skeleton = {}
	for _ = 1, 6 do
		table.insert(skeleton, self:_createDrawing("Line", { Thickness = 1, Color = color }))
	end

	local package = {
		Box = self:_createDrawing("Square", { Thickness = 2, Color = color }),
		Name = self:_createDrawing("Text", { Size = 13, Center = true, Outline = true, Color = color }),
		Health = self:_createDrawing("Square", { Filled = true }),
		HealthBG = self:_createDrawing("Square", { Filled = true, Color = Color3.new(0, 0, 0), Transparency = 0.5 }),
		Distance = self:_createDrawing("Text", { Size = 11, Center = true, Outline = true, Color = color }),
		Tool = self:_createDrawing("Text", { Size = 11, Center = true, Outline = true, Color = Color3.fromRGB(255, 220, 100) }),
		Tracer = self:_createDrawing("Line", { Thickness = 1.5, Color = color }),
		Skeleton = skeleton,
	}

	self._drawings[player] = package
	return package
end

function VisualsService:_hideVisuals(data)
	if not data then return end
	if data.Box then data.Box.Visible = false end
	if data.Name then data.Name.Visible = false end
	if data.Health then data.Health.Visible = false end
	if data.HealthBG then data.HealthBG.Visible = false end
	if data.Distance then data.Distance.Visible = false end
	if data.Tool then data.Tool.Visible = false end
	if data.Tracer then data.Tracer.Visible = false end
	if data.Skeleton then
		for _, line in ipairs(data.Skeleton) do line.Visible = false end
	end
end

function VisualsService:_removePlayerVisuals(player)
	local data = self._drawings[player]
	if data then
		for _, obj in pairs(data) do
			if type(obj) == "table" then
				for _, sub in ipairs(obj) do pcall(sub.Remove, sub) end
			else
				pcall(obj.Remove, obj)
			end
		end
		self._drawings[player] = nil
	end

	local hl = self._highlights[player]
	if hl then
		pcall(hl.Destroy, hl)
		self._highlights[player] = nil
	end
end

function VisualsService:_updateVisuals()
	local espEnabled = self._config:Get("ESP.Enabled")
	local chamsEnabled = self._config:Get("Chams.Enabled")

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= self._localPlayer then
			local assets = self._entity:GetAssets(player)
			local data = self:_getOrCreateVisuals(player)

			if not assets or (not espEnabled and not chamsEnabled) then
				self:_hideVisuals(data)
				if self._highlights[player] then
					pcall(self._highlights[player].Destroy, self._highlights[player])
					self._highlights[player] = nil
				end
			else
				-- Chams Management
				if chamsEnabled and assets.Character then
					if not self._highlights[player] or self._highlights[player].Parent ~= assets.Character then
						if self._highlights[player] then pcall(self._highlights[player].Destroy, self._highlights[player]) end
						local hl = Instance.new("Highlight")
						hl.Name = "B0XazChams"
						hl.Adornee = assets.Character
						hl.FillColor = self._config:Get("Chams.FillColor") or Color3.fromRGB(0, 170, 255)
						hl.OutlineColor = self._config:Get("Chams.OutlineColor") or Color3.fromRGB(255, 255, 255)
						hl.FillTransparency = 0.5
						hl.DepthMode = self._config:Get("Chams.DepthMode") == "Occluded" and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop
						hl.Parent = assets.Character
						self._highlights[player] = hl
					end
				elseif self._highlights[player] then
					pcall(self._highlights[player].Destroy, self._highlights[player])
					self._highlights[player] = nil
				end

				-- 2D Vector ESP Rendering
				if espEnabled and assets.RootPart and assets.Head then
					local rootPos = assets.RootPart.Position
					local rootScreen, onScreen = self._spatial.WorldToViewport(rootPos)

					if onScreen then
						local headScreen = self._spatial.WorldToViewport(assets.Head.Position + Vector3.new(0, 0.5, 0))
						local feetScreen = self._spatial.WorldToViewport(rootPos - Vector3.new(0, 3, 0))
						
						local height = math.abs(headScreen.Y - feetScreen.Y)
						local width = height * 0.55
						local halfW, halfH = width * 0.5, height * 0.5
						local espColor = self._config:Get("ESP.Color") or Color3.fromRGB(0, 200, 255)

						-- Box
						if self._config:Get("ESP.Box") and data.Box then
							data.Box.Size = Vector2.new(width, height)
							data.Box.Position = Vector2.new(rootScreen.X - halfW, rootScreen.Y - halfH)
							data.Box.Color = espColor
							data.Box.Visible = true
						else
							data.Box.Visible = false
						end

						-- Name Label
						if self._config:Get("ESP.Name") and data.Name then
							data.Name.Text = player.DisplayName or player.Name
							data.Name.Position = Vector2.new(rootScreen.X, headScreen.Y - 18)
							data.Name.Color = espColor
							data.Name.Visible = true
						else
							data.Name.Visible = false
						end

						-- Health Bar
						if self._config:Get("ESP.Health") and data.Health and data.HealthBG then
							local ratio = math.clamp(assets.Humanoid.Health / math.max(assets.Humanoid.MaxHealth, 1), 0, 1)
							local bx = rootScreen.X - halfW - 6
							local by = rootScreen.Y - halfH
							data.HealthBG.Size = Vector2.new(3, height)
							data.HealthBG.Position = Vector2.new(bx, by)
							data.HealthBG.Visible = true

							data.Health.Size = Vector2.new(3, height * ratio)
							data.Health.Position = Vector2.new(bx, by + height * (1 - ratio))
							data.Health.Color = Color3.fromHSV(ratio * 0.33, 1, 1)
							data.Health.Visible = true
						else
							data.Health.Visible = false
							data.HealthBG.Visible = false
						end

						-- Distance Label
						if self._config:Get("ESP.Distance") and data.Distance then
							local myPos = self._localPlayer.Character and self._localPlayer.Character:FindFirstChild("HumanoidRootPart")
							local dist = myPos and (myPos.Position - rootPos).Magnitude or 0
							data.Distance.Text = string.format("%dm", math.floor(dist))
							data.Distance.Position = Vector2.new(rootScreen.X, feetScreen.Y + 2)
							data.Distance.Color = espColor
							data.Distance.Visible = true
						else
							data.Distance.Visible = false
						end

						-- Snap Tracers
						if self._config:Get("ESP.Tracers") and data.Tracer then
							data.Tracer.From = self._spatial.GetScreenBottomCenter()
							data.Tracer.To = Vector2.new(rootScreen.X, rootScreen.Y)
							data.Tracer.Color = espColor
							data.Tracer.Visible = true
						else
							data.Tracer.Visible = false
						end
					else
						self:_hideVisuals(data)
					end
				else
					self:_hideVisuals(data)
				end
			end
		end
	end
end

function VisualsService:Destroy()
	for p in pairs(self._drawings) do
		self:_removePlayerVisuals(p)
	end
end

return VisualsService
