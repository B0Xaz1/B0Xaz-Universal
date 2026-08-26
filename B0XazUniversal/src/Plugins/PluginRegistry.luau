--!strict

export type PluginManifest = {
	Name: string,
	PluginModule: string,
	Description: string,
}

-- Place and Universe ids are both keys into the same map so either can
-- identify a supported game.
local REGISTRY_MAP: { [string]: PluginManifest } = {
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
