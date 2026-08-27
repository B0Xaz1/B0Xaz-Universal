local HttpService = game:GetService("HttpService")

local LICENSE_API_URL = "https://rogqxmrswmjarbqhvpjj.supabase.co/functions/v1/validate-license"
local SUPABASE_KEY = "sb_publishable_YIP4w2sYX6KbpVEjLiI3Xg_nG9VL0UG"
local STATIC_SALT = "B0Xaz_Universal_Key_System_2026"

local TIER_NAMES = {
	[3] = "Tier 3 (Full Access)",
	[2] = "Tier 2 (Normal)",
	[1] = "Tier 1 (Entry)",
	[0] = "No Access",
}

return function(services: any)
	local Environment = services:Get("Environment")
	local StateStore = services:Get("StateStore")

	local KeyService = {
		CurrentKey = "",
		CurrentTier = 0,
	}

	local function debug(message: string)
		print("[B0Xaz][KeyService] " .. message)
	end

	debug("Initialized")

	local function getKeyFilePath(): string
		return "B0XazUniversal/_key.json"
	end

	-- Uses whichever HTTP implementation the executor provides; RequestAsync
	-- is the last-resort fallback since it is slowest on some executors.
	local function attemptValidation(key: string, hwid: string): (boolean, number, string, boolean)
		debug("Validation request: preparing payload")
		local payload = HttpService:JSONEncode({ key = key, hwid = hwid })
		local headers = {
			["Content-Type"] = "application/json",
			["apikey"] = SUPABASE_KEY,
			["Authorization"] = "Bearer " .. SUPABASE_KEY,
		}

		local reqFn = request or http_request or (syn and syn.request) or (http and http.request)
		local ok, response = false, nil

		if typeof(reqFn) == "function" then
			ok, response = pcall(reqFn, { Url = LICENSE_API_URL, Method = "POST", Headers = headers, Body = payload })
		else
			ok, response = pcall(function()
				return HttpService:RequestAsync({ Url = LICENSE_API_URL, Method = "POST", Headers = headers, Body = payload })
			end)
		end

		if not ok or typeof(response) ~= "table" then
			debug("Validation request failed: no response table")
			return false, 0, "Authentication server unreachable.", true
		end

		local statusCode = tonumber(response.StatusCode or response.Status) or 500
		debug("Validation response status=" .. tostring(statusCode))
		local body = response.Body or response.body or ""

		if statusCode < 200 or statusCode >= 300 then
			local errMsg = "License rejected."
			if typeof(body) == "string" then
				local decodeOk, decoded = pcall(HttpService.JSONDecode, HttpService, body)
				if decodeOk and typeof(decoded) == "table" and decoded.error then
					errMsg = tostring(decoded.error)
				end
			end
			-- 5xx and rate limiting are the backend faulting, which says
			-- nothing about whether the key itself is good.
			local transient = statusCode >= 500 or statusCode == 408 or statusCode == 429
			if transient then
				errMsg = "Server error: " .. errMsg
			end
			return false, 0, errMsg, transient
		end

		local decodeOk, data = pcall(HttpService.JSONDecode, HttpService, body)
		if not decodeOk or typeof(data) ~= "table" or data.valid ~= true then
			return false, 0, (typeof(data) == "table" and tostring(data.error or "Invalid license")) or "Invalid server response.", false
		end

		local tierMap = { Entry = 1, Normal = 2, Full = 3 }
		local tierNumber = tierMap[data.tier] or 0
		if tierNumber == 0 then return false, 0, "License tier invalid.", false end

		return true, tierNumber, data.tier .. " Access Granted", false
	end

	-- A backend blip must not read as a bad key, so transient failures are
	-- retried before the modal is shown.
	local function requestValidation(key: string, hwid: string): (boolean, number, string)
		local valid, tier, msg, transient
		for attempt = 1, 3 do
			valid, tier, msg, transient = attemptValidation(key, hwid)
			if valid or not transient then
				return valid, tier, msg
			end
			debug("Validation attempt " .. attempt .. " failed transiently: " .. tostring(msg))
			task.wait(attempt * 1.5)
		end
		return false, 0, tostring(msg) .. " (retried 3 times)"
	end

	-- The key is wrapped in XOR + base64 before touching disk; this is
	-- obfuscation against casual inspection, not real encryption.
	function KeyService:SaveEncryptedKey(rawKey: string): boolean
		local payload = HttpService:JSONEncode({ Key = rawKey, Timestamp = os.time() })
		local scrambled = Environment.Base64Encode(Environment.XorCipher(payload, STATIC_SALT))
		local ok, _ = Environment.WriteFile(getKeyFilePath(), scrambled)
		return ok
	end

	function KeyService:VerifySavedKey(): (boolean, number, string)
		debug("VerifySavedKey: reading saved key")
		local content = Environment.ReadFile(getKeyFilePath())
		if not content or content == "" then
			debug("VerifySavedKey: no saved key found")
			return false, 0, "No key found"
		end

		local jsonPayload: string? = nil
		pcall(function()
			local decoded = Environment.Base64Decode(content)
			jsonPayload = Environment.XorCipher(decoded, STATIC_SALT)
		end)

		-- Files written by older builds are plain JSON; fall back to the raw
		-- content when the round trip does not come out as an object.
		if not jsonPayload or jsonPayload:sub(1, 1) ~= "{" then
			jsonPayload = content
		end

		local decodeOk, data = pcall(HttpService.JSONDecode, HttpService, jsonPayload or "")
		if not decodeOk or typeof(data) ~= "table" or typeof(data.Key) ~= "string" then
			debug("VerifySavedKey: saved key is corrupt")
			return false, 0, "Saved key corrupt"
		end

		debug("VerifySavedKey: saved key decoded; authenticating")
		return self:AuthenticateKey(data.Key)
	end

	function KeyService:AuthenticateKey(rawKey: string): (boolean, number, string)
		debug("AuthenticateKey: validating supplied key")
		local cleanKey = tostring(rawKey or ""):match("^%s*(.-)%s*$") or ""
		if cleanKey == "" then
			debug("AuthenticateKey: key is empty")
			return false, 0, "Key cannot be empty"
		end

		debug("AuthenticateKey: requesting device id")
		local hwid = Environment.GetDeviceId()
		debug("AuthenticateKey: requesting validation")
		local valid, tier, msg = requestValidation(cleanKey, hwid)

		if valid then
			debug("AuthenticateKey: validation succeeded tier=" .. tostring(tier))
			self.CurrentKey = cleanKey
			self.CurrentTier = tier
			self:SaveEncryptedKey(cleanKey)
			StateStore:SetTier(tier)
			return true, tier, msg
		end

		debug("AuthenticateKey: validation rejected")
		return false, 0, msg
	end

	function KeyService:ClearKey()
		self.CurrentKey = ""
		self.CurrentTier = 0
		Environment.DeleteFile(getKeyFilePath())
		StateStore:SetTier(0)
	end

	function KeyService:GetTierName(): string
		return TIER_NAMES[self.CurrentTier] or "No Access"
	end

	function KeyService:GetMaskedKey(): string
		if self.CurrentKey == "" then return "None" end
		return string.rep("•", 12)
	end

	function KeyService:CopyInfo(): (boolean, string)
		Environment.SetClipboard("https://discord.gg/B0XazHub")
		return true, "Discord support invite copied to clipboard."
	end

	return KeyService
end
