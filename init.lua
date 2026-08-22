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
		BASE_URL = "https://raw.githubusercontent.com/B0Xaz/Universal/main/",
		LOAD_TIMEOUT = 10,
	},
	LOG_FORMAT = "[B0Xaz Loader] %s",
	LOG_MESSAGES = {
		START = "Initializing B0Xaz Framework...",
		CLEANUP = "Cleanup executed.",
		CONFIG = "Configuration loaded.",
		UTILS = "Utilities initialized.",
		GAME_WAIT = "Game environment verified.",
		DRAWING_MANAGER = "Drawing Manager loaded.",
		CONTEXT = "Context registry created.",
		THEME = "Theme system loaded.",
		UI_ENGINE = "UI Engine initialized.",
		KEY_SYSTEM = "Key System initialized.",
		CONFIG_SYSTEM = "Config System initialized.",
		AIMBOT_SYSTEM = "Aimbot System initialized.",
		ESP_SYSTEM = "ESP System initialized.",
		FLING_SYSTEM = "Fling System initialized.",
		FLY_SYSTEM = "Fly System initialized.",
		MOVEMENT_SYSTEM = "Movement System initialized.",
		PERFORMANCE_SYSTEM = "Performance System initialized.",
		PLAYERS_SYSTEM = "Players System initialized.",
		OVERLAY_MANAGER = "Overlay Manager initialized.",
		GAME_LOADER = "Game Loader initialized.",
		GAME_MODULE = "Game specific module loaded.",
		ESP_INIT = "ESP world entities initialized.",
		CONFIG_AUTOLOAD = "Autoload profile applied.",
		AUTOSAVE_START = "Autosave background thread started.",
		BUILD_UI = "User Interface generated.",
		RUNTIME = "Runtime core loop started.",
		AUTH_SUCCESS = "License verified successfully. Starting application...",
		AUTH_REQUIRED = "License verification required. Prompting authentication UI...",
		COMPLETE = "B0Xaz Framework successfully loaded.",
	},
}

local function log(message)
	print(string.format(SETTINGS.LOG_FORMAT, message))
end

log(SETTINGS.LOG_MESSAGES.START)

local globalEnv = getgenv and getgenv() or _G

local moduleCache = {}
local function import(path)
	if moduleCache[path] then
		return moduleCache[path]
	end

	local sourceCode = nil

	if readfile and isfile and isfile(path) then
		local success, content = pcall(readfile, path)
		if success and content then
			sourceCode = content
		end
	end

	if not sourceCode and game.HttpGet then
		local baseUrl = globalEnv.B0XazBaseURL or SETTINGS.DEFAULTS.BASE_URL
		local cleanPath = path:gsub("^%./", ""):gsub("^/", "")
		local fullUrl = baseUrl .. cleanPath
		local success, response = pcall(function()
			return game:HttpGet(fullUrl)
		end)
		if success and response and #response > 0 then
			sourceCode = response
		end
	end

	if not sourceCode then
		return nil
	end

	local loaderFn = loadstring(sourceCode, path)
	if not loaderFn then
		return nil
	end

	local runSuccess, moduleResult = pcall(loaderFn)
	if not runSuccess then
		return nil
	end

	moduleCache[path] = moduleResult
	return moduleResult
end

local cleanupFn = import(SETTINGS.PATHS.CLEANUP)
if type(cleanupFn) == "function" then
	pcall(cleanupFn)
	log(SETTINGS.LOG_MESSAGES.CLEANUP)
end

local configFn = import(SETTINGS.PATHS.CONFIG)
local configData, defaultLighting = {}, {}
if type(configFn) == "function" then
	local success, cfg, lighting = pcall(configFn)
	if success then
		configData = cfg or {}
		defaultLighting = lighting or {}
	end
	log(SETTINGS.LOG_MESSAGES.CONFIG)
end

local utilsFn = import(SETTINGS.PATHS.UTILS)
local utils = type(utilsFn) == "function" and utilsFn(configData) or {}
log(SETTINGS.LOG_MESSAGES.UTILS)

if utils.WaitForGameLoad then
	utils.WaitForGameLoad(SETTINGS.DEFAULTS.LOAD_TIMEOUT)
	log(SETTINGS.LOG_MESSAGES.GAME_WAIT)
end

local drawingMgrFn = import(SETTINGS.PATHS.DRAWING_MANAGER)
local drawingManager = type(drawingMgrFn) == "function" and drawingMgrFn() or {}
log(SETTINGS.LOG_MESSAGES.DRAWING_MANAGER)

local contextFn = import(SETTINGS.PATHS.CONTEXT)
local context = type(contextFn) == "function" and contextFn(configData, defaultLighting, utils, drawingManager) or {}
context.import = import
log(SETTINGS.LOG_MESSAGES.CONTEXT)

local themeFn = import(SETTINGS.PATHS.THEME)
local activeTheme, themeManager = {}, {}
if type(themeFn) == "function" then
	local success, th, thMgr = pcall(themeFn)
	if success then
		activeTheme = th or {}
		themeManager = thMgr or {}
	end
	log(SETTINGS.LOG_MESSAGES.THEME)
end
context.Theme = activeTheme
context.ThemeManager = themeManager

local uiEngineFn = import(SETTINGS.PATHS.UI_ENGINE)
local uiEngine = type(uiEngineFn) == "function" and uiEngineFn(context, activeTheme) or {}
context.UIEngine = uiEngine
log(SETTINGS.LOG_MESSAGES.UI_ENGINE)

local keySysFn = import(SETTINGS.PATHS.KEY_SYSTEM)
local keySystem = type(keySysFn) == "function" and keySysFn(context, import) or {}
context.KeySystem = keySystem
log(SETTINGS.LOG_MESSAGES.KEY_SYSTEM)

local configSysFn = import(SETTINGS.PATHS.CONFIG_SYSTEM)
local configSystem = type(configSysFn) == "function" and configSysFn(context) or {}
context.ConfigSystem = configSystem
log(SETTINGS.LOG_MESSAGES.CONFIG_SYSTEM)

local aimbotSysFn = import(SETTINGS.PATHS.AIMBOT_SYSTEM)
local aimbotSystem = type(aimbotSysFn) == "function" and aimbotSysFn(context) or {}
context.AimbotSystem = aimbotSystem
log(SETTINGS.LOG_MESSAGES.AIMBOT_SYSTEM)

local espSysFn = import(SETTINGS.PATHS.ESP_SYSTEM)
local espSystem = type(espSysFn) == "function" and espSysFn(context) or {}
context.ESPSystem = espSystem
log(SETTINGS.LOG_MESSAGES.ESP_SYSTEM)

local flingSysFn = import(SETTINGS.PATHS.FLING_SYSTEM)
local flingSystem = type(flingSysFn) == "function" and flingSysFn(context) or {}
context.FlingSystem = flingSystem
log(SETTINGS.LOG_MESSAGES.FLING_SYSTEM)

local flySysFn = import(SETTINGS.PATHS.FLY_SYSTEM)
local flySystem = type(flySysFn) == "function" and flySysFn(context) or {}
context.FlySystem = flySystem
log(SETTINGS.LOG_MESSAGES.FLY_SYSTEM)

local moveSysFn = import(SETTINGS.PATHS.MOVEMENT_SYSTEM)
local movementSystem = type(moveSysFn) == "function" and moveSysFn(context) or {}
context.MovementSystem = movementSystem
log(SETTINGS.LOG_MESSAGES.MOVEMENT_SYSTEM)

local perfSysFn = import(SETTINGS.PATHS.PERFORMANCE_SYSTEM)
local performanceSystem = type(perfSysFn) == "function" and perfSysFn(context) or {}
context.PerformanceSystem = performanceSystem
log(SETTINGS.LOG_MESSAGES.PERFORMANCE_SYSTEM)

local playersSysFn = import(SETTINGS.PATHS.PLAYERS_SYSTEM)
local playersSystem = type(playersSysFn) == "function" and playersSysFn(context) or {}
context.PlayersSystem = playersSystem
log(SETTINGS.LOG_MESSAGES.PLAYERS_SYSTEM)

local overlayMgrFn = import(SETTINGS.PATHS.OVERLAY_MANAGER)
local overlayManager = type(overlayMgrFn) == "function" and overlayMgrFn(context) or {}
context.OverlayManager = overlayManager
log(SETTINGS.LOG_MESSAGES.OVERLAY_MANAGER)

local gameLoaderFn = import(SETTINGS.PATHS.GAME_LOADER)
local gameLoader = type(gameLoaderFn) == "function" and gameLoaderFn(context, import) or {}
context.GameLoader = gameLoader
log(SETTINGS.LOG_MESSAGES.GAME_LOADER)

globalEnv.B0XazContext = context

local function startApplication()
	if gameLoader and gameLoader.Load then
		pcall(gameLoader.Load)
		log(SETTINGS.LOG_MESSAGES.GAME_MODULE)
	end

	if espSystem and espSystem.InitializeAll then
		pcall(espSystem.InitializeAll)
		log(SETTINGS.LOG_MESSAGES.ESP_INIT)
	end

	if configSystem and configSystem.LoadAutoload then
		pcall(configSystem.LoadAutoload)
		log(SETTINGS.LOG_MESSAGES.CONFIG_AUTOLOAD)
	end

	if configSystem and configSystem.StartAutosaveLoop then
		pcall(configSystem.StartAutosaveLoop)
		log(SETTINGS.LOG_MESSAGES.AUTOSAVE_START)
	end

	local buildUiFn = import(SETTINGS.PATHS.BUILD_UI)
	if type(buildUiFn) == "function" then
		pcall(buildUiFn, context)
		log(SETTINGS.LOG_MESSAGES.BUILD_UI)
	end

	local runtimeFn = import(SETTINGS.PATHS.RUNTIME)
	if type(runtimeFn) == "function" then
		pcall(runtimeFn, context)
		log(SETTINGS.LOG_MESSAGES.RUNTIME)
	end

	log(SETTINGS.LOG_MESSAGES.COMPLETE)
end

local isVerified, _, verifyMsg = false, 0, ""
if keySystem and keySystem.LoadAndVerify then
	isVerified, _, verifyMsg = keySystem.LoadAndVerify()
end

if isVerified then
	log(SETTINGS.LOG_MESSAGES.AUTH_SUCCESS)
	startApplication()
else
	log(SETTINGS.LOG_MESSAGES.AUTH_REQUIRED)
	if uiEngine and uiEngine.CreateKeyPrompt then
		uiEngine.CreateKeyPrompt(nil, keySystem, activeTheme, startApplication, verifyMsg)
	else
		startApplication()
	end
end
