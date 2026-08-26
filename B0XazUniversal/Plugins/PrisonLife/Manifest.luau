--[[
    B0XazUniversal . Plugins/PrisonLife/Manifest.luau
    Weapon spawns, map coordinates, door definitions
    ----------------------------------------
    Static data only -- no behavior. UniverseId 155615604 (Prison Life).
    Consumed by WorldPhase, WeaponMods and Mechanics.

    Status: SCAFFOLD
]]

local Manifest = {}

Manifest.UniverseId = 155615604
Manifest.Places = { 155615604 }

-- Weapon spawn points: { name, position, parentRegion }
Manifest.WeaponSpawns = {
    -- { name = "M9",        position = Vector3.new(0, 0, 0) },
}

-- Named map coordinates for teleport bookmarks
Manifest.Coordinates = {
    -- { name = "Cafeteria", position = Vector3.new(0, 0, 0) },
}

-- Door / gate definitions: { name, modelName, path }
Manifest.Doors = {
    -- { name = "Main Gate", model = "Gate" },
}

return Manifest
