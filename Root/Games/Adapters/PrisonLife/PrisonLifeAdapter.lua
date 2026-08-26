-- ════════════════════════════════════════════════════════════════════════════
-- Games/Adapters/PrisonLife/PrisonLifeAdapter.lua
-- Master adapter lifecycle and Game Tab UI builder for Prison Life
-- ════════════════════════════════════════════════════════════════════════════

local Manifest = require(script.Parent.Manifest)
local DoorPhaser = require(script.Parent.DoorPhaser)
local WeaponModder = require(script.Parent.WeaponModder)
local MeleeController = require(script.Parent.MeleeController)

local Toggle = require(script.Parent.Parent.Parent.UI.Components.Toggle)
local Slider = require(script.Parent.Parent.Parent.UI.Components.Slider)
local Button = require(script.Parent.Parent.Parent.UI.Components.Button)

local PrisonLifeAdapter = {}
PrisonLifeAdapter.__index = PrisonLifeAdapter

function PrisonLifeAdapter.new()
	return setmetatable({}, PrisonLifeAdapter)
end

function PrisonLifeAdapter:Init(container)
	self._config = container:Get("ConfigService")
	self._entity = container:Get("EntityService")
	self._scheduler = container:Get("Scheduler")
	self._input = container:Get("InputService")

	-- Merge Game Defaults
	for k, v in pairs(Manifest.DEFAULTS) do
		if self._config:Get("Game." .. k) == nil then
			self._config:Set("Game." .. k, v, true)
		end
	end

	-- Subsystems
	self.Doors = DoorPhaser.new(self._config)
	self.Weapons = WeaponModder.new(self._config)
	self.Melee = MeleeController.new(self._config, self._entity)

	-- Heartbeat physics loops
	self._scheduler:AddTask("Physics", "PrisonLife_Loop", function()
		self.Melee:RunPunchAura()
		self.Melee:EnforceAntiRestrict()
	end)
end

function PrisonLifeAdapter:BuildUI(tab)
	local page = tab.Page
	local theme = tab._theme

	-- Gun Grabber Spawns
	for name, pos in pairs(Manifest.GUN_SPAWNS) do
		Button.new(page, "Grab Gun: " .. name, function()
			local char = game:GetService("Players").LocalPlayer.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if root then
				local orig = root.CFrame
				root.CFrame = CFrame.new(pos)
				task.wait(1.2)
				if root and root.Parent then root.CFrame = orig end
			end
		end, theme)
	end

	-- Door Phasing
	Toggle.new(page, "Phase Doors & Gates", self._config:Get("Game.DoorPhase"), function(v)
		self._config:Set("Game.DoorPhase", v)
		if v then self.Doors:Scan() else self.Doors:RestoreAll() end
	end, theme)

	-- Combat Modifiers
	Toggle.new(page, "No Spread", self._config:Get("Game.NoSpread"), function(v)
		self._config:Set("Game.NoSpread", v)
		self.Weapons:ScanGuns()
	end, theme)

	Toggle.new(page, "Fast Fire Rate", self._config:Get("Game.FastFire"), function(v)
		self._config:Set("Game.FastFire", v)
		self.Weapons:ScanGuns()
	end, theme)

	Toggle.new(page, "Force Full-Auto", self._config:Get("Game.ForceAuto"), function(v)
		self._config:Set("Game.ForceAuto", v)
		self.Weapons:ScanGuns()
	end, theme)

	-- Melee
	Toggle.new(page, "Punch Aura", self._config:Get("Game.PunchAura"), function(v)
		self._config:Set("Game.PunchAura", v)
	end, theme)

	Toggle.new(page, "Super Punch (Multi-Hit)", self._config:Get("Game.SuperPunch"), function(v)
		self._config:Set("Game.SuperPunch", v)
	end, theme)

	Toggle.new(page, "Anti-Taser / Anti-Restrict", self._config:Get("Game.AntiRestrict"), function(v)
		self._config:Set("Game.AntiRestrict", v)
	end, theme)
end

function PrisonLifeAdapter:Destroy()
	if self.Doors then self.Doors:Destroy() end
	if self.Weapons then self.Weapons:Destroy() end
end

return PrisonLifeAdapter
