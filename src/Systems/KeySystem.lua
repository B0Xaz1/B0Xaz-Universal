-- // src/Systems/KeySystem.lua
local SETTINGS = {
	KEY_PATHS = {
		ENTRY = "src/Keys/Entry.lua",
		NORMAL = "src/Keys/Normal.lua",
		FULL = "src/Keys/Full.lua",
	},
	TIERS = {
		[3] = "Tier 3 (Full Access)",
		[2] = "Tier 2 (Normal)",
		[1] = "Tier 1 (Entry)",
		[0] = "None",
	},
	FILES = {
		DEFAULT_FOLDER = "B0XazUniversal",
		KEY_FILENAME = "_key.json",
	},
	MESSAGES = {
		KEY_INFO = "This script uses tier-based access. Contact the owner to get an Entry, Normal, or Full key.",
		EMPTY_KEY = "Key cannot be empty.",
		FULL_ACCESS = "Full Access Granted!",
		NORMAL_ACCESS = "Normal Access Granted!",
		ENTRY_ACCESS = "Entry Access Granted!",
		DENIED = "Incorrect Key. Access Denied.",
		HWID_MISMATCH = "Key saved on a different device.",
		CLIPBOARD_COPIED = "Information copied to clipboard.",
		RATE_LIMITED = "Please wait before trying again.",
	},
	LIMITS = {
		VALIDATE_COOLDOWN = 0.25,
		MIN_MASK_LENGTH = 4,
	},
	FALLBACK_KEYS = {
		[3] = { "Main Access", "FULL-ALPHA-01", "FULL-BETA-02", "FULL-TEST-KEY" },
		[2] = { "NORMAL-TEST-KEY", "NORMAL-ACCESS" },
		[1] = { "ENTRY-TEST-KEY", "ENTRY-ACCESS" },
	},
}

return function(Context, import)
	local HttpService = game:GetService("HttpService")
	local Players = game:GetService("Players")
	local RbxAnalyticsService = game:GetService("RbxAnalyticsService")

	local Utils = (Context and Context.Utils) or {}
	local CONFIG = (Context and Context.CONFIG) or {}
	local importFn = import or (Context and Context.import)

	local KeySystem = {
		CurrentTier = 0,
		CurrentKey = "",
	}

	local lastValidationTime = 0
	local keyLookup = {}

	for tier, keys in pairs(SETTINGS.FALLBACK_KEYS) do
		for _, key in ipairs(keys) do
			local normalized = tostring(key):match("^%s*(.-)%s*$")
			if normalized and normalized ~= "" then
				keyLookup[normalized] = tier
			end
		end
	end

	local function populateKeyLookup(path, tier)
		if type(importFn) ~= "function" then return end
		local success, keyList = pcall(importFn, path)
		if success and type(keyList) == "table" then
			for _, key in ipairs(keyList) do
				local normalized = tostring(key):match("^%s*(.-)%s*$")
				if normalized and normalized ~= "" then
					keyLookup[normalized] = tier
				end
			end
		end
	end

	populateKeyLookup(SETTINGS.KEY_PATHS.ENTRY, 1)
	populateKeyLookup(SETTINGS.KEY_PATHS.NORMAL, 2)
	populateKeyLookup(SETTINGS.KEY_PATHS.FULL, 3)

	local function getKeyFilePath()
		local folder = tostring(CONFIG.FOLDER or SETTINGS.FILES.DEFAULT_FOLDER)
		return string.format("%s/%s", folder, SETTINGS.FILES.KEY_FILENAME)
	end

	local function getHWID()
		local hwid = ""
		pcall(function()
			hwid = RbxAnalyticsService:GetClientId()
		end)
		if type(hwid) == "string" and hwid ~= "" then
			return hwid
		end
		local localPlayer = Players.LocalPlayer
		if localPlayer then
			return tostring(localPlayer.UserId)
		end
		return "UNKNOWN_HWID"
	end

	local function trim(str)
		return tostring(str or ""):match("^%s*(.-)%s*$") or ""
	end

	function KeySystem.GetTierName()
		return SETTINGS.TIERS[KeySystem.CurrentTier] or SETTINGS.TIERS[0]
	end

	function KeySystem.GetMaskedKey()
		local key = KeySystem.CurrentKey
		if not key or key == "" then
			return SETTINGS.TIERS[0]
		end
		local len = #key
		if len <= SETTINGS.LIMITS.MIN_MASK_LENGTH then
			return string.rep("*", len)
		end
		return key:sub(1, 2) .. string.rep("*", len - 4) .. key:sub(-2)
	end

	function KeySystem.Validate(userInput)
		local now = os.clock()
		if (now - lastValidationTime) < SETTINGS.LIMITS.VALIDATE_COOLDOWN then
			return false, KeySystem.CurrentTier, SETTINGS.MESSAGES.RATE_LIMITED
		end
		lastValidationTime = now

		local cleanKey = trim(userInput)
		if cleanKey == "" then
			return false, 0, SETTINGS.MESSAGES.EMPTY_KEY
		end

		local tier = keyLookup[cleanKey]
		if tier == 3 then
			return true, 3, SETTINGS.MESSAGES.FULL_ACCESS, cleanKey
		elseif tier == 2 then
			return true, 2, SETTINGS.MESSAGES.NORMAL_ACCESS, cleanKey
		elseif tier == 1 then
			return true, 1, SETTINGS.MESSAGES.ENTRY_ACCESS, cleanKey
		end

		return false, 0, SETTINGS.MESSAGES.DENIED
	end

	function KeySystem.SaveKey(key)
		local filePath = getKeyFilePath()
		local payload = {
			Key = key,
			HWID = getHWID(),
			SavedAt = os.time(),
		}
		local success, encoded = pcall(function()
			return HttpService:JSONEncode(payload)
		end)
		if success and Utils.WriteFile then
			return Utils.WriteFile(filePath, encoded)
		end
		return false
	end

	function KeySystem.ApplyKey(key)
		local success, tier, msg, canonicalKey = KeySystem.Validate(key)
		if not success then
			return false, 0, msg
		end

		KeySystem.CurrentKey = canonicalKey
		KeySystem.CurrentTier = tier
		KeySystem.SaveKey(canonicalKey)
		return true, tier, msg
	end

	function KeySystem.LoadAndVerify()
		if not Utils.ReadFile then
			return false, 0, ""
		end

		local filePath = getKeyFilePath()
		local content = Utils.ReadFile(filePath)
		if not content or content == "" then
			return false, 0, ""
		end

		local decodeSuccess, data = pcall(function()
			return HttpService:JSONDecode(content)
		end)
		if not decodeSuccess or type(data) ~= "table" or not data.Key then
			return false, 0, ""
		end

		if data.HWID and data.HWID ~= getHWID() then
			return false, 0, SETTINGS.MESSAGES.HWID_MISMATCH
		end

		local success, tier, msg, canonicalKey = KeySystem.Validate(data.Key)
		if success then
			KeySystem.CurrentKey = canonicalKey
			KeySystem.CurrentTier = tier
		end
		return success, tier, msg
	end

	function KeySystem.ClearKey()
		KeySystem.CurrentKey = ""
		KeySystem.CurrentTier = 0
		local filePath = getKeyFilePath()
		pcall(function()
			if delfile then
				delfile(filePath)
			end
		end)
	end

	function KeySystem.CopyGetKeyLink()
		pcall(function()
			if setclipboard then
				setclipboard(SETTINGS.MESSAGES.KEY_INFO)
			end
		end)
		return true, SETTINGS.MESSAGES.CLIPBOARD_COPIED
	end

	return KeySystem
end
