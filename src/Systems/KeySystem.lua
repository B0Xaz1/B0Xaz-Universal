-- src/Systems/KeySystem.lua
return function(Context)
	local KeySystem = {}
	local HttpService = game:GetService("HttpService")
	local Players = game:GetService("Players")
	local Utils = Context.Utils
	local CONFIG = Context.CONFIG

	----------------------------------------------------------------
	-- OFFLINE KEY CONFIGURATION
	----------------------------------------------------------------
	local MASTER_KEY = "Main Access"
	local KEY_INFO_MESSAGE = "This script uses a direct key. Contact the administrator to obtain access."

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
			hwid = tostring(Players.LocalPlayer.UserId)
		end
		return hwid
	end

	function KeySystem.GetTierName()
		if KeySystem.CurrentTier == 3 then
			return "Tier 3 (Full Access)"
		elseif KeySystem.CurrentTier == 2 then
			return "Tier 2 (Enhanced)"
		elseif KeySystem.CurrentTier == 1 then
			return "Tier 1 (Standard)"
		else
			return "None"
		end
	end

	function KeySystem.GetMaskedKey()
		if not KeySystem.CurrentKey or KeySystem.CurrentKey == "" then
			return "None"
		end
		if #KeySystem.CurrentKey <= 4 then
			return string.rep("*", #KeySystem.CurrentKey)
		end
		return KeySystem.CurrentKey:sub(1, 2) .. string.rep("*", #KeySystem.CurrentKey - 4) .. KeySystem.CurrentKey:sub(-2)
	end

	function KeySystem.Validate(userInput)
		userInput = trim(userInput)

		if userInput == "" then 
			return false, 0, "Key cannot be empty." 
		end

		if userInput == MASTER_KEY then
			KeySystem.CurrentTier = 3
			return true, 3, "Access Granted!", userInput
		else
			return false, 0, "Incorrect key. Access denied."
		end
	end

	function KeySystem.SaveKey(key)
		local data = {
			Key = key,
			HWID = getHWID(),
			SavedAt = os.time()
		}
		local ok, encoded = pcall(function() return HttpService:JSONEncode(data) end)
		if ok then 
			return Utils.WriteFile(KEY_FILE, encoded) 
		end
	end

	function KeySystem.ApplyKey(key)
		local ok, tier, msg, canonical = KeySystem.Validate(key)
		if not ok then return false, 0, msg end

		KeySystem.CurrentKey = canonical
		KeySystem.SaveKey(KeySystem.CurrentKey)
		return true, tier, msg
	end

	function KeySystem.LoadAndVerify()
		local content = Utils.ReadFile(KEY_FILE)
		if not content or content == "" then return false, 0, "" end

		local ok, data = pcall(function() return HttpService:JSONDecode(content) end)
		if not ok or not data.Key then return false, 0, "" end

		if data.HWID and data.HWID ~= getHWID() then
			return false, 0, "Key saved on a different device."
		end

		return KeySystem.Validate(data.Key)
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

	function KeySystem.CopyGetKeyLink()
		pcall(function()
			setclipboard(KEY_INFO_MESSAGE)
		end)
		return true, "Key instructions copied to clipboard."
	end

	return KeySystem
end
