-- // init.lua (Main Loader)
local SETTINGS = {
	PATHS = {
		CONFIG = "src/Config.lua",
		CLEANUP = "src/Cleanup.lua",
		UTILS = "src/Utils.lua",
		DRAWING_MANAGER = "src/Visuals/DrawingManager.lua",
		CONTEXT = "src/Context.lua",
		THEME = "src/UI/Theme.lua",
		UI_ENGINE = "src/UI/UI.lua",
		KEY_SYSTEM = "src/Systems/KeySystem.lua",
		CONFIG_SYSTEM = "src/Systems/ConfigSystem.lua",
		AIMBOT_SYSTEM = "src/Systems/AimbotSystem.lua",
		ESP_SYSTEM = "src/Systems/ESPSystem.lua",
		FLING_SYSTEM = "src/Systems/FlingSystem.lua",
		FLY_SYSTEM = "src/Systems/FlySystem.lua",
		MOVEMENT_SYSTEM = "src/Systems/MovementSystem.lua",
		PERFORMANCE_SYSTEM = "src/Systems/PerformanceSystem.lua",
		PLAYERS_SYSTEM = "src/Systems/PlayersSystem.lua",
		OVERLAY_MANAGER = "src/Visuals/OverlayManager.lua",
		GAME_LOADER = "src/Games/Loader.lua",
		BUILD_UI = "src/UI/BuildUI.lua",
		RUNTIME = "src/Runtime.lua",
	},
	DEFAULTS = {
		BASE_URL = "https://raw.githubusercontent.com/B0Xaz1/B0Xaz-Universal/main/",
		LOAD_TIMEOUT = 10,
		RETRY_ATTEMPTS = 2,
	},
}

print("[B0Xaz] Initializing Universal Suite from GitHub...")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

if not LocalPlayer then
	local startTime = os.clock()
	while not Players.LocalPlayer and (os.clock() - startTime) < SETTINGS.DEFAULTS.LOAD_TIMEOUT do
		task.wait(0.1)
	end
	LocalPlayer = Players.LocalPlayer
end

if not game:IsLoaded() then
	pcall(function()
		game.Loaded:Wait()
	end)
end

local globalEnv = getgenv and getgenv() or _G
local moduleCache = {}

local function isValidSource(code)
	if type(code) ~= "string" or #code < 5 then
		return false
	end
	local lower = code:lower()
	if lower:sub(1, 3) == "404" or lower:find("not found") or lower:find("<!doctype") or lower:find("<html") then
		return false
	end
	return true
end

local function fetchSource(path)
	local baseUrl = globalEnv.B0XazBaseURL or SETTINGS.DEFAULTS.BASE_URL
	local cleanPath = path:gsub("^%./", ""):gsub("^/", "")
	local fullUrl = baseUrl .. cleanPath

	for attempt = 1, SETTINGS.DEFAULTS.RETRY_ATTEMPTS do
		local success, response = pcall(function()
			return game:HttpGet(fullUrl)
		end)
		if success and isValidSource(response) then
			return response
		end
		task.wait(0.2)
	end

	warn("[B0Xaz] Failed to fetch module from GitHub (404 / Unreachable): " .. fullUrl)
	return nil
end

local function import(path)
	if moduleCache[path] ~= nil then
		return moduleCache[path]
	end

	local sourceCode = fetchSource(path)
	if not sourceCode then
		moduleCache[path] = false
		return nil
	end

	local loaderFn, compileErr = loadstring(sourceCode, "=" .. path)
	if not loaderFn then
		warn("[B0Xaz] Syntax error compiling module " .. tostring(path) .. ": " .. tostring(compileErr))
		moduleCache[path] = false
		return nil
	end

	local runSuccess, moduleResult = pcall(loaderFn)
	if not runSuccess then
		warn("[B0Xaz] Runtime error executing module " .. tostring(path) .. ": " .. tostring(moduleResult))
		moduleCache[path] = false
		return nil
	end

	print("[B0Xaz] Successfully imported: " .. tostring(path))
	moduleCache[path] = moduleResult
	return moduleResult
end

-- 1. Execute Cleanup
local cleanupFn = import(SETTINGS.PATHS.CLEANUP)
if type(cleanupFn) == "function" then
	pcall(cleanupFn)
end

-- 2. Load Config & Utils
local configFn = import(SETTINGS.PATHS.CONFIG)
local configData, defaultLighting = {}, {}
if type(configFn) == "function" then
	local success, cfg, lighting = pcall(configFn)
	if success then
		configData = cfg or {}
		defaultLighting = lighting or {}
	end
end

local utilsFn = import(SETTINGS.PATHS.UTILS)
local utils = type(utilsFn) == "function" and utilsFn(configData) or {}

if type(utils.WaitForGameLoad) == "function" then
	pcall(utils.WaitForGameLoad, SETTINGS.DEFAULTS.LOAD_TIMEOUT)
end

-- 3. Load Drawing Manager & Core Context
local drawingMgrFn = import(SETTINGS.PATHS.DRAWING_MANAGER)
local drawingManager = type(drawingMgrFn) == "function" and drawingMgrFn() or {}

local contextFn = import(SETTINGS.PATHS.CONTEXT)
local context = type(contextFn) == "function" and contextFn(configData, defaultLighting, utils, drawingManager) or {}
context.import = import

-- 4. Load UI Engine & Theme
local themeFn = import(SETTINGS.PATHS.THEME)
local activeTheme, themeManager = {}, {}
if type(themeFn) == "function" then
	local success, th, thMgr = pcall(themeFn)
	if success then
		activeTheme = th or {}
		themeManager = thMgr or {}
	end
end
context.Theme = activeTheme
context.ThemeManager = themeManager

local uiEngineFn = import(SETTINGS.PATHS.UI_ENGINE)
local uiEngine = type(uiEngineFn) == "function" and uiEngineFn(context, activeTheme) or {}
context.UIEngine = uiEngine

-- 5. Load Systems
local keySysFn = import(SETTINGS.PATHS.KEY_SYSTEM)
local keySystem = type(keySysFn) == "function" and keySysFn(context, import) or {}
context.KeySystem = keySystem

local configSysFn = import(SETTINGS.PATHS.CONFIG_SYSTEM)
local configSystem = type(configSysFn) == "function" and configSysFn(context) or {}
context.ConfigSystem = configSystem

local aimbotSysFn = import(SETTINGS.PATHS.AIMBOT_SYSTEM)
local aimbotSystem = type(aimbotSysFn) == "function" and aimbotSysFn(context) or {}
context.AimbotSystem = aimbotSystem

local espSysFn = import(SETTINGS.PATHS.ESP_SYSTEM)
local espSystem = type(espSysFn) == "function" and espSysFn(context) or {}
context.ESPSystem = espSystem

local flingSysFn = import(SETTINGS.PATHS.FLING_SYSTEM)
local flingSystem = type(flingSysFn) == "function" and flingSysFn(context) or {}
context.FlingSystem = flingSystem

local flySysFn = import(SETTINGS.PATHS.FLY_SYSTEM)
local flySystem = type(flySysFn) == "function" and flySysFn(context) or {}
context.FlySystem = flySystem

local moveSysFn = import(SETTINGS.PATHS.MOVEMENT_SYSTEM)
local movementSystem = type(moveSysFn) == "function" and moveSysFn(context) or {}
context.MovementSystem = movementSystem

local perfSysFn = import(SETTINGS.PATHS.PERFORMANCE_SYSTEM)
local performanceSystem = type(perfSysFn) == "function" and perfSysFn(context) or {}
context.PerformanceSystem = performanceSystem

local playersSysFn = import(SETTINGS.PATHS.PLAYERS_SYSTEM)
local playersSystem = type(playersSysFn) == "function" and playersSysFn(context) or {}
context.PlayersSystem = playersSystem

local overlayMgrFn = import(SETTINGS.PATHS.OVERLAY_MANAGER)
local overlayManager = type(overlayMgrFn) == "function" and overlayMgrFn(context) or {}
context.OverlayManager = overlayManager

local gameLoaderFn = import(SETTINGS.PATHS.GAME_LOADER)
local gameLoader = type(gameLoaderFn) == "function" and gameLoaderFn(context, import) or {}
context.GameLoader = gameLoader

globalEnv.B0XazContext = context

-- Main Start Sequence
local function startApplication()
	print("[B0Xaz] Launching systems and UI...")

	if gameLoader and type(gameLoader.Load) == "function" then
		pcall(gameLoader.Load)
	end

	if espSystem and type(espSystem.InitializeAll) == "function" then
		pcall(espSystem.InitializeAll)
	end

	if configSystem and type(configSystem.LoadAutoload) == "function" then
		pcall(configSystem.LoadAutoload)
	end

	if configSystem and type(configSystem.StartAutosaveLoop) == "function" then
		pcall(configSystem.StartAutosaveLoop)
	end

	local buildUiFn = import(SETTINGS.PATHS.BUILD_UI)
	if type(buildUiFn) == "function" then
		local success, err = pcall(buildUiFn, context)
		if not success then
			warn("[B0Xaz] BuildUI execution error: " .. tostring(err))
		end
	else
		warn("[B0Xaz] BuildUI module could not be loaded.")
	end

	local runtimeFn = import(SETTINGS.PATHS.RUNTIME)
	if type(runtimeFn) == "function" then
		local success, err = pcall(runtimeFn, context)
		if not success then
			warn("[B0Xaz] Runtime execution error: " .. tostring(err))
		end
	end

	print("[B0Xaz] Successfully loaded and active!")
end

-- Key Authentication Verification
local isVerified, verifyMsg = false, ""
if keySystem and type(keySystem.LoadAndVerify) == "function" then
	local success, verified, _, msg = pcall(keySystem.LoadAndVerify)
	if success then
		isVerified = verified
		verifyMsg = msg or ""
	end
end

if isVerified then
	print("[B0Xaz] Saved license key verified (Tier: " .. tostring(keySystem.GetTierName()) .. ")")
	startApplication()
else
	print("[B0Xaz] Prompting for key authentication...")
	local promptCreated = false
	if uiEngine and type(uiEngine.CreateKeyPrompt) == "function" then
		local success, err = pcall(function()
			uiEngine.CreateKeyPrompt(nil, keySystem, activeTheme, startApplication, verifyMsg)
		end)
		if not success then
			warn("[B0Xaz] Failed to create Key Prompt: " .. tostring(err))
		else
			promptCreated = true
		end
	end
	if not promptCreated then
		warn("[B0Xaz] Key prompt window unavailable, starting default UI...")
		startApplication()
	end
end
