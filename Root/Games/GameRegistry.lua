-- ════════════════════════════════════════════════════════════════════════════
-- Games/GameRegistry.lua
-- Static mapping registry of supported experiences with fast lookups
-- ════════════════════════════════════════════════════════════════════════════

local GameRegistry = {
	-- Place ID / Universe ID mappings to adapter configurations
	["155615604"] = {
		Name = "Prison Life v2.0",
		Folder = "PrisonLife",
		Description = "Bespoke modifications for Prison Life, including door phasing, weapon modifications, and taser resistance.",
	},
	-- Target patterns can be extended seamlessly
}

-- Fast lookup parsing compound string patterns
function GameRegistry.Resolve(placeId, universeId)
	local targetPlace = tostring(placeId)
	local targetUniverse = tostring(universeId)

	if GameRegistry[targetPlace] then return GameRegistry[targetPlace] end
	if GameRegistry[targetUniverse] then return GameRegistry[targetUniverse] end

	return nil
end

return GameRegistry
