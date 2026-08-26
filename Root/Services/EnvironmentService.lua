-- ════════════════════════════════════════════════════════════════════════════
-- Services/EnvironmentService.lua
-- World lighting management, Fullbright, and client rendering optimizers
-- ════════════════════════════════════════════════════════════════════════════

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local EnvironmentService = {}
EnvironmentService.__index = EnvironmentService

function EnvironmentService.new()
	local self = setmetatable({}, EnvironmentService)
	self._defaultLighting = {}
	self._defaultGravity = Workspace.Gravity
	self._textureCache = setmetatable({}, { __mode = "k" })
	self._materialCache = setmetatable({}, { __mode = "k" })
	self._shadowCache = setmetatable({}, { __mode = "k" })
	return self
end

function EnvironmentService:Init(container)
	self._config = container:Get("ConfigService")
	self._scheduler = container:Get("Scheduler")

	-- Snapshot Baseline Lighting
	self._defaultLighting = {
		Ambient = Lighting.Ambient,
		OutdoorAmbient = Lighting.OutdoorAmbient,
		Brightness = Lighting.Brightness,
		GlobalShadows = Lighting.GlobalShadows,
		ClockTime = Lighting.ClockTime,
	}

	-- Fullbright (edge-triggered): assert the values ONCE when the toggle
	-- turns on. Writing them every frame fights the game's own lighting
	-- scripts and makes the world strobe bright/dark after inject.
	local lastFullbright = false
	self._scheduler:AddTask("Physics", "Environment_Fullbright", function()
		local enabled = self._config:Get("Visuals.Fullbright") == true
		if enabled ~= lastFullbright then
			lastFullbright = enabled
			if enabled then
				Lighting.Ambient = Color3.new(1, 1, 1)
				Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
				Lighting.Brightness = 2
				Lighting.GlobalShadows = false
			end
		end
	end)
end

function EnvironmentService:SetNoTextures(enabled)
	self._config:Set("Performance.NoTextures", enabled)
	if enabled then
		for _, d in ipairs(Workspace:GetDescendants()) do
			if d:IsA("Decal") or d:IsA("Texture") then
				if self._textureCache[d] == nil then self._textureCache[d] = d.Texture end
				d.Texture = ""
			end
		end
	else
		for obj, tex in pairs(self._textureCache) do
			if obj and obj.Parent then pcall(function() obj.Texture = tex end) end
		end
		table.clear(self._textureCache)
	end
end

function EnvironmentService:SetLowMaterials(enabled)
	self._config:Set("Performance.LowMaterials", enabled)
	if enabled then
		for _, d in ipairs(Workspace:GetDescendants()) do
			if d:IsA("BasePart") and not d:IsA("Terrain") then
				if self._materialCache[d] == nil then self._materialCache[d] = d.Material end
				d.Material = Enum.Material.SmoothPlastic
			end
		end
	else
		for obj, mat in pairs(self._materialCache) do
			if obj and obj.Parent then pcall(function() obj.Material = mat end) end
		end
		table.clear(self._materialCache)
	end
end

function EnvironmentService:SetNoShadows(enabled)
	self._config:Set("Performance.NoShadows", enabled)
	Lighting.GlobalShadows = not enabled
	if enabled then
		for _, d in ipairs(Workspace:GetDescendants()) do
			if d:IsA("BasePart") then
				if self._shadowCache[d] == nil then self._shadowCache[d] = d.CastShadow end
				d.CastShadow = false
			end
		end
	else
		for obj, shadow in pairs(self._shadowCache) do
			if obj and obj.Parent then pcall(function() obj.CastShadow = shadow end) end
		end
		table.clear(self._shadowCache)
	end
end

function EnvironmentService:RestoreDefaults()
	for k, v in pairs(self._defaultLighting) do
		pcall(function() Lighting[k] = v end)
	end
	Workspace.Gravity = self._defaultGravity
	self:SetNoTextures(false)
	self:SetLowMaterials(false)
	self:SetNoShadows(false)
end

function EnvironmentService:Destroy()
	self:RestoreDefaults()
end

return EnvironmentService
