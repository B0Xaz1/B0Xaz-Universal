-- ════════════════════════════════════════════════════════════════════════════
-- Services/ConfigService.lua
-- Observable configuration registry, profile I/O, and autosave daemon
-- ════════════════════════════════════════════════════════════════════════════

local ConfigService = {}
ConfigService.__index = ConfigService

local function deepCopy(tbl)
	if type(tbl) ~= "table" then return tbl end
	local out = {}
	for k, v in pairs(tbl) do
		out[k] = type(v) == "table" and deepCopy(v) or v
	end
	return out
end

function ConfigService.new()
	local self = setmetatable({}, ConfigService)
	self.Dirty = false
	self._isLoading = false
	return self
end

function ConfigService:Init(container)
	self._constants = container:Get("Constants")
	self._http = container:Get("HttpUtil")
	self._signalClass = container:Get("Signal")
	
	self.Data = deepCopy(self._constants.DEFAULT_CONFIG)
	self.OnConfigChanged = self._signalClass.new()
	self.OnProfileLoaded = self._signalClass.new()
end

function ConfigService:_getPath(name)
	local folder = self._constants.FOLDER or "B0XazUniversal"
	local ext = self._constants.CONFIG_EXT or ".json"
	return string.format("%s/%s%s", folder, name, ext)
end

-- Get configuration entry via dot notation path (e.g. "Movement.Speed")
function ConfigService:Get(path)
	local cur = self.Data
	for segment in path:gmatch("[^%.]+") do
		if cur == nil then return nil end
		cur = cur[segment]
	end
	return cur
end

-- Set configuration entry with dirty-checking and signal dispatch
function ConfigService:Set(path, value, silent)
	local keys = {}
	for segment in path:gmatch("[^%.]+") do
		table.insert(keys, segment)
	end

	local cur = self.Data
	for i = 1, #keys - 1 do
		if cur[keys[i]] == nil then cur[keys[i]] = {} end
		cur = cur[keys[i]]
	end

	local lastKey = keys[#keys]
	if cur[lastKey] == value then return end

	cur[lastKey] = value
	if not self._isLoading then
		self.Dirty = true
		if not silent then
			self.OnConfigChanged:Fire(path, value)
		end
	end
end

-- Save active configuration into a named profile
function ConfigService:SaveProfile(name)
	if not name or #name == 0 or name:lower() == "default" then 
		return false, "Invalid profile name" 
	end
	if not writefile then return false, "writefile unavailable" end

	local encoded = self._http.JSONEncode(self.Data)
	if not encoded then return false, "JSON serialization failed" end

	local ok = pcall(writefile, self:_getPath(name), encoded)
	return ok, ok and "Profile saved successfully" or "File write failed"
end

-- Load named profile into memory
function ConfigService:LoadProfile(name)
	if name == "Default" then
		self.Data = deepCopy(self._constants.DEFAULT_CONFIG)
		self.Dirty = false
		self.OnProfileLoaded:Fire("Default")
		return true
	end

	if not (readfile and isfile and isfile(self:_getPath(name))) then
		return false, "Profile file not found"
	end

	local content = nil
	pcall(function() content = readfile(self:_getPath(name)) end)
	local decoded = self._http.JSONDecode(content)
	if not decoded or type(decoded) ~= "table" then
		return false, "Failed to parse profile JSON"
	end

	self._isLoading = true
	self.Data = deepCopy(self._constants.DEFAULT_CONFIG)
	for k, v in pairs(decoded) do
		self.Data[k] = v
	end
	self._isLoading = false
	self.Dirty = false
	self.OnProfileLoaded:Fire(name)
	return true
end

-- Enumerate saved profiles on disk
function ConfigService:GetSavedProfiles()
	local names = { "Default" }
	if not listfiles then return names end

	local folder = self._constants.FOLDER or "B0XazUniversal"
	local files = {}
	pcall(function() files = listfiles(folder) end)

	for _, file in ipairs(files) do
		local fileName = file:gsub("^.*[/\\]", "")
		local base = fileName:match("^(.-)%.[jJ][sS][oO][nN]$")
		if base and base ~= "" and base:sub(1, 1) ~= "_" and base:lower() ~= "default" then
			table.insert(names, base)
		end
	end
	return names
end

-- Export configuration to clipboard
function ConfigService:Export()
	local encoded = self._http.JSONEncode(self.Data)
	if encoded and setclipboard then
		pcall(setclipboard, encoded)
	end
	return encoded
end

-- Import configuration from JSON string
function ConfigService:Import(rawJson)
	local decoded = self._http.JSONDecode(rawJson)
	if not decoded or type(decoded) ~= "table" then
		return false, "Invalid JSON data"
	end

	self._isLoading = true
	self.Data = deepCopy(self._constants.DEFAULT_CONFIG)
	for k, v in pairs(decoded) do self.Data[k] = v end
	self._isLoading = false
	self.Dirty = true
	self.OnProfileLoaded:Fire("Imported")
	return true
end

-- Start background autosave daemon
function ConfigService:StartAutosave(interval)
	task.spawn(function()
		while true do
			task.wait(interval or 2.0)
			if self.Dirty and not self._isLoading and writefile then
				self.Dirty = false
				local encoded = self._http.JSONEncode(self.Data)
				if encoded then
					pcall(writefile, self:_getPath(self._constants.AUTOLOAD_FILE or "_autoload"), encoded)
				end
			end
		end
	end)
end

function ConfigService:Destroy()
	self.OnConfigChanged:Destroy()
	self.OnProfileLoaded:Destroy()
end

return ConfigService
