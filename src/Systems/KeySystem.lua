-- src/Systems/KeySystem.lua
return function(Context)
	local KeySystem = {}
	local HttpService = game:GetService("HttpService")
	local Utils = Context.Utils
	local CONFIG = Context.CONFIG

	-- Add, remove, or change keys here.
	-- 1 = Entry, 2 = Normal, 3 = Full
	local VALID_KEYS = {
		-- Entry Keys
		["B0XAZ-ENTRY-A1B2C3"] = 1,
		["B0XAZ-ENTRY-X9Y8Z7"] = 1,
		-- Normal Keys
		["B0XAZ-NORM-D4E5F6"] = 2,
		["B0XAZ-NORM-Q1W2E3"] = 2,
		-- Full Keys
		["B0XAZ-FULL-G7H8I9"] = 3,
		["B0XAZ-FULL-M9N8B7"] = 3,
	}

	local TIER_NAMES = {
		[0] = "No Access",
		[1] = "Entry Tier",
		[2] = "Normal Tier",
		[3] = "Full Access"
	}

	KeySystem.CurrentTier = 0
	KeySystem.CurrentKey = ""
	local KEY_FILE = CONFIG.FOLDER .. "/_key.json"

	-- Securely fetch HWID (Falls back to UserId if executor lacks ClientId API)
	local function getHWID()
		local hwid = ""
		pcall(function() hwid = game:GetService("RbxAnalyticsService"):GetClientId() end)
		if not hwid or hwid == "" then hwid = tostring(game.Players.LocalPlayer.UserId) end
		return hwid
	end

	function KeySystem.GetTierName(tier)
		return TIER_NAMES[tier or KeySystem.CurrentTier] or "Unknown"
	end

	function KeySystem.Validate(key)
		if not key or key == "" then return false, 0, "Key cannot be empty." end
		
		local tier = VALID_KEYS[key]
		if tier then
			return true, tier, "Authentication Successful."
		end
		return false, 0, "Invalid or unrecognized key."
	end

	function KeySystem.SaveKey(key)
		local hwid = getHWID()
		local data = { Key = key, HWID = hwid }
		local ok, encoded = pcall(function() return HttpService:JSONEncode(data) end)
		if ok then
			Utils.WriteFile(KEY_FILE, encoded)
		end
	end

	function KeySystem.LoadAndVerify()
		local content = Utils.ReadFile(KEY_FILE)
		if not content then return false, 0, "" end

		local ok, data = pcall(function() return HttpService:JSONDecode(content) end)
		if ok and type(data) == "table" and data.Key and data.HWID then
			-- HWID Check
			local currentHwid = getHWID()
			if data.HWID ~= currentHwid then
				return false, 0, "HWID Mismatch! Key is bound to another device."
			end
			
			local isValid, tier, msg = KeySystem.Validate(data.Key)
			if isValid then
				KeySystem.CurrentKey = data.Key
				KeySystem.CurrentTier = tier
				return true, tier, msg
			else
				return false, 0, "Saved key has been revoked or expired."
			end
		end
		return false, 0, "Corrupted key file."
	end

	function KeySystem.ClearKey()
		KeySystem.CurrentKey = ""
		KeySystem.CurrentTier = 0
		pcall(function() delfile(KEY_FILE) end)
	end

	return KeySystem
end
