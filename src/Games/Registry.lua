-- // src/Games/Registry.lua
local SETTINGS = {
	REGISTRY = {
		["155615604"] = {
			Name = "Prison Life",
			Folder = "155615604",
			Description = "Prison Life automated door phasing, warp gun grabber, and weapon mods",
		},
	},
}

return function()
	local registryCopy = {}
	for placeId, config in pairs(SETTINGS.REGISTRY) do
		local idStr = tostring(placeId)
		local data = {
			Name = config.Name,
			Folder = config.Folder or idStr,
			Description = config.Description or "",
		}
		registryCopy[idStr] = data
	end
	return registryCopy
end
