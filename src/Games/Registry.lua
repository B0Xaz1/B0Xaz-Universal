-- src/Games/Registry.lua
-- Map PlaceId (number or string) -> game info
return function()
	return {
		-- Example entries (replace with real place ids you care about)
		["155615604"] = {
			Name = "Prison Life",
			Folder = "155615604",
			Description = "Prison Life-specific features",
		},
	}
end
