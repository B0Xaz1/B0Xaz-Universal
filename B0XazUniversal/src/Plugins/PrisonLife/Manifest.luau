--!strict
-- ══════════════════════════════════════════════════════════════════════════════
-- B0XazUniversal - Prison Life Plugin Manifest & Data Tables
-- Pre-computed coordinate arrays, weapon spawns, door container tables,
-- and default state configurations.
-- ══════════════════════════════════════════════════════════════════════════════

local Manifest = {
	Name = "Prison Life",
	
	LOCATIONS = {
		{ Name = "Prison Cells", CFrame = CFrame.new(920, 98, 2436) },
		{ Name = "Cafeteria", CFrame = CFrame.new(920, 98, 2290) },
		{ Name = "Prison Yard", CFrame = CFrame.new(779, 98, 2463) },
		{ Name = "Criminal Base", CFrame = CFrame.new(-943, 95, 2058) },
		{ Name = "Police Armory", CFrame = CFrame.new(831, 98, 2284) },
		{ Name = "Parking Lot", CFrame = CFrame.new(745, 98, 2148) },
		{ Name = "Roof", CFrame = CFrame.new(845, 130, 2235) },
		{ Name = "Secret Room", CFrame = CFrame.new(674, 98, 2384) },
		{ Name = "Tunnels", CFrame = CFrame.new(918, 80, 2284) },
		{ Name = "Outside Prison", CFrame = CFrame.new(451.67, 98.04, 2216.34) },
		{ Name = "Kitchen", CFrame = CFrame.new(906.64, 99.99, 2237.67) },
		{ Name = "Break Room", CFrame = CFrame.new(800.09, 99.99, 2266.72) },
	},

	GUN_SPAWNS = {
		["M9"] = Vector3.new(816.65, 102.50, 2229.37),
		["Remington 870"] = Vector3.new(820.27, 102.50, 2229.31),
		["AK-47"] = Vector3.new(-932, 100.74, 2039.5),
		["MP5"] = Vector3.new(813.72, 102.50, 2229.37),
	},

	DOOR_FOLDERS = {
		["doors"] = true,
		["glass"] = true,
		["celldoors"] = true,
		["prison_fences"] = true,
		["prison_gate"] = true,
	},

	PRISON_GUNS = {
		["M9"] = true,
		["Remington 870"] = true,
		["AK-47"] = true,
		["M4A1"] = true,
		["M700"] = true,
		["Revolver"] = true,
		["MP5"] = true,
	},

	CRIMINAL_SPAWN = Vector3.new(-943, 95, 2058),
}

table.freeze(Manifest.LOCATIONS)
table.freeze(Manifest.GUN_SPAWNS)
table.freeze(Manifest.DOOR_FOLDERS)
table.freeze(Manifest.PRISON_GUNS)

return Manifest
