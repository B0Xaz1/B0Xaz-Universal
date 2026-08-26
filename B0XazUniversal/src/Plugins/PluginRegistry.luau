--!strict
-- ══════════════════════════════════════════════════════════════════════════════
-- B0XazUniversal - Polymorphic Game Plugin Registry
-- Provides O(1) indexed lookup tables mapping PlaceIds and UniverseIds to
-- structured game manifest definitions.
-- ══════════════════════════════════════════════════════════════════════════════

export type PluginManifest = {
	Name: string,
	PluginModule: string,
	Description: string,
}

local REGISTRY_MAP: { [string]: PluginManifest } = {
	-- Prison Life Main & Universe Place IDs
	["155615604"] = {
		Name = "Prison Life",
		PluginModule = "B0XazUniversal/src/Plugins/PrisonLife/Mechanics.luau",
		Description = "Door phasing, weapon attributes, macro, punch aura",
	},
	["135787580685512"] = {
		Name = "Prison Life",
		PluginModule = "B0XazUniversal/src/Plugins/PrisonLife/Mechanics.luau",
		Description = "Door phasing, weapon attributes, macro, punch aura",
	},
	["132339825894541"] = {
		Name = "Prison Life",
		PluginModule = "B0XazUniversal/src/Plugins/PrisonLife/Mechanics.luau",
		Description = "Door phasing, weapon attributes, macro, punch aura",
	},
}

local PluginRegistry = {}

function PluginRegistry.Resolve(placeId: number, universeId: number): PluginManifest?
	local byPlace = REGISTRY_MAP[tostring(placeId)]
	if byPlace then return byPlace end

	local byUniverse = REGISTRY_MAP[tostring(universeId)]
	if byUniverse then return byUniverse end

	return nil
end

return PluginRegistry
