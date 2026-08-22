-- src/Systems/KeySystem.lua
return function(Context)
	local KeySystem = {}
	local HttpService = game:GetService("HttpService")
	local Players = game:GetService("Players")
	local Utils = Context.Utils
	local CONFIG = Context.CONFIG

	-- 1 = Entry, 2 = Normal, 3 = Full
	local VALID_KEYS = {
		-- Entry
		["B0XAZ-ENTRY-A1B2C3"] = 1,
		["B0XAZ-ENTRY-X9Y8Z7"] = 1,
		-- Normal
		["B0XAZ-NORM-D4E5F6"] = 2,
		["B0XAZ-NORM-Q1W2E3"] = 2,
		-- Full
		["B0XAZ-FULL-G7H8I9"] = 3,
		["B0XAZ-FULL-M9N8B7"] = 3,
		["B0XAZ-FULL-A5NAD3"] = 3,
		["B0XAZ-FULL-9PAL31"] = 3,
		["B0XAZ-FULL-9XAP12"] = 3,
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

	local function getHWID()
		local hwid = ""
		pcall(function()
			hwid = game:GetService("RbxAnalyticsService"):GetClientId()
		end)
		if type(hwid) ~= "string" or hwid == "" then
			local lp = Players.LocalPlayer
			hwid = lp and tostring(lp.UserId) or "unknown"
		end
		return hwid
	end

	function KeySystem.GetTierName(tier)
		return TIER_NAMES[tier or KeySystem.CurrentTier] or "Unknown"
	end

	function KeySystem.HasTier(req)
		req = tonumber(req) or 1
		return (tonumber(KeySystem.CurrentTier) or 0) >= req
	end

	function KeySystem.Validate(key)
		key = trim(key):upper()
		-- allow users to type lowercase; stored keys are uppercase
		-- rebuild lookup with uppercase keys
		if key == "" then
			return false, 0, "Key cannot be empty."
		end

		-- direct match first
		local tier = VALID_KEYS[key]
		if not tier then
			-- try original case map with normalized key
			for k, t in pairs(VALID_KEYS) do
				if trim(k):upper() == key then
					tier = t
					key = trim(k) -- keep canonical stored form
					break
				end
			end
		end

		if tier then
			return true, tier, "Authentication Successful.", key
		end
		return false, 0, "Invalid or unrecognized key.", nil
	end

	function KeySystem.SaveKey(key)
		key = trim(key)
		local data = {
			Key = key,
			HWID = getHWID(),
			SavedAt = os.time(),
		}
		local ok, encoded = pcall(function()
			return HttpService:JSONEncode(data)
		end)
		if not ok then
			return false, "Failed to encode key data."
		end
		local wrote, err = Utils.WriteFile(KEY_FILE, encoded)
		return wrote, err
	end

	function KeySystem.ApplyKey(key)
		local ok, tier, msg, canonical = KeySystem.Validate(key)
		if not ok then
			return false, 0, msg
		end
		canonical = canonical or trim(key)
		KeySystem.CurrentKey = canonical
		KeySystem.CurrentTier = tier
		local saved, saveErr = KeySystem.SaveKey(canonical)
		if not saved then
			return true, tier, "Key valid, but failed to save: " .. tostring(saveErr)
		end
		return true, tier, msg
	end

	function KeySystem.LoadAndVerify()
		Utils.MakeFolder(CONFIG.FOLDER)

		local content = Utils.ReadFile(KEY_FILE)
		if not content or content == "" then
			return false, 0, ""
		end

		local ok, data = pcall(function()
			return HttpService:JSONDecode(content)
		end)
		if not ok or type(data) ~= "table" or not data.Key then
			return false, 0, "Corrupted key file."
		end

		-- HWID bind
		if data.HWID and data.HWID ~= "" then
			local current = getHWID()
			if tostring(data.HWID) ~= tostring(current) then
				return false, 0, "HWID Mismatch! Key is bound to another device."
			end
		end

		local valid, tier, msg, canonical = KeySystem.Validate(data.Key)
		if not valid then
			return false, 0, "Saved key has been revoked or expired."
		end

		KeySystem.CurrentKey = canonical or trim(data.Key)
		KeySystem.CurrentTier = tier
		return true, tier, msg or "Authentication Successful."
	end

	function KeySystem.ClearKey()
		KeySystem.CurrentKey = ""
		KeySystem.CurrentTier = 0
		pcall(function()
			if isfile and isfile(KEY_FILE) then
				delfile(KEY_FILE)
			end
		end)
	end

	function KeySystem.GetMaskedKey()
		local k = KeySystem.CurrentKey
		if not k or k == "" then
			return "None"
		end
		if #k <= 10 then
			return string.rep("*", #k)
		end
		return k:sub(1, 6) .. string.rep("*", math.max(4, #k - 10)) .. k:sub(-4)
	end

	return KeySystem
end
