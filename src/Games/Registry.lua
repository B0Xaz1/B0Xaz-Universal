local SETTINGS = {
	REGISTRY = {
		["155615604"] = {
			Name = "Prison Life",
			Folder = "155615604",
			Description = "Prison Life automated door phasing and weapon enhancements",
		},
	},
}

return function()
	local registryCopy = {}
	for placeId, config in pairs(SETTINGS.REGISTRY) do
		registryCopy[placeId] = {
			Name = config.Name,
			Folder = config.Folder,
			Description = config.Description,
		}
	end
	return registryCopy
end
