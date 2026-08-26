-- ════════════════════════════════════════════════════════════════════════════
-- Services/AuthService.lua
-- Remote license validator, encrypted token cache, and tier gating
-- ════════════════════════════════════════════════════════════════════════════

local AuthService = {}
AuthService.__index = AuthService

local LICENSE_API_URL = "https://rogqxmrswmjarbqhvpjj.supabase.co/functions/v1/validate-license"
local SUPABASE_KEY = "sb_publishable_YIP4w2sYX6KbpVEjLiI3Xg_nG9VL0UG"
local STATIC_SALT = "B0Xaz_Universal_Key_System_2026"

function AuthService.new()
	local self = setmetatable({}, AuthService)
	self.CurrentTier = 0
	self.CurrentKey = ""
	return self
end

function AuthService:Init(container)
	self._crypto = container:Get("Crypto")
	self._http = container:Get("HttpUtil")
	self._constants = container:Get("Constants")
	self._signalClass = container:Get("Signal")
	self.OnTierChanged = self._signalClass.new()
end

function AuthService:_getKeyPath()
	local folder = (self._constants and self._constants.FOLDER) or "B0XazUniversal"
	return string.format("%s/_key.json", folder)
end

-- Validate a raw key against remote backend
function AuthService:Validate(key)
	local cleanKey = tostring(key or ""):match("^%s*(.-)%s*$") or ""
	if cleanKey == "" then 
		return false, 0, "License key cannot be empty." 
	end

	local payload = self._http.JSONEncode({
		key = cleanKey,
		hwid = self._crypto.GetDeviceId(),
	})

	local ok, response = self._http.Request({
		Url = LICENSE_API_URL,
		Method = "POST",
		Headers = {
			["Content-Type"] = "application/json",
			["apikey"] = SUPABASE_KEY,
			["Authorization"] = "Bearer " .. SUPABASE_KEY,
		},
		Body = payload,
	})

	if not ok or type(response) ~= "table" then
		return false, 0, "License validation server unreachable."
	end

	local body = response.Body or response.body
	local decoded = self._http.JSONDecode(body)
	if not decoded or decoded.valid ~= true then
		local err = (decoded and decoded.error) or "Invalid license key."
		return false, 0, tostring(err)
	end

	local tiers = { Entry = 1, Normal = 2, Full = 3 }
	local resolvedTier = tiers[decoded.tier] or 0
	if resolvedTier == 0 then
		return false, 0, "License returned unrecognized access tier."
	end

	return true, resolvedTier, string.format("%s access granted.", decoded.tier), cleanKey
end

-- Save encrypted license token to disk
function AuthService:SaveKey(key)
	if not writefile then return false end
	local payload = self._http.JSONEncode({ Key = key, SavedAt = os.time() })
	if not payload then return false end
	
	local encrypted = self._crypto.Base64Encode(self._crypto.Xor(payload, STATIC_SALT))
	pcall(writefile, self:_getKeyPath(), encrypted)
	return true
end

-- Authenticate and store valid key
function AuthService:ApplyKey(key)
	local ok, tier, msg, canonical = self:Validate(key)
	if not ok then return false, 0, msg end

	self.CurrentKey = canonical
	self.CurrentTier = tier
	self:SaveKey(canonical)
	self.OnTierChanged:Fire(tier)
	return true, tier, msg
end

-- Reads and verifies cached key token from disk
function AuthService:LoadAndVerify()
	if not (readfile and isfile and isfile(self:_getKeyPath())) then
		return false, 0, "No saved key found."
	end

	local content = nil
	pcall(function() content = readfile(self:_getKeyPath()) end)
	if not content or content == "" then return false, 0, "Key cache empty." end

	local decrypted = self._crypto.Xor(self._crypto.Base64Decode(content), STATIC_SALT)
	local data = self._http.JSONDecode(decrypted) or self._http.JSONDecode(content)
	if not (data and data.Key) then
		return false, 0, "Corrupt key file format."
	end

	local ok, tier, msg, canonical = self:Validate(data.Key)
	if ok then
		self.CurrentKey = canonical
		self.CurrentTier = tier
		self.OnTierChanged:Fire(tier)
		return true, tier, msg
	end

	return false, 0, msg
end

-- Clear local license token
function AuthService:ClearKey()
	self.CurrentKey = ""
	self.CurrentTier = 0
	if delfile and isfile and isfile(self:_getKeyPath()) then
		pcall(delfile, self:_getKeyPath())
	end
	self.OnTierChanged:Fire(0)
end

function AuthService:GetTierName()
	local names = (self._constants and self._constants.TIER_NAMES) or {}
	return names[self.CurrentTier] or "No Access"
end

function AuthService:GetMaskedKey()
	if not self.CurrentKey or self.CurrentKey == "" then return "None" end
	return string.rep("•", 12)
end

function AuthService:Destroy()
	self.OnTierChanged:Destroy()
end

return AuthService
