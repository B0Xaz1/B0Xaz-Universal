-- ════════════════════════════════════════════════════════════════════════════
-- Games/Adapters/PrisonLife/WeaponModder.lua
-- Injects weapon attributes (NoSpread, FastFire) and executes tool macros
-- ════════════════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local Manifest = require(script.Parent.Manifest)

local WeaponModder = {}
WeaponModder.__index = WeaponModder

function WeaponModder.new(configService)
	local self = setmetatable({}, WeaponModder)
	self._config = configService
	self._gunCache = setmetatable({}, { __mode = "k" })
	self._macroThread = nil
	self._toolIndex = 1
	self._localPlayer = Players.LocalPlayer
	return self
end

function WeaponModder:ApplyGun(tool)
	if not (tool and tool:IsA("Tool") and Manifest.PRISON_GUNS[tool.Name]) then return end

	local function modify(obj)
		if not self._gunCache[obj] then
			local snapshot = {}
			for _, attr in ipairs(Manifest.GUN_ATTRS) do
				snapshot[attr] = obj:GetAttribute(attr)
			end
			self._gunCache[obj] = snapshot
		end

		if self._config:Get("Game.NoSpread") then obj:SetAttribute("SpreadRadius", 0) end
		if self._config:Get("Game.FastFire") then obj:SetAttribute("FireRate", 0.001) end
		if self._config:Get("Game.ForceAuto") then obj:SetAttribute("AutoFire", true) end
		if self._config:Get("Game.ForceRange") then obj:SetAttribute("Range", 10000) end
	end

	modify(tool)
	for _, d in ipairs(tool:GetDescendants()) do
		modify(d)
	end
end

function WeaponModder:ScanGuns()
	local containers = {
		self._localPlayer:FindFirstChildOfClass("Backpack"),
		self._localPlayer.Character,
	}
	for _, container in ipairs(containers) do
		if container then
			for _, item in ipairs(container:GetChildren()) do
				if item:IsA("Tool") then self:ApplyGun(item) end
			end
		end
	end
end

function WeaponModder:StartMacro()
	self:StopMacro()
	self._macroThread = task.spawn(function()
		while true do
			local char = self._localPlayer.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local bp = self._localPlayer:FindFirstChildOfClass("Backpack")

			if hum and bp and hum.Health > 0 then
				local tools = {}
				for _, t in ipairs(bp:GetChildren()) do
					if t:IsA("Tool") and Manifest.PRISON_GUNS[t.Name] then table.insert(tools, t) end
				end
				for _, t in ipairs(char:GetChildren()) do
					if t:IsA("Tool") and Manifest.PRISON_GUNS[t.Name] then table.insert(tools, t) end
				end

				if #tools >= 2 then
					self._toolIndex = (self._toolIndex % #tools) + 1
					local nextTool = tools[self._toolIndex]
					if nextTool and nextTool.Parent ~= char then
						hum:EquipTool(nextTool)
					end
				end
			end
			task.wait(self._config:Get("Game.FakeMacroDelay") or 0.03)
		end
	end)
end

function WeaponModder:StopMacro()
	if self._macroThread then
		pcall(task.cancel, self._macroThread)
		self._macroThread = nil
	end
end

function WeaponModder:Restore()
	self:StopMacro()
	for obj, snapshot in pairs(self._gunCache) do
		if obj and obj.Parent then
			for attr, val in pairs(snapshot) do
				pcall(function() obj:SetAttribute(attr, val) end)
			end
		end
	end
	table.clear(self._gunCache)
end

function WeaponModder:Destroy()
	self:Restore()
end

return WeaponModder
