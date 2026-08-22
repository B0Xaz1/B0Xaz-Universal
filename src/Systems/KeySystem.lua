-- // src/Systems/KeySystem.lua
return function(Context, import)
	local HttpService = game:GetService("HttpService")
	local Players = game:GetService("Players")

	local Utils = Context.Utils or {}
	local CONFIG = Context.CONFIG or {}
	local importFn = import or Context.import

	local KEY_PATHS = {
		ENTRY  = "src/Keys/Entry.lua",
		NORMAL = "src/Keys/Normal.lua",
		FULL   = "src/Keys/Full.lua",
	}

	local TIER_NAMES = {
		[3] = "Tier 3 (Full Access)",
		[2] = "Tier 2 (Normal)",
		[1] = "Tier 1 (Entry)",
		[0] = "None",
	}

	local FALLBACK = {
		[3] = { "Main Access", "FULL-ALPHA-01", "FULL-BETA-02", "FULL-TEST-KEY" },
		[2] = { "NORMAL-TEST-KEY", "NORMAL-ACCESS", "NORMAL-ALPHA-01", "NORMAL-BETA-02" },
		[1] = { "ENTRY-TEST-KEY", "ENTRY-ACCESS", "ENTRY-ALPHA-01", "ENTRY-BETA-02" },
	}

	local KeySystem = { CurrentTier = 0, CurrentKey = "" }
	local lastValidate = 0
	local keyLookup = {}

	for tier, keys in pairs(FALLBACK) do
		for _, key in ipairs(keys) do
			local n = tostring(key):match("^%s*(.-)%s*$")
			if n and n ~= "" then keyLookup[n] = tier end
		end
	end

	local function loadKeys(path, tier)
		if type(importFn) ~= "function" then return end
		local ok, list = pcall(importFn, path, true)
		if ok and type(list) == "table" then
			for _, key in ipairs(list) do
				local n = tostring(key):match("^%s*(.-)%s*$")
				if n and n ~= "" then keyLookup[n] = tier end
			end
		end
	end

	loadKeys(KEY_PATHS.ENTRY, 1)
	loadKeys(KEY_PATHS.NORMAL, 2)
	loadKeys(KEY_PATHS.FULL, 3)

	local function keyPath()
		return string.format("%s/_key.json", CONFIG.FOLDER or "B0XazUniversal")
	end

	local function getHWID()
		local hwid = ""
		pcall(function()
			hwid = game:GetService("RbxAnalyticsService"):GetClientId()
		end)
		if type(hwid) == "string" and hwid ~= "" then return hwid end
		local lp = Players.LocalPlayer
		return lp and tostring(lp.UserId) or "UNKNOWN"
	end

	local function trim(s)
		return tostring(s or ""):match("^%s*(.-)%s*$") or ""
	end

	function KeySystem.GetTierName()
		return TIER_NAMES[KeySystem.CurrentTier] or TIER_NAMES[0]
	end

	function KeySystem.GetMaskedKey()
		local key = KeySystem.CurrentKey
		if not key or key == "" then return "None" end
		if #key <= 4 then return string.rep("*", #key) end
		return key:sub(1, 2) .. string.rep("*", #key - 4) .. key:sub(-2)
	end

	function KeySystem.Validate(input)
		local now = os.clock()
		if (now - lastValidate) < 0.25 then
			return false, KeySystem.CurrentTier, "Please wait before trying again."
		end
		lastValidate = now

		local clean = trim(input)
		if clean == "" then return false, 0, "Key cannot be empty." end

		local tier = keyLookup[clean]
		if tier == 3 then return true, 3, "Full Access Granted!", clean end
		if tier == 2 then return true, 2, "Normal Access Granted!", clean end
		if tier == 1 then return true, 1, "Entry Access Granted!", clean end
		return false, 0, "Incorrect Key. Access Denied."
	end

	function KeySystem.SaveKey(key)
		local payload = { Key = key, HWID = getHWID(), SavedAt = os.time() }
		local ok, encoded = pcall(function() return HttpService:JSONEncode(payload) end)
		if ok and Utils.WriteFile then
			return Utils.WriteFile(keyPath(), encoded)
		end
		return false
	end

	function KeySystem.ApplyKey(key)
		local ok, tier, msg, canonical = KeySystem.Validate(key)
		if not ok then return false, 0, msg end
		KeySystem.CurrentKey = canonical
		KeySystem.CurrentTier = tier
		KeySystem.SaveKey(canonical)
		return true, tier, msg
	end

	function KeySystem.LoadAndVerify()
		if not Utils.ReadFile then return false, 0, "" end
		local content = Utils.ReadFile(keyPath())
		if not content or content == "" then return false, 0, "" end

		local ok, data = pcall(function() return HttpService:JSONDecode(content) end)
		if not ok or type(data) ~= "table" or not data.Key then return false, 0, "" end

		if data.HWID and data.HWID ~= getHWID() then
			return false, 0, "Key saved on a different device."
		end

		local success, tier, msg, canonical = KeySystem.Validate(data.Key)
		if success then
			KeySystem.CurrentKey = canonical
			KeySystem.CurrentTier = tier
		end
		return success, tier, msg
	end

	function KeySystem.ClearKey()
		KeySystem.CurrentKey = ""
		KeySystem.CurrentTier = 0
		pcall(function()
			if delfile then delfile(keyPath()) end
		end)
	end

	function KeySystem.CopyGetKeyLink()
		pcall(function()
			if setclipboard then
				setclipboard("This script uses tier-based access. Contact the owner for an Entry, Normal, or Full key.")
			end
		end)
		return true, "Information copied to clipboard."
	end

	return KeySystem
end
