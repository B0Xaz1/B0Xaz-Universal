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
	-- Change this word whenever you want to change the key for everyone.
	local MASTER_KEY = "Main Access" 

	-- Since there is no website, this message shows when they click "Get Key"
	local KEY_INFO_MESSAGE = "This is a private script. Please ask the owner for the key."

	KeySystem.CurrentTier = 0
	KeySystem.CurrentKey = ""
	local KEY_FILE = tostring(CONFIG.FOLDER or "B0XazUniversal") .. "/_key.json"

	local function trim(s)
		return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
	end

	-- Local HWID for saving the key to this specific computer
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

	function KeySystem.Validate(userInput)
		userInput = trim(userInput)
		
		if userInput == "" then 
			return false, 0, "Key cannot be empty." 
		end

		-- Check the input against your hardcoded Master Key
		if userInput == MASTER_KEY then
			KeySystem.CurrentTier = 3 -- Full Access
			return true, 3, "Access Granted!", userInput
		else
			return false, 0, "Incorrect Key. Access Denied."
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

		-- Check if the saved key was for this computer
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
		-- Since there is no link, we just notify them
		setclipboard(KEY_INFO_MESSAGE)
		return true, "Information copied to clipboard."
	end

	return KeySystem
end
