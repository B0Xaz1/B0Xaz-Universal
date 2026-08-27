local HttpService = game:GetService("HttpService")

return function(services: any)
	local StateStore = services:Get("StateStore")
	local Environment = services:Get("Environment")
	local Disposer = services:Get("Disposer")
	local EventBus = services:Get("EventBus")

	local CONFIGS_FOLDER: string = "Configs"
	local AUTOLOAD_FILENAME: string = "_autoload"

	local ConfigService = {
		Dirty = false,
		_isLoading = false,
	}

	local function getFilePath(profileName: string): string
		-- Strip characters that are illegal in filenames so profiles map to
		-- one safe file each.
		local cleanName = profileName:gsub("[/\\%.:%*%?<>|%c\"]", "_")
		return string.format("%s/%s.json", CONFIGS_FOLDER, cleanName)
	end

	-- Color3 and Enum values are not JSON primitives, so they are wrapped in
	-- marker tables on the way out and rebuilt on the way in.
	local function sanitizeForSerialization(target: any): any
		local t = typeof(target)
		if t == "Color3" then
			return { __type = "Color3", r = target.R, g = target.G, b = target.B }
		elseif t == "EnumItem" then
			local enumName = tostring(target.EnumType):gsub("^Enum%.", "")
			return { __type = "EnumItem", enum = enumName, name = target.Name }
		elseif t == "table" then
			local out = {}
			for k, v in pairs(target) do
				out[k] = sanitizeForSerialization(v)
			end
			return out
		end
		return target
	end

	local function restoreFromSerialization(target: any): any
		if typeof(target) == "table" then
			if target.__type == "Color3" then
				return Color3.new(target.r or 1, target.g or 1, target.b or 1)
			elseif target.__type == "EnumItem" and target.name then
				local cleanEnum = tostring(target.enum or "KeyCode"):gsub("^Enum%.", "")
				local enumType = (Enum :: any)[cleanEnum]
				if enumType then
					local item = enumType[target.name]
					if item then return item end
				end
			end

			local out = {}
			for k, v in pairs(target) do
				out[k] = restoreFromSerialization(v)
			end
			return out
		end
		return target
	end

	function ConfigService:Save(profileName: string): (boolean, string?)
		if profileName:lower() == "default" then
			return false, "Cannot overwrite default snapshot"
		end

		local snapshot = StateStore:GetSettingsSnapshot()
		local sanitized = sanitizeForSerialization(snapshot)

		local ok, jsonString = pcall(HttpService.JSONEncode, HttpService, sanitized)
		if not ok then return false, "JSON encoding failure" end

		local writeOk, writeErr = Environment.WriteFile(getFilePath(profileName), jsonString)
		if writeOk then
			EventBus:Publish("ConfigSaved", profileName)
			return true, nil
		end
		return false, writeErr
	end

	function ConfigService:Load(profileName: string): (boolean, string?)
		self._isLoading = true

		if profileName:lower() == "default" then
			StateStore:LoadSettingsSnapshot(StateStore:GetDefaultSettings())
			self._isLoading = false
			self.Dirty = false
			EventBus:Publish("ConfigLoaded", "Default")
			return true, nil
		end

		local content = Environment.ReadFile(getFilePath(profileName))
		if not content then
			self._isLoading = false
			return false, "Config file not found"
		end

		local ok, data = pcall(HttpService.JSONDecode, HttpService, content)
		if not ok or typeof(data) ~= "table" then
			self._isLoading = false
			return false, "Invalid JSON data in file"
		end

		local restored = restoreFromSerialization(data)
		StateStore:LoadSettingsSnapshot(restored)
		self._isLoading = false
		self.Dirty = false
		EventBus:Publish("ConfigLoaded", profileName)
		return true, nil
	end

	function ConfigService:Delete(profileName: string): boolean
		if profileName:lower() == "default" or profileName == AUTOLOAD_FILENAME then
			return false
		end
		local deleted = Environment.DeleteFile(getFilePath(profileName))
		if deleted then
			EventBus:Publish("ConfigDeleted", profileName)
		end
		return deleted
	end

	function ConfigService:ListProfiles(): { string }
		local files = Environment.ListFiles(CONFIGS_FOLDER)
		local profiles = { "Default" }

		for _, path in ipairs(files) do
			local name = path:match("([^/\\]+)%.[jJ][sS][oO][nN]$")
			if name and name ~= AUTOLOAD_FILENAME and name:lower() ~= "default" then
				table.insert(profiles, name)
			end
		end
		table.sort(profiles)
		return profiles
	end

	function ConfigService:Export(): (boolean, string?)
		local snapshot = StateStore:GetSettingsSnapshot()
		local sanitized = sanitizeForSerialization(snapshot)
		local ok, jsonString = pcall(HttpService.JSONEncode, HttpService, sanitized)
		if ok then
			Environment.SetClipboard(jsonString)
			return true, jsonString
		end
		return false, "Failed to encode JSON"
	end

	function ConfigService:Import(rawJson: string): (boolean, string?)
		-- An empty payload falls back to whatever is on the clipboard
		local clean = rawJson
		if clean == "" then
			clean = Environment.GetClipboard() or ""
		end
		if clean == "" then return false, "No JSON payload provided" end

		local ok, data = pcall(HttpService.JSONDecode, HttpService, clean)
		if not ok or typeof(data) ~= "table" then return false, "Malformed JSON string" end

		self._isLoading = true
		local restored = restoreFromSerialization(data)
		StateStore:LoadSettingsSnapshot(restored)
		self._isLoading = false
		self.Dirty = true
		EventBus:Publish("ConfigImported")
		return true, nil
	end

	function ConfigService:LoadAutoload(): boolean
		local content = Environment.ReadFile(getFilePath(AUTOLOAD_FILENAME))
		if not content or content == "" then return false end

		local ok, data = pcall(HttpService.JSONDecode, HttpService, content)
		if ok and typeof(data) == "table" then
			self._isLoading = true
			StateStore:LoadSettingsSnapshot(restoreFromSerialization(data))
			self._isLoading = false
			self.Dirty = false
			return true
		end
		return false
	end

	function ConfigService:Initialize()
		-- Any state change marks the autoload dirty unless a load is in
		-- flight, which would otherwise save the load right back out.
		EventBus:Subscribe("StateChanged", function()
			if not self._isLoading then
				self.Dirty = true
			end
		end)

		Disposer:Spawn(function()
			while not Disposer.IsDisposed do
				task.wait(1.5)
				if self.Dirty and not self._isLoading then
					self.Dirty = false
					local snapshot = sanitizeForSerialization(StateStore:GetSettingsSnapshot())
					local encodeOk, jsonString = pcall(HttpService.JSONEncode, HttpService, snapshot)
					if encodeOk and typeof(jsonString) == "string" then
						local writeOk, writeErr = Environment.WriteFile(getFilePath(AUTOLOAD_FILENAME), jsonString)
						if not writeOk then
							warn("[ConfigService] Autosave failed: " .. tostring(writeErr))
						end
					else
						warn("[ConfigService] Autosave JSON encoding failed")
					end
				end
			end
		end)
	end

	return ConfigService
end
