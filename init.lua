-- // init.lua (Main Loader)
local BASE_URL = "https://raw.githubusercontent.com/B0Xaz1/B0Xaz-Universal/main/"
local LOAD_TIMEOUT = 10

local PATHS = {
	CONFIG             = "src/Config.lua",
	CLEANUP            = "src/Cleanup.lua",
	UTILS              = "src/Utils.lua",
	DRAWING_MANAGER    = "src/Visuals/DrawingManager.lua",
	CONTEXT            = "src/Context.lua",
	THEME              = "src/UI/Theme.lua",
	UI_ENGINE          = "src/UI/UI.lua",
	KEY_SYSTEM         = "src/Systems/KeySystem.lua",
	CONFIG_SYSTEM      = "src/Systems/ConfigSystem.lua",
	AIMBOT_SYSTEM      = "src/Systems/AimbotSystem.lua",
	ESP_SYSTEM         = "src/Systems/ESPSystem.lua",
	FLING_SYSTEM       = "src/Systems/FlingSystem.lua",
	FLY_SYSTEM         = "src/Systems/FlySystem.lua",
	MOVEMENT_SYSTEM    = "src/Systems/MovementSystem.lua",
	PERFORMANCE_SYSTEM = "src/Systems/PerformanceSystem.lua",
	PLAYERS_SYSTEM     = "src/Systems/PlayersSystem.lua",
	OVERLAY_MANAGER    = "src/Visuals/OverlayManager.lua",
	GAME_LOADER        = "src/Games/Loader.lua",
	BUILD_UI           = "src/UI/BuildUI.lua",
	RUNTIME            = "src/Runtime.lua",
}

print("[B0Xaz] Initializing Universal Suite...")

local Players = game:GetService("Players")

if not game:IsLoaded() then
	pcall(function() game.Loaded:Wait() end)
end

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
	local startTime = os.clock()
	while not Players.LocalPlayer and (os.clock() - startTime) < LOAD_TIMEOUT do
		task.wait(0.1)
	end
	LocalPlayer = Players.LocalPlayer
end

local globalEnv = (getgenv and getgenv()) or _G
local moduleCache = {}

-- ============================================================
-- GitHub Fetching with Case-Variant Fallbacks
-- ============================================================
local function isValidSource(code)
	if type(code) ~= "string" or #code < 5 then return false end
	local lower = code:lower()
	if lower:sub(1, 3) == "404"
		or lower:find("not found", 1, true)
		or lower:find("<!doctype", 1, true)
		or lower:find("<html", 1, true) then
		return false
	end
	return true
end

local function generatePathVariants(path)
	local cleanPath = path:gsub("^%./", ""):gsub("^/", "")
	local variants = { cleanPath }
	local folder, filename = cleanPath:match("^(.-)/([^/]+)$")

	if folder and filename then
		table.insert(variants, folder:lower() .. "/" .. filename)
		table.insert(variants, folder .. "/" .. filename:lower())
		table.insert(variants, folder:lower() .. "/" .. filename:lower())
		table.insert(variants, filename)
	end

	return variants
end

local function fetchSource(path)
	local baseUrl = globalEnv.B0XazBaseURL or BASE_URL
	local cacheBust = "?t=" .. tostring(os.time())
	local variants = generatePathVariants(path)

	for _, variant in ipairs(variants) do
		local fullUrl = baseUrl .. variant .. cacheBust
		local success, response = pcall(function()
			return game:HttpGet(fullUrl)
		end)
		if success and isValidSource(response) then
			return response
		end
	end
	return nil
end

-- Inline emergency fallbacks in case GitHub HTTP fails completely
local EMERGENCY_FALLBACKS = {
	["src/Systems/ConfigSystem.lua"] = function()
		return function(Context)
			local ConfigSystem = { Dirty = false, AutoloadFile = "_autoload", DefaultSnapshot = nil }
			function ConfigSystem.NotifyChange() ConfigSystem.Dirty = true end
			function ConfigSystem.Serialize() return {} end
			function ConfigSystem.Deserialize() end
			function ConfigSystem.UpdateUI() end
			function ConfigSystem.GetSavedNames() return { "Default" } end
			function ConfigSystem.Save() return true end
			function ConfigSystem.Load() return true end
			function ConfigSystem.Delete() return true end
			function ConfigSystem.LoadAutoload() return false end
			function ConfigSystem.StartAutosaveLoop() end
			return ConfigSystem
		end
	end,
	["src/Games/Loader.lua"] = function()
		return function(Context)
			local Loader = { PlaceId = tostring(game.PlaceId), Supported = true }
			function Loader.GetDisplayName() return "Universal" end
			function Loader.IsSupported() return true end
			function Loader.Load() return nil end
			function Loader.BuildUI() return true end
			function Loader.Update() end
			function Loader.Destroy() end
			return Loader
		end
	end
}

local function import(path, isOptional)
	if moduleCache[path] ~= nil then
		return moduleCache[path] or nil
	end

	local source = fetchSource(path)
	local resolved = nil

	if source then
		local loaderFn, compileErr = loadstring(source, "=" .. path)
		if loaderFn then
			local ok, result = pcall(loaderFn)
			if ok then
				resolved = result
			else
				warn("[B0Xaz] Runtime error in " .. path .. ": " .. tostring(result))
			end
		else
			warn("[B0Xaz] Syntax error in " .. path .. ": " .. tostring(compileErr))
		end
	end

	-- Use emergency fallback if fetch or loadstring failed
	if resolved == nil and EMERGENCY_FALLBACKS[path] then
		warn("[B0Xaz] Using emergency fallback for: " .. path)
		local ok, fallbackFn = pcall(EMERGENCY_FALLBACKS[path])
		if ok then resolved = fallbackFn end
	end

	if resolved ~= nil then
		print("[B0Xaz] Loaded: " .. path)
		moduleCache[path] = resolved
		return resolved
	end

	moduleCache[path] = false
	if not isOptional then
		warn("[B0Xaz] Failed to load required module: " .. tostring(path))
	end
	return nil
end

-- ============================================================
-- Bootstrap Sequence
-- ============================================================

-- 1. Cleanup previous session
local cleanupFn = import(PATHS.CLEANUP)
if type(cleanupFn) == "function" then pcall(cleanupFn) end

-- 2. Config & Lighting snapshot
local configFn = import(PATHS.CONFIG)
local configData, defaultLighting = {}, {}
if type(configFn) == "function" then
	local ok, cfg, lighting = pcall(configFn)
	if ok then
		configData = cfg or {}
		defaultLighting = lighting or {}
	end
end

-- 3. Utils
local utilsFn = import(PATHS.UTILS)
local utils = (type(utilsFn) == "function" and utilsFn(configData)) or {}
if type(utils.WaitForGameLoad) == "function" then
	pcall(utils.WaitForGameLoad, LOAD_TIMEOUT)
end

-- 4. Drawing Manager
local drawingMgrFn = import(PATHS.DRAWING_MANAGER)
local drawingManager = (type(drawingMgrFn) == "function" and drawingMgrFn()) or { Available = false }

-- 5. Context
local contextFn = import(PATHS.CONTEXT)
local context = (type(contextFn) == "function" and contextFn(configData, defaultLighting, utils, drawingManager)) or {}
context.import = import

-- 6. Theme
local themeFn = import(PATHS.THEME)
local activeTheme, themeManager = {}, {}
if type(themeFn) == "function" then
	local ok, th, thMgr = pcall(themeFn)
	if ok then
		activeTheme = th or {}
		themeManager = thMgr or {}
	end
end
context.Theme = activeTheme
context.ThemeManager = themeManager

-- 7. UI Engine
local uiEngineFn = import(PATHS.UI_ENGINE)
local uiEngine = (type(uiEngineFn) == "function" and uiEngineFn(context, activeTheme)) or {}
context.UIEngine = uiEngine

-- 8. Key System
local keySysFn = import(PATHS.KEY_SYSTEM)
local keySystem = (type(keySysFn) == "function" and keySysFn(context, import)) or {}
context.KeySystem = keySystem

-- 9. Systems
local function safeInit(fn)
	if type(fn) ~= "function" then return {} end
	local ok, result = pcall(fn, context)
	if ok and type(result) == "table" then
		return result
	end
	return {}
end

context.ConfigSystem      = safeInit(import(PATHS.CONFIG_SYSTEM))
context.AimbotSystem      = safeInit(import(PATHS.AIMBOT_SYSTEM))
context.ESPSystem         = safeInit(import(PATHS.ESP_SYSTEM))
context.FlingSystem       = safeInit(import(PATHS.FLING_SYSTEM))
context.FlySystem         = safeInit(import(PATHS.FLY_SYSTEM))
context.MovementSystem    = safeInit(import(PATHS.MOVEMENT_SYSTEM))
context.PerformanceSystem = safeInit(import(PATHS.PERFORMANCE_SYSTEM))
context.PlayersSystem     = safeInit(import(PATHS.PLAYERS_SYSTEM))
context.OverlayManager    = safeInit(import(PATHS.OVERLAY_MANAGER))

-- 10. Game Loader
local gameLoaderFactory = import(PATHS.GAME_LOADER)
if type(gameLoaderFactory) == "function" then
	local ok, res = pcall(gameLoaderFactory, context, import)
	if ok and type(res) == "table" then
		context.GameLoader = res
	end
end

globalEnv.B0XazContext = context

-- ============================================================
-- Launcher
-- ============================================================
local function startApplication()
	print("[B0Xaz] Launching UI & runtime...")

	if context.ESPSystem and context.ESPSystem.InitializeAll then
		pcall(context.ESPSystem.InitializeAll)
	end

	if context.ConfigSystem and context.ConfigSystem.LoadAutoload then
		pcall(context.ConfigSystem.LoadAutoload)
	end

	if context.ConfigSystem and context.ConfigSystem.StartAutosaveLoop then
		pcall(context.ConfigSystem.StartAutosaveLoop)
	end

	local buildUiFn = import(PATHS.BUILD_UI)
	if type(buildUiFn) == "function" then
		local ok, err = pcall(buildUiFn, context)
		if not ok then
			warn("[B0Xaz] BuildUI error: " .. tostring(err))
		end
	end

	local runtimeFn = import(PATHS.RUNTIME)
	if type(runtimeFn) == "function" then
		local ok, err = pcall(runtimeFn, context)
		if not ok then
			warn("[B0Xaz] Runtime error: " .. tostring(err))
		end
	end

	print("[B0Xaz] Universal Hub loaded.")
end

-- Key verification
local verified = false
if keySystem and keySystem.LoadAndVerify then
	local ok, result = pcall(keySystem.LoadAndVerify)
	verified = ok and result == true
end

if verified then
	startApplication()
elseif uiEngine and type(uiEngine.CreateKeyPrompt) == "function" then
	local ok, err = pcall(uiEngine.CreateKeyPrompt, uiEngine, keySystem, activeTheme, startApplication, "")
	if not ok then
		warn("[B0Xaz] Key prompt error: " .. tostring(err) .. " — launching anyway.")
		startApplication()
	end
else
	startApplication()
end
