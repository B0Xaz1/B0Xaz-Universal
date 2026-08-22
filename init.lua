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
}

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
	local startTime = os.clock()
	while not Players.LocalPlayer and (os.clock() - startTime) < SETTINGS.DEFAULTS.LOAD_TIMEOUT do
		task.wait()
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
local function import(path)
	if moduleCache[path] then
		return moduleCache[path]
	end

	local sourceCode = nil
	local pathVariants = {
		path,
		path:gsub("^src/", ""),
		"./" .. path,
	}

	if readfile and isfile then
		for _, variant in ipairs(pathVariants) do
			local success, isFileExist = pcall(isfile, variant)
			if success and isFileExist then
				local readSuccess, content = pcall(readfile, variant)
				if readSuccess and content and #content > 0 then
					sourceCode = content
					break
				end
			end
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
end

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

if utils.WaitForGameLoad then
	pcall(utils.WaitForGameLoad, SETTINGS.DEFAULTS.LOAD_TIMEOUT)
end

local drawingMgrFn = import(SETTINGS.PATHS.DRAWING_MANAGER)
local drawingManager = type(drawingMgrFn) == "function" and drawingMgrFn() or {}

local contextFn = import(SETTINGS.PATHS.CONTEXT)
local context = type(contextFn) == "function" and contextFn(configData, defaultLighting, utils, drawingManager) or {}
context.import = import

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

local function startApplication()
	if gameLoader and gameLoader.Load then
		pcall(gameLoader.Load)
	end

	if espSystem and espSystem.InitializeAll then
		pcall(espSystem.InitializeAll)
	end

	if configSystem and configSystem.LoadAutoload then
		pcall(configSystem.LoadAutoload)
	end

	if configSystem and configSystem.StartAutosaveLoop then
		pcall(configSystem.StartAutosaveLoop)
	end

	local buildUiFn = import(SETTINGS.PATHS.BUILD_UI)
	if type(buildUiFn) == "function" then
		pcall(buildUiFn, context)
	end

	local runtimeFn = import(SETTINGS.PATHS.RUNTIME)
	if type(runtimeFn) == "function" then
		pcall(runtimeFn, context)
	end
end

local isVerified, verifyMsg = false, ""
if keySystem and keySystem.LoadAndVerify then
	local success, verified, _, msg = pcall(keySystem.LoadAndVerify)
	if success then
		isVerified = verified
		verifyMsg = msg or ""
	end
end

if isVerified then
	startApplication()
else
	local promptCreated = false
	if uiEngine and uiEngine.CreateKeyPrompt then
		local success = pcall(function()
			uiEngine.CreateKeyPrompt(nil, keySystem, activeTheme, startApplication, verifyMsg)
		end)
		promptCreated = success
	end
	if not promptCreated then
		startApplication()
	end
end
