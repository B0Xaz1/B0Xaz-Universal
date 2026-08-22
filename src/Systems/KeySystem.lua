-- src/Systems/KeySystem.lua
return function(Context)
	local KeySystem = {}
	local HttpService = game:GetService("HttpService")
	local Players = game:GetService("Players")
	local Utils = Context.Utils
	local CONFIG = Context.CONFIG

	-- ================================================================
	-- PLATOBOOST CONFIGURATION (Free Plan - 1 Service)
	-- Replace with your single Service ID and Gateway Link from Platoboost
	-- ================================================================
	KeySystem.SERVICE_ID = "YOUR_PLATOBOOST_SERVICE_ID"
	KeySystem.GET_KEY_URL = "https://gateway.platoboost.com/a/YOUR_LINK_ID"

	-- Optional: Manual exact key overrides if you don't want to use prefixes
	local EXACT_TIER_OVERRIDES = {
		["MY-CUSTOM-FULL-KEY-123"] = 3,
		["MY-CUSTOM-NORM-KEY-456"] = 2,
	}

	local TIER_NAMES = {
		[0] = "No Access",
		[1] = "Entry Tier",
		[2] = "Normal Tier",
		[3] = "Full Access",
	}

	KeySystem.CurrentTier = 0
	KeySystem.CurrentKey = ""
	local KEY_FILE = tostring(CONFIG.FOLDER) .. "/_key.json"

	local function trim(s)
		return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
	end

	local function platoboostVerify(serviceId, key)
		local url = string.format("https://api.platoboost.com/public/whitelist/v2/verify?service=%s&key=%s", serviceId, key)
		local success, response = pcall(function()
			return game:HttpGet(url)
		end)

		if success and response then
			local ok, data = pcall(function() return HttpService:JSONDecode(response) end)
			if ok and type(data) == "table" then
				return data.success == true, data.message or ""
			end
		end
		return false, "Network error reaching Platoboost."
	end

	function KeySystem.GetTierName(tier)
		return TIER_NAMES[tier or KeySystem.CurrentTier] or "Unknown"
	end

	function KeySystem.HasTier(req)
		req = tonumber(req) or 1
		return (tonumber(KeySystem.CurrentTier) or 0) >= req
	end

	-- ================================================================
	-- Validate Key via Platoboost + Determine Tier Level
	-- ================================================================
	function KeySystem.Validate(key)
		key = trim(key)
		if key == "" then
			return false, 0, "Key cannot be empty."
		end

		if KeySystem.SERVICE_ID == "YOUR_PLATOBOOST_SERVICE_ID" or KeySystem.SERVICE_ID == "" then
			return false, 0, "Developer setup required: Service ID not set."
		end

		-- 1. Check validity with Platoboost API
		local isValid, pbMsg = platoboostVerify(KeySystem.SERVICE_ID, key)
		if not isValid then
			return false, 0, (pbMsg ~= "" and pbMsg or "Invalid or expired Platoboost key.")
		end

		-- 2. Platoboost confirmed key is valid! Now determine tier:
		local uppercaseKey = key:upper()
		local tier = 1 -- Default for standard link completion keys

		-- Exact override check
		if EXACT_TIER_OVERRIDES[key] or EXACT_TIER_OVERRIDES[uppercaseKey] then
			tier = EXACT_TIER_OVERRIDES[key] or EXACT_TIER_OVERRIDES[uppercaseKey]
		-- Prefix checks for Tier 3 (Full)
		elseif uppercaseKey:sub(1, 5) == "FULL-" 
			or uppercaseKey:sub(1, 5) == "FULL_" 
			or uppercaseKey:find("B0XAZ-FULL") 
			or uppercaseKey:find("FULLACCESS") then
			tier = 3
		-- Prefix checks for Tier 2 (Normal)
		elseif uppercaseKey:sub(1, 5) == "NORM-" 
			or uppercaseKey:sub(1, 5) == "NORM_" 
			or uppercaseKey:find("B0XAZ-NORM") 
			or uppercaseKey:find("NORMAL") then
			tier = 2
		end

		return true, tier, "Authenticated: " .. TIER_NAMES[tier], key
	end

	function KeySystem.SaveKey(key)
		key = trim(key)
		local data = { Key = key, SavedAt = os.time() }
		local ok, encoded = pcall(function() return HttpService:JSONEncode(data) end)
		if ok then Utils.WriteFile(KEY_FILE, encoded) end
	end

	function KeySystem.ApplyKey(key)
		local ok, tier, msg, canonical = KeySystem.Validate(key)
		if not ok then return false, 0, msg end
		KeySystem.CurrentKey = canonical or key
		KeySystem.CurrentTier = tier
		KeySystem.SaveKey(KeySystem.CurrentKey)
		return true, tier, msg
	end

	function KeySystem.LoadAndVerify()
		Utils.MakeFolder(CONFIG.FOLDER)
		local content = Utils.ReadFile(KEY_FILE)
		if not content or content == "" then return false, 0, "" end

		local ok, data = pcall(function() return HttpService:JSONDecode(content) end)
		if ok and type(data) == "table" and data.Key then
			local valid, tier, msg, canonical = KeySystem.Validate(data.Key)
			if valid then
				KeySystem.CurrentKey = canonical or data.Key
				KeySystem.CurrentTier = tier
				return true, tier, msg
			end
		end
		return false, 0, "Saved key is no longer valid."
	end

	function KeySystem.ClearKey()
		KeySystem.CurrentKey = ""
		KeySystem.CurrentTier = 0
		pcall(function() if isfile(KEY_FILE) then delfile(KEY_FILE) end end)
	end

	function KeySystem.GetMaskedKey()
		local k = KeySystem.CurrentKey
		if not k or k == "" then return "None" end
		if #k <= 10 then return "****" end
		return k:sub(1, 4) .. "****" .. k:sub(-4)
	end

	return KeySystem
end
