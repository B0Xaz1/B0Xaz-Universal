-- ════════════════════════════════════════════════════════════════════════════
-- Games/Adapters/PrisonLife/Manifest.lua
-- Static configuration, POI CFrames, and item definitions for Prison Life
-- ════════════════════════════════════════════════════════════════════════════

local Manifest = {
	DEFAULTS = {
		DoorPhase = false,
		DoorGlow = true,
		PhaseTransparency = 0.65,
		GlowColor = Color3.fromRGB(0, 200, 220),
		NoSpread = false,
		FastFire = false,
		ForceAuto = false,
		ForceRange = false,
		FireRateValue = 0.001,
		RangeValue = 10000,
		FakeMacro = false,
		FakeMacroKey = Enum.KeyCode.V,
		FakeMacroDelay = 0.03,
		AntiRestrict = false,
		PunchAura = false,
		PunchAuraRange = 15,
		SuperPunch = false,
		SuperPunchHits = 10,
	},

	LOCATIONS = {
		{ Name = "Prison Cells", CFrame = CFrame.new(920, 98, 2436) },
		{ Name = "Cafeteria", CFrame = CFrame.new(920, 98, 2290) },
		{ Name = "Prison Yard", CFrame = CFrame.new(779, 98, 2463) },
		{ Name = "Criminal Base", CFrame = CFrame.new(-943, 95, 2058) },
		{ Name = "Police Armory", CFrame = CFrame.new(831, 98, 2284) },
		{ Name = "Parking Lot", CFrame = CFrame.new(745, 98, 2148) },
		{ Name = "Roof", CFrame = CFrame.new(845, 130, 2235) },
		{ Name = "Kitchen", CFrame = CFrame.new(906, 100, 2237) },
	},

	GUN_SPAWNS = {
		["M9"] = Vector3.new(816.65, 102.50, 2229.37),
		["Remington 870"] = Vector3.new(820.27, 102.50, 2229.31),
		["AK-47"] = Vector3.new(-932, 100.74, 2039.5),
		["MP5"] = Vector3.new(813.72, 102.50, 2229.37),
	},

	DOOR_FOLDERS = { "doors", "glass", "celldoors", "prison_fences", "prison_gate" },

	PRISON_GUNS = {
		["M9"] = true,
		["Remington 870"] = true,
		["AK-47"] = true,
		["M4A1"] = true,
		["M700"] = true,
		["Revolver"] = true,
		["MP5"] = true,
	},

	GUN_ATTRS = { "SpreadRadius", "FireRate", "AutoFire", "Range" },
	CRIM_POS = Vector3.new(-943, 95, 2058),
}

return Manifest
