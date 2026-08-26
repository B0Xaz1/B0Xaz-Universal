--!strict
-- ══════════════════════════════════════════════════════════════════════════════
-- B0XazUniversal - License Authentication & Key Service
-- Validates tokens against Supabase Edge Functions, manages HWID bindings,
-- and encrypts saved keys locally in B0XazUniversal/_key.json.
-- ══════════════════════════════════════════════════════════════════════════════

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

	local function getKeyFilePath(): string
		return "B0XazUniversal/_key.json"
	end

	-- Send HTTP Request to Supabase Authentication Endpoint
	local function requestValidation(key: string, hwid: string): (boolean, number, string)
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
			return false, 0, "Authentication server unreachable."
		end

		local statusCode = tonumber(response.StatusCode or response.Status) or 500
		local body = response.Body or response.body or ""

		if statusCode < 200 or statusCode >= 300 then
			local errMsg = "License rejected."
			if typeof(body) == "string" then
				local decodeOk, decoded = pcall(HttpService.JSONDecode, HttpService, body)
				if decodeOk and typeof(decoded) == "table" and decoded.error then
					errMsg = tostring(decoded.error)
				end
			end
			return false, 0, errMsg
		end

		local decodeOk, data = pcall(HttpService.JSONDecode, HttpService, body)
		if not decodeOk or typeof(data) ~= "table" or data.valid ~= true then
			return false, 0, (typeof(data) == "table" and tostring(data.error or "Invalid license")) or "Invalid server response."
		end

		local tierMap = { Entry = 1, Normal = 2, Full = 3 }
		local tierNumber = tierMap[data.tier] or 0
		if tierNumber == 0 then return false, 0, "License tier invalid." end

		return true, tierNumber, data.tier .. " Access Granted"
	end

	function KeyService:SaveEncryptedKey(rawKey: string): boolean
		local payload = HttpService:JSONEncode({ Key = rawKey, Timestamp = os.time() })
		local scrambled = Environment.Base64Encode(Environment.XorCipher(payload, STATIC_SALT))
		local ok, _ = Environment.WriteFile(getKeyFilePath(), scrambled)
		return ok
	end

	function KeyService:VerifySavedKey(): (boolean, number, string)
		local content = Environment.ReadFile(getKeyFilePath())
		if not content or content == "" then return false, 0, "No key found" end

		local jsonPayload: string? = nil
		pcall(function()
			local decoded = Environment.Base64Decode(content)
			jsonPayload = Environment.XorCipher(decoded, STATIC_SALT)
		end)

		if not jsonPayload or jsonPayload:sub(1, 1) ~= "{" then
			jsonPayload = content -- Plain JSON fallback
		end

		local decodeOk, data = pcall(HttpService.JSONDecode, HttpService, jsonPayload or "")
		if not decodeOk or typeof(data) ~= "table" or typeof(data.Key) ~= "string" then
			return false, 0, "Saved key corrupt"
		end

		return self:AuthenticateKey(data.Key)
	end

	function KeyService:AuthenticateKey(rawKey: string): (boolean, number, string)
		local cleanKey = tostring(rawKey or ""):match("^%s*(.-)%s*$") or ""
		if cleanKey == "" then return false, 0, "Key cannot be empty" end

		local hwid = Environment.GetDeviceId()
		local valid, tier, msg = requestValidation(cleanKey, hwid)

		if valid then
			self.CurrentKey = cleanKey
			self.CurrentTier = tier
			self:SaveEncryptedKey(cleanKey)
			StateStore:SetTier(tier)
			return true, tier, msg
		end

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
