-- // src/Keys/Full.lua
local SETTINGS = {
	KEYS = {
		"Main Access",
		"FULL-ALPHA-01",
		"FULL-BETA-02",
		"FULL-TEST-KEY",
	},
}

local keyList = table.create(#SETTINGS.KEYS)
for index, key in ipairs(SETTINGS.KEYS) do
	keyList[index] = key
end

return keyList
