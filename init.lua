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
	pcall(function() game.Loaded:Wait() end)
end

local globalEnv = getgenv and getgenv() or _G
local moduleCache = {}

local function isValidSource(code)
	if type(code) ~= "string" or #code < 5 then return false end
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

	warn("[B0Xaz] Failed to fetch module (404/Case Sensitivity?): " .. path)
	return nil
end

local function import(path)
	if moduleCache[path] ~= nil then return moduleCache[path] end
	local sourceCode = fetchSource(path)
	if not sourceCode then moduleCache[path] = false return nil end

	local loaderFn, compileErr = loadstring(sourceCode, "=" .. path)
	if not loaderFn then
		warn("[B0Xaz] Syntax error compiling " .. path .. ": " .. tostring(compileErr))
		moduleCache[path] = false return nil
	end

	local runSuccess, moduleResult = pcall(loaderFn)
	if not runSuccess then
		warn("[B0Xaz] Runtime error executing " .. path .. ": " .. tostring(moduleResult))
		moduleCache[path] = false return nil
	end

	print("[B0Xaz] Successfully imported: " .. path)
	moduleCache[path] = moduleResult
	return moduleResult
end

-- Load sequence with fix for typos
local cleanupFn = import(SETTINGS.PATHS.CLEANUP)
if type(cleanupFn) == "function" then pcall(cleanupFn) end

local configFn = import(SETTINGS.PATHS.CONFIG)
local configData, defaultLighting = {}, {}
if type(configFn) == "function" then
	local success, cfg, lighting = pcall(configFn)
	if success then configData = cfg or {} defaultLighting = lighting or {} end
end

local utilsFn = import(SETTINGS.PATHS.UTILS)
local utils = type(utilsFn) == "function" and utilsFn(configData) or {}
if type(utils.WaitForGameLoad) == "function" then pcall(utils.WaitForGameLoad, SETTINGS.DEFAULTS.LOAD_TIMEOUT) end

local drawingMgrFn = import(SETTINGS.PATHS.DRAWING_MANAGER)
local drawingManager = type(drawingMgrFn) == "function" and drawingMgrFn() or {Available = false}

local contextFn = import(SETTINGS.PATHS.CONTEXT)
local context = type(contextFn) == "function" and contextFn(configData, defaultLighting, utils, drawingManager) or {}
context.import = import

local themeFn = import(SETTINGS.PATHS.THEME)
local activeTheme, themeManager = {}, {}
if type(themeFn) == "function" then
	local success, th, thMgr = pcall(themeFn)
	if success then activeTheme = th or {} themeManager = thMgr or {} end
end
context.Theme = activeTheme
context.ThemeManager = themeManager

local uiEngineFn = import(SETTINGS.PATHS.UI_ENGINE)
local uiEngine = type(uiEngineFn) == "function" and uiEngineFn(context, activeTheme) or {}
context.UIEngine = uiEngine

local keySysFn = import(SETTINGS.PATHS.KEY_SYSTEM)
local keySystem = type(keySysFn) == "function" and keySysFn(context, import) or {}
context.KeySystem = keySystem

local configSysFn = import(SETTINGS.PATHS.CONFIG_SYSTEM)
context.ConfigSystem = type(configSysFn) == "function" and configSysFn(context) or {}

local aimbotSysFn = import(SETTINGS.PATHS.AIMBOT_SYSTEM)
context.AimbotSystem = type(aimbotSysFn) == "function" and aimbotSysFn(context) or {}

local espSysFn = import(SETTINGS.PATHS.ESP_SYSTEM)
context.ESPSystem = type(espSysFn) == "function" and espSysFn(context) or {}

local flingSysFn = import(SETTINGS.PATHS.FLING_SYSTEM)
context.FlingSystem = type(flingSysFn) == "function" and flingSysFn(context) or {}

local flySysFn = import(SETTINGS.PATHS.FLY_SYSTEM)
context.FlySystem = type(flySysFn) == "function" and flySysFn(context) or {}

local moveSysFn = import(SETTINGS.PATHS.MOVEMENT_SYSTEM)
context.MovementSystem = type(moveSysFn) == "function" and moveSysFn(context) or {}

local perfSysFn = import(SETTINGS.PATHS.PERFORMANCE_SYSTEM)
context.PerformanceSystem = type(perfSysFn) == "function" and perfSysFn(context) or {}

local playersSysFn = import(SETTINGS.PATHS.PLAYERS_SYSTEM)
context.PlayersSystem = type(playersSysFn) == "function" and playersSysFn(context) or {}

local overlayMgrFn = import(SETTINGS.PATHS.OVERLAY_MANAGER)
context.OverlayManager = type(overlayMgrFn) == "function" and overlayMgrFn(context) or {}

local gameLoaderFn = import(SETTINGS.PATHS.GAME_LOADER)
context.GameLoader = type(gameLoaderFn) == "function" and gameLoaderFn(context, import) or {}

globalEnv.B0XazContext = context

local function startApplication()
	print("[B0Xaz] Launching systems and UI...")
	if context.GameLoader and context.GameLoader.Load then pcall(context.GameLoader.Load) end
	if context.ESPSystem and context.ESPSystem.InitializeAll then pcall(context.ESPSystem.InitializeAll) end
	if context.ConfigSystem and context.ConfigSystem.LoadAutoload then pcall(context.ConfigSystem.LoadAutoload) end
	if context.ConfigSystem and context.ConfigSystem.StartAutosaveLoop then pcall(context.ConfigSystem.StartAutosaveLoop) end
	
	local buildUiFn = import(SETTINGS.PATHS.BUILD_UI)
	if type(buildUiFn) == "function" then pcall(buildUiFn, context) end

	local runtimeFn = import(SETTINGS.PATHS.RUNTIME)
	if type(runtimeFn) == "function" then pcall(runtimeFn, context) end
	print("[B0Xaz] Successfully loaded and active!")
end

local isVerified = false
if keySystem and keySystem.LoadAndVerify then
	local success, verified = pcall(keySystem.LoadAndVerify)
	isVerified = success and verified
end

if isVerified then
	startApplication()
else
	if uiEngine and uiEngine.CreateKeyPrompt then
		uiEngine.CreateKeyPrompt(nil, keySystem, activeTheme, startApplication, "")
	else
		startApplication()
	end
end
