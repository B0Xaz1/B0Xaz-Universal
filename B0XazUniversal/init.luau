--!strict
-- ══════════════════════════════════════════════════════════════════════════════
-- B0XazUniversal - Unified Bootstrap Orchestrator
-- Re-architected for deterministic lifecycle control, zero global state leaks,
-- and parallel asset resolution.
-- ══════════════════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local LOAD_TIMEOUT: number = 15
local RETRY_ATTEMPTS: number = 3
local RETRY_DELAY: number = 0.1

-- Environment Resolution
local globalEnv = (getgenv and getgenv()) or _G
local sourceRef: string = tostring(globalEnv.B0XazRef or "main")
if not sourceRef:match("^[%w%._%-/]+$") then
	sourceRef = "main"
end

local BASE_URL: string = tostring(globalEnv.B0XazBaseURL or ("https://raw.githubusercontent.com/B0Xaz1/testmenu/" .. sourceRef .. "/"))
if not BASE_URL:sub(-1):match("[/\\]") then
	BASE_URL = BASE_URL .. "/"
end

-- Atomic Session State
local currentSessionId: number = (tonumber(globalEnv.B0XazSessionId) or 0) + 1
globalEnv.B0XazSessionId = currentSessionId

-- Teardown Previous Suite Instance
if globalEnv.B0XazMasterDisposer and typeof(globalEnv.B0XazMasterDisposer.Dispose) == "function" then
	pcall(function()
		globalEnv.B0XazMasterDisposer:Dispose()
	end)
	globalEnv.B0XazMasterDisposer = nil
end

-- Wait for Game & LocalPlayer Loading
if not game:IsLoaded() then
	local startClock: number = os.clock()
	while not game:IsLoaded() and (os.clock() - startClock) < LOAD_TIMEOUT do
		task.wait(0.1)
	end
end

if not Players.LocalPlayer then
	local startClock: number = os.clock()
	while not Players.LocalPlayer and (os.clock() - startClock) < LOAD_TIMEOUT do
		task.wait(0.1)
	end
end

-- Module Source Fetcher with In-Memory Caching
local sourceCache: { [string]: string } = {}
local compiledModuleCache: { [string]: any } = {}

local function isValidLuaSource(source: string): (boolean, string?)
	if typeof(source) ~= "string" or #source < 8 then
		return false, "Empty response"
	end
	local head = source:sub(1, 150):lower()
	if head:find("<!doctype", 1, true) or head:find("<html", 1, true) then
		return false, "Received HTML page (invalid endpoint)"
	end
	if head:find("404: not found", 1, true) or head:find("404 not found", 1, true) then
		return false, "File not found (404)"
	end
	return true, nil
end

local function fetchSource(path: string): string
	local cleanPath = path:gsub("^%./", ""):gsub("^/", "")
	if sourceCache[cleanPath] then
		return sourceCache[cleanPath]
	end

	local targetUrl = BASE_URL .. cleanPath
	local lastError = "Unknown error"

	for attempt = 1, RETRY_ATTEMPTS do
		local requestUrl = targetUrl
		if attempt > 1 then
			requestUrl = targetUrl .. (targetUrl:find("?", 1, true) and "&" or "?") .. "nocache=" .. tostring(os.clock())
		end

		local fetchOk, response = pcall(function()
			return game:HttpGet(requestUrl)
		end)

		if fetchOk and typeof(response) == "string" then
			local valid, errReason = isValidLuaSource(response)
			if valid then
				sourceCache[cleanPath] = response
				return response
			end
			lastError = errReason or "Invalid source"
		else
			lastError = tostring(response)
		end
		task.wait(RETRY_DELAY * attempt)
	end

	error(string.format("[B0Xaz Bootstrapper] Failed to fetch '%s' after %d attempts: %s", cleanPath, RETRY_ATTEMPTS, lastError))
end

-- Safe Require Implementation
local function requireModule(path: string, ...: any): any
	local cleanPath = path:gsub("^%./", ""):gsub("^/", "")
	if compiledModuleCache[cleanPath] ~= nil then
		return compiledModuleCache[cleanPath]
	end

	local source = fetchSource(cleanPath)
	local chunk, compileErr = loadstring(source, "@" .. cleanPath)
	if not chunk then
		error(string.format("[B0Xaz Bootstrapper] Syntax error in '%s': %s", cleanPath, tostring(compileErr)))
	end

	local execOk, factory = pcall(chunk)
	if not execOk then
		error(string.format("[B0Xaz Bootstrapper] Runtime error in '%s': %s", cleanPath, tostring(factory)))
	end

	local moduleResult = factory
	if typeof(factory) == "function" then
		local initOk, initialized = pcall(factory, ...)
		if not initOk then
			error(string.format("[B0Xaz Bootstrapper] Factory execution failed in '%s': %s", cleanPath, tostring(initialized)))
		end
		moduleResult = initialized
	end

	compiledModuleCache[cleanPath] = moduleResult
	return moduleResult
end

-- Global Relaunch Hook
globalEnv.B0XazRelaunch = function()
	if globalEnv.B0XazRelaunching then return end
	globalEnv.B0XazRelaunching = true

	pcall(function()
		if globalEnv.B0XazMasterDisposer then
			globalEnv.B0XazMasterDisposer:Dispose()
			globalEnv.B0XazMasterDisposer = nil
		end
		local initSource = game:HttpGet(BASE_URL .. "init.luau?nocache=" .. tostring(os.clock()))
		local initFn = loadstring(initSource, "@init.luau")
		if initFn then
			initFn()
		end
	end)

	globalEnv.B0XazRelaunching = false
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Startup Pipeline Initialization
-- ─────────────────────────────────────────────────────────────────────────────
local function bootstrap()
	print("[B0Xaz] Initializing High-Performance Architecture...")

	-- 1. Core Foundations
	local Disposer = requireModule("B0XazUniversal/src/Core/Disposer.luau")
	local masterDisposer = Disposer.new("MasterDisposer")
	globalEnv.B0XazMasterDisposer = masterDisposer

	local Environment = requireModule("B0XazUniversal/src/Core/Environment.luau", masterDisposer)
	local EventBus = requireModule("B0XazUniversal/src/Core/EventBus.luau", masterDisposer)
	local StateStore = requireModule("B0XazUniversal/src/Core/StateStore.luau", EventBus, masterDisposer)
	local TaskScheduler = requireModule("B0XazUniversal/src/Core/TaskScheduler.luau", masterDisposer)
	local ServiceContainer = requireModule("B0XazUniversal/src/Core/ServiceContainer.luau")

	-- Register Core Services
	ServiceContainer:Register("Disposer", masterDisposer)
	ServiceContainer:Register("Environment", Environment)
	ServiceContainer:Register("EventBus", EventBus)
	ServiceContainer:Register("StateStore", StateStore)
	ServiceContainer:Register("TaskScheduler", TaskScheduler)
	ServiceContainer:Register("Require", requireModule)

	-- 2. Infrastructure Services
	local KeyService = requireModule("B0XazUniversal/src/Services/KeyService.luau", ServiceContainer)
	local ConfigService = requireModule("B0XazUniversal/src/Services/ConfigService.luau", ServiceContainer)
	local PlayerTracker = requireModule("B0XazUniversal/src/Services/PlayerTracker.luau", ServiceContainer)
	local OptimizerService = requireModule("B0XazUniversal/src/Services/OptimizerService.luau", ServiceContainer)

	ServiceContainer:Register("KeyService", KeyService)
	ServiceContainer:Register("ConfigService", ConfigService)
	ServiceContainer:Register("PlayerTracker", PlayerTracker)
	ServiceContainer:Register("OptimizerService", OptimizerService)

	-- 3. Visuals & Locomotion Foundations
	local DrawingPool = requireModule("B0XazUniversal/src/Visuals/DrawingPool.luau", ServiceContainer)
	local ESPController = requireModule("B0XazUniversal/src/Visuals/ESPController.luau", ServiceContainer)
	local OverlayController = requireModule("B0XazUniversal/src/Visuals/OverlayController.luau", ServiceContainer)
	local LocomotionService = requireModule("B0XazUniversal/src/Locomotion/LocomotionService.luau", ServiceContainer)
	local FlightService = requireModule("B0XazUniversal/src/Locomotion/FlightService.luau", ServiceContainer)

	ServiceContainer:Register("DrawingPool", DrawingPool)
	ServiceContainer:Register("ESPController", ESPController)
	ServiceContainer:Register("OverlayController", OverlayController)
	ServiceContainer:Register("LocomotionService", LocomotionService)
	ServiceContainer:Register("FlightService", FlightService)

	-- 4. Combat Mechanics
	local TargetFilter = requireModule("B0XazUniversal/src/Combat/TargetFilter.luau", ServiceContainer)
	local AimbotService = requireModule("B0XazUniversal/src/Combat/AimbotService.luau", ServiceContainer)
	local TriggerbotService = requireModule("B0XazUniversal/src/Combat/TriggerbotService.luau", ServiceContainer)

	ServiceContainer:Register("TargetFilter", TargetFilter)
	ServiceContainer:Register("AimbotService", AimbotService)
	ServiceContainer:Register("TriggerbotService", TriggerbotService)

	-- 5. Game Plugin Manager
	local PluginManager = requireModule("B0XazUniversal/src/Plugins/PluginManager.luau", ServiceContainer)
	ServiceContainer:Register("PluginManager", PluginManager)

	-- 6. UI Engine & Construction
	local ThemeEngine = requireModule("B0XazUniversal/src/UI/ThemeEngine.luau", ServiceContainer)
	local UIEngine = requireModule("B0XazUniversal/src/UI/UIEngine.luau", ServiceContainer)
	ServiceContainer:Register("ThemeEngine", ThemeEngine)
	ServiceContainer:Register("UIEngine", UIEngine)

	-- Launch Sequence: Verify Key or Display Auth Modal
	local function launchApplication()
		print("[B0Xaz] Launching verified runtime environment...")

		-- Initialize Systems
		PlayerTracker:Initialize()
		OptimizerService:Initialize()
		ESPController:Initialize()
		OverlayController:Initialize()
		LocomotionService:Initialize()
		FlightService:Initialize()
		AimbotService:Initialize()
		TriggerbotService:Initialize()
		PluginManager:Initialize()

		-- Build Main Window
		UIEngine:ConstructInterface()

		-- Load Autosaved Configuration Profile
		ConfigService:LoadAutoload()

		print("[B0Xaz] Universal Suite initialized successfully.")
	end

	-- Authenticate License
	local isVerified, currentTier, authMessage = KeyService:VerifySavedKey()
	if isVerified then
		StateStore:SetTier(currentTier)
		launchApplication()
	else
		local KeyAuthModal = requireModule("B0XazUniversal/src/UI/Modals/KeyAuthModal.luau", ServiceContainer)
		KeyAuthModal:Show(function(verifiedTier)
			StateStore:SetTier(verifiedTier)
			launchApplication()
		end, authMessage)
	end
end

local startupOk, startupErr = pcall(bootstrap)
if not startupOk then
	warn(string.format("[B0Xaz] Startup Failure: %s", tostring(startupErr)))
end
