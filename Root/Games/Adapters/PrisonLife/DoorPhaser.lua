-- ════════════════════════════════════════════════════════════════════════════
-- Games/Adapters/PrisonLife/DoorPhaser.lua
-- Obstacle collision phasing and visual glow manager for Prison Life
-- ════════════════════════════════════════════════════════════════════════════

local Workspace = game:GetService("Workspace")
local Manifest = require(script.Parent.Manifest)

local DoorPhaser = {}
DoorPhaser.__index = DoorPhaser

local NEON = Enum.Material.Neon

function DoorPhaser.new(configService)
	local self = setmetatable({}, DoorPhaser)
	self._config = configService
	self._doorCache = setmetatable({}, { __mode = "k" })
	self._doorParts = {}
	self._connections = {}
	return self
end

function DoorPhaser:IsDoorPart(part)
	if not (part and part:IsA("BasePart")) then return false end
	local cur = part.Parent
	while cur and cur ~= Workspace do
		for _, folder in ipairs(Manifest.DOOR_FOLDERS) do
			if cur.Name:lower() == folder then return true end
		end
		cur = cur.Parent
	end
	return false
end

function DoorPhaser:ApplyStyle(part)
	local original = self._doorCache[part]
	if not original or not part.Parent then return end

	local transparency = self._config:Get("Game.PhaseTransparency") or 0.65
	local glow = self._config:Get("Game.DoorGlow")
	local glowColor = self._config:Get("Game.GlowColor") or Color3.fromRGB(0, 200, 220)

	pcall(function()
		part.CanCollide = false
		part.Transparency = transparency
		if glow then
			part.Material = NEON
			part.Color = glowColor
		else
			part.Material = original.Material
			part.Color = original.Color
		end
	end)
end

function DoorPhaser:ProcessPart(part)
	if not self:IsDoorPart(part) then return end
	if not self._doorCache[part] then
		self._doorCache[part] = {
			CanCollide = part.CanCollide,
			Transparency = part.Transparency,
			Color = part.Color,
			Material = part.Material,
		}
	end
	self._doorParts[part] = true
	self:ApplyStyle(part)
end

function DoorPhaser:Scan()
	for _, child in ipairs(Workspace:GetChildren()) do
		for _, folder in ipairs(Manifest.DOOR_FOLDERS) do
			if child.Name:lower() == folder then
				for _, d in ipairs(child:GetDescendants()) do
					if d:IsA("BasePart") then self:ProcessPart(d) end
				end
			end
		end
	end
end

function DoorPhaser:UpdateAll()
	for part in pairs(self._doorParts) do
		if part and part.Parent then
			self:ApplyStyle(part)
		else
			self._doorParts[part] = nil
			self._doorCache[part] = nil
		end
	end
end

function DoorPhaser:RestoreAll()
	for part, orig in pairs(self._doorCache) do
		if part and part.Parent then
			pcall(function()
				part.CanCollide = orig.CanCollide
				part.Transparency = orig.Transparency
				part.Color = orig.Color
				part.Material = orig.Material
			end)
		end
	end
	table.clear(self._doorCache)
	table.clear(self._doorParts)
end

function DoorPhaser:Destroy()
	self:RestoreAll()
end

return DoorPhaser
