-- src/Systems/KeySystem.lua
return function(Context)
	local KeySystem = {}
	local HttpService = game:GetService("HttpService")
	local Players = game:GetService("Players")
	local Utils = Context.Utils
	local CONFIG = Context.CONFIG

	-- ================================================================
	-- PLATOBOOST CONFIGURATION
	-- Replace these with the IDs from your Platoboost Dashboard
	-- ================================================================
	local SERVICES = {
		[3] = "YOUR_FULL_ACCESS_SERVICE_ID",   -- Tier 3
		[2] = "YOUR_NORMAL_TIER_SERVICE_ID",   -- Tier 2
		[1] = "YOUR_ENTRY_TIER_SERVICE_ID",    -- Tier 1
	}

	-- Links to show in the UI for users to get keys
	KeySystem.GET_KEY_URLS = {
		[3] = "https://gateway.platoboost.com/a/YOUR_FULL_LINK_ID",
		[2] = "https://gateway.platoboost.com/a/YOUR_NORMAL_LINK_ID",
		[1] = "https://gateway.platoboost.com/a/YOUR_ENTRY_LINK_ID",
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

	local function trim(s) return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")) end

	local function getHWID()
		local hwid = ""
		pcall(function() hwid = game:GetService("RbxAnalyticsService"):GetClientId() end)
		if not hwid or hwid == "" then hwid = tostring(Players.LocalPlayer.UserId) end
		return hwid
	end

	local function platoboostVerify(serviceId, key)
		local url = string.format("https://api.platoboost.com/public/whitelist/v2/verify?service=%s&key=%s", serviceId, key)
		local success, response = pcall(function()
			return game:HttpGet(url)
		end)

		if success then
			local ok, data = pcall(function() return HttpService:JSONDecode(response) end)
			-- Platoboost returns { "success": true } if valid
			return ok and data.success == true
		end
		return false
	end

	function KeySystem.GetTierName(tier) return TIER_NAMES[tier or KeySystem.CurrentTier] or "Unknown" end

	-- ================================================================
	-- Logic: Check key against each tier's Service ID
	-- ================================================================
	function KeySystem.Validate(key)
		key = trim(key)
		if key == "" then return false, 0, "Key cannot be empty." end

		-- Check tiers from highest (Full) to lowest (Entry)
		for tierLevel = 3, 1, -1 do
			local serviceId = SERVICES[tierLevel]
			if serviceId and serviceId ~= "" and serviceId ~= "YOUR_ID_HERE" then
				if platoboostVerify(serviceId, key) then
					return true, tierLevel, "Authentication Successful!", key
				end
			end
		end

		return false, 0, "Invalid key or expired session.", nil
	end

	function KeySystem.SaveKey(key)
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
			-- Verification is live against Platoboost
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
