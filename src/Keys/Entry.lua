local SETTINGS = {
	KEYS = {
		"ENTRY-ALPHA-01",
		"ENTRY-BETA-02",
		"ENTRY-TEST-KEY",
	},
}

local keyList = table.create(#SETTINGS.KEYS)
for index, key in ipairs(SETTINGS.KEYS) do
	keyList[index] = key
end

return keyList
