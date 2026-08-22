-- src/Systems/KeySystem.lua
return function(Context)
	local KeySystem = {}
	local HttpService = game:GetService("HttpService")
	local Players = game:GetService("Players")
	local Utils = Context.Utils
	local CONFIG = Context.CONFIG

	----------------------------------------------------------------
	-- PLATOBOOST (Free plan = 1 service)
	----------------------------------------------------------------
	-- Service ID from Platoboost top-right: (ID: 30171)
	KeySystem.SERVICE_ID = "30171"

	-- Platoboost Loader/Gateway link (this is what users open to get a key)
	KeySystem.GET_KEY_URL = "https://platoboost.com/loader/30171"

	-- Optional exact overrides (always checked after Platoboost says valid)
	local EXACT_TIER_OVERRIDES = {
		--["FULL-myfriend1"] = 3,
	}

	local TIER_NAMES = {
		[0] = "No Access",
		[1] = "Entry Tier",
		[2] = "Normal Tier",
		[3] = "Full Access",
	}

	KeySystem.CurrentTier = 0
	KeySystem.CurrentKey = ""

	local KEY_FILE = tostring(CONFIG.FOLDER or "B0XazUniversal") .. "/_key.json"

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

	local function httpGet(url)
		local requestFn = (syn and syn.request)
			or (http and http.request)
			or http_request
			or request
			or (fluxus and fluxus.request)

		if requestFn then
			local ok, res = pcall(function()
				return requestFn({
					Url = url,
					Method = "GET",
					Headers = {
						["User-Agent"] = "B0Xaz-Universal",
						["Content-Type"] = "application/json",
					},
				})
			end)
			if ok and res then
				local body = res.Body or res.body
				local code = res.StatusCode or res.status_code or 200
				if code == 200 and body then
					return body
				end
			end
		end

		local ok2, body2 = pcall(function()
			return game:HttpGet(url)
		end)
		if ok2 then
			return body2
		end
		return nil
	end

	local function platoboostVerify(serviceId, key)
		local hwid = getHWID()

		-- Try primary host first, fall back to .net if .com fails
		local hosts = {
			"https://api.platoboost.com",
			"https://api.platoboost.net"
		}

		local body = nil

		for _, host in ipairs(hosts) do
			local url = string.format(
				"%s/public/whitelist/%s?identifier=%s&key=%s",
				host,
				HttpService:UrlEncode(tostring(serviceId)),
				HttpService:UrlEncode(tostring(hwid)),
				HttpService:UrlEncode(tostring(key))
			)

			body = httpGet(url)
			if body then break end
		end

		if not body then
			return false, "Could not reach Platoboost API."
		end

		local ok, data = pcall(function()
			return HttpService:JSONDecode(body)
		end)
		if not ok or type(data) ~= "table" then
			return false, "Invalid Platoboost response."
		end

		if data.success == true and data.data and data.data.valid == true then
			return true, "Authenticated Successfully!"
		end

		return false, data.message or data.error or "Invalid or expired key."
	end

	local function resolveTier(key)
		local upper = key:upper()

		if EXACT_TIER_OVERRIDES[key] then
			return EXACT_TIER_OVERRIDES[key]
		end
		if EXACT_TIER_OVERRIDES[upper] then
			return EXACT_TIER_OVERRIDES[upper]
		end

		-- Full Access
		if upper:sub(1, 5) == "FULL-"
			or upper:sub(1, 5) == "FULL_"
			or upper:find("B0XAZ%-FULL", 1, false)
			or upper:find("FULLACCESS", 1, true)
		then
			return 3
		end

		-- Normal
		if upper:sub(1, 5) == "NORM-"
			or upper:sub(1, 5) == "NORM_"
			or upper:find("B0XAZ%-NORM", 1, false)
			or upper:find("NORMAL", 1, true)
		then
			return 2
		end

		-- Standard Platoboost link keys = Entry
		return 1
	end

	function KeySystem.GetTierName(tier)
		return TIER_NAMES[tier or KeySystem.CurrentTier] or "Unknown"
	end

	function KeySystem.HasTier(req)
		req = tonumber(req) or 1
		return (tonumber(KeySystem.CurrentTier) or 0) >= req
	end

	function KeySystem.Validate(key)
		key = trim(key)
		if key == "" then
			return false, 0, "Key cannot be empty."
		end

		if not KeySystem.SERVICE_ID or KeySystem.SERVICE_ID == "" then
			return false, 0, "Service ID is not configured."
		end

		local ok, msg = platoboostVerify(KeySystem.SERVICE_ID, key)
		if not ok then
			return false, 0, msg or "Invalid or expired key."
		end

		local tier = resolveTier(key)
		return true, tier, "Authenticated: " .. KeySystem.GetTierName(tier), key
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
			return false, "Failed to encode key."
		end
		return Utils.WriteFile(KEY_FILE, encoded)
	end

	function KeySystem.ApplyKey(key)
		local ok, tier, msg, canonical = KeySystem.Validate(key)
		if not ok then
			return false, 0, msg
		end

		KeySystem.CurrentKey = canonical or trim(key)
		KeySystem.CurrentTier = tier
		KeySystem.SaveKey(KeySystem.CurrentKey)
		return true, tier, msg
	end

	function KeySystem.LoadAndVerify()
		if Utils.MakeFolder then
			Utils.MakeFolder(CONFIG.FOLDER)
		end

		local content = Utils.ReadFile(KEY_FILE)
		if not content or content == "" then
			return false, 0, ""
		end

		local ok, data = pcall(function()
			return HttpService:JSONDecode(content)
		end)
		if not ok or type(data) ~= "table" or not data.Key then
			return false, 0, "Corrupted saved key file."
		end

		-- Optional local HWID check (Platoboost also binds keys server-side)
		if data.HWID and data.HWID ~= "" then
			local current = getHWID()
			if tostring(data.HWID) ~= tostring(current) then
				return false, 0, "HWID mismatch. This key was saved on another device."
			end
		end

		local valid, tier, msg, canonical = KeySystem.Validate(data.Key)
		if not valid then
			return false, 0, msg or "Saved key is no longer valid."
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
			return string.rep("*", math.max(4, #k))
		end
		return k:sub(1, 4) .. string.rep("*", 6) .. k:sub(-4)
	end

	function KeySystem.CopyGetKeyLink()
		local link = KeySystem.GET_KEY_URL or ""
		if link == "" or link:find("YOUR_GATEWAY") then
			return false, "Get-key link not configured yet."
		end
		local ok = pcall(function()
			setclipboard(link)
		end)
		return ok, ok and "Link copied." or "Clipboard unavailable."
	end

	return KeySystem
end
