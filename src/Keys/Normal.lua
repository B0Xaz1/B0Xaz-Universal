local SETTINGS = {
	KEYS = {
		"NORMAL-ALPHA-01",
		"NORMAL-BETA-02",
		"NORMAL-TEST-KEY",
	},
}

local keyList = table.create(#SETTINGS.KEYS)
for index, key in ipairs(SETTINGS.KEYS) do
	keyList[index] = key
end

return keyList
