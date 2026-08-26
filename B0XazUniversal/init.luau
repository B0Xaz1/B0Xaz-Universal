--!strict
-- ══════════════════════════════════════════════════════════════════════════════
-- B0XazUniversal - Unified Bootstrap Orchestrator (Path Resilient)
-- ══════════════════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")

local LOAD_TIMEOUT: number = 15
local RETRY_ATTEMPTS: number = 3

local globalEnv = (getgenv and getgenv()) or _G

local function trace(message: string)
	print("[B0Xaz][Trace] " .. message)
end

local SOURCE_ROOT: string = "B0XazUniversal"
local sourceRef: string = tostring(globalEnv.B0XazRef or "main")

-- All source files, including this entry point, live under B0XazUniversal/.
-- B0XazBaseURL may point either at the repository ref or directly at that
-- folder; normalize both forms so every fetch uses the same root.
local configuredBaseURL = globalEnv.B0XazBaseURL
local BASE_URL: string
if typeof(configuredBaseURL) == "string" and configuredBaseURL:gsub("%s+", "") ~= "" then
	BASE_URL = configuredBaseURL
else
	BASE_URL = "https://raw.githubusercontent.com/B0Xaz1/Rewrite/" .. sourceRef .. "/" .. SOURCE_ROOT
end
-- Remove a trailing slash (and any accidental query string) before checking
-- the folder name, then restore the slash required for URL concatenation.
BASE_URL = (BASE_URL:match("^[^?#]*") or BASE_URL):gsub("[/\\]+$", "")
if not BASE_URL:lower():match("/" .. SOURCE_ROOT:lower() .. "$") then
	BASE_URL = BASE_URL .. "/" .. SOURCE_ROOT
end
BASE_URL = BASE_URL .. "/"
-- Keep the resolved location available to the server-hop/teleport pipeline.
globalEnv.B0XazBaseURL = BASE_URL
globalEnv.B0XazInitURL = BASE_URL .. "init.luau"

trace("Entry point loaded")
trace("Source ref: " .. sourceRef)
trace("Source base: " .. BASE_URL)

-- Session ID & Cleanup
local currentSessionId: number = (tonumber(globalEnv.B0XazSessionId) or 0) + 1
globalEnv.B0XazSessionId = currentSessionId

if globalEnv.B0XazMasterDisposer and typeof(globalEnv.B0XazMasterDisposer.Dispose) == "function" then
	pcall(function() globalEnv.B0XazMasterDisposer:Dispose() end)
	globalEnv.B0XazMasterDisposer = nil
end
trace("Session " .. tostring(currentSessionId) .. " initialized")

-- Wait for Game Load
if not game:IsLoaded() then
	local start = os.clock()
	while not game:IsLoaded() and (os.clock() - start) < LOAD_TIMEOUT do task.wait(0.1) end
end
if not Players.LocalPlayer then
	local start = os.clock()
	while not Players.LocalPlayer and (os.clock() - start) < LOAD_TIMEOUT do task.wait(0.1) end
end
trace(string.format("Readiness complete: gameLoaded=%s localPlayer=%s", tostring(game:IsLoaded()), tostring(Players.LocalPlayer ~= nil)))

local sourceCache: { [string]: string } = {}
local compiledCache: { [string]: any } = {}

local function fetchSource(path: string): string
	-- Strip prefixes for clean path resolution across repos
	local cleanPath = path:gsub("^%./", ""):gsub("^/", ""):gsub("^B0XazUniversal/", "")
	if sourceCache[cleanPath] then return sourceCache[cleanPath] end

	local lastErr = "Unknown"
	for attempt = 1, RETRY_ATTEMPTS do
		local url = BASE_URL .. cleanPath .. (attempt > 1 and ("?t=" .. os.clock()) or "")
		trace(string.format("Fetch attempt %d/%d: %s", attempt, RETRY_ATTEMPTS, url))
		local ok, response = pcall(game.HttpGet, game, url)
		if ok and type(response) == "string" and #response > 10 and not response:find("404: Not Found", 1, true) then
			sourceCache[cleanPath] = response
			trace(string.format("Fetch succeeded: %s (%d bytes)", cleanPath, #response))
			return response
		end
		lastErr = tostring(response)
		trace(string.format("Fetch attempt failed: %s (%s)", cleanPath, lastErr))
		task.wait(0.1 * attempt)
	end
	error(string.format("[B0Xaz] Fetch failed for '%s': %s", cleanPath, lastErr))
end

local function requireModule(path: string, ...: any): any
	local cleanPath = path:gsub("^%./", ""):gsub("^/", ""):gsub("^B0XazUniversal/", "")
	trace("Require start: " .. cleanPath)
	if compiledCache[cleanPath] ~= nil then
		trace("Require cache hit: " .. cleanPath)
		return compiledCache[cleanPath]
	end

	local source = fetchSource(cleanPath)
	local chunk, compileErr = loadstring(source, "@" .. cleanPath)
	if not chunk then
		error(string.format("[B0Xaz] Syntax Error in '%s': %s", cleanPath, tostring(compileErr)))
	end
	trace("Compiled: " .. cleanPath)

	local execOk, factory = pcall(chunk)
	if not execOk then
		error(string.format("[B0Xaz] Runtime Error in '%s': %s", cleanPath, tostring(factory)))
	end
	trace("Executed: " .. cleanPath)

	local result = factory
	if typeof(factory) == "function" then
		trace("Factory initialize: " .. cleanPath)
		local initOk, initialized = pcall(factory, ...)
		if not initOk then
			error(string.format("[B0Xaz] Init Error in '%s': %s", cleanPath, tostring(initialized)))
		end
		result = initialized
		trace("Factory ready: " .. cleanPath)
	end

	compiledCache[cleanPath] = result
	trace("Require complete: " .. cleanPath)
	return result
end

local function requireStep(label: string, path: string, ...: any): any
	trace("Step load: " .. label)
	local result = requireModule(path, ...)
	trace("Step loaded: " .. label)
	return result
end

-- Execution Pipeline
local function bootstrap()
	print("[B0Xaz] Starting Suite Engine...")
	trace("Bootstrap start")

	local Disposer = requireStep("Disposer", "src/Core/Disposer.luau")
	local masterDisposer = Disposer.new("MasterDisposer")
	globalEnv.B0XazMasterDisposer = masterDisposer
	trace("Master disposer created")

	local Environment = requireStep("Environment", "src/Core/Environment.luau", masterDisposer)
	local EventBus = requireStep("EventBus", "src/Core/EventBus.luau", masterDisposer)
	local StateStore = requireStep("StateStore", "src/Core/StateStore.luau", EventBus, masterDisposer)
	local TaskScheduler = requireStep("TaskScheduler", "src/Core/TaskScheduler.luau", masterDisposer)
	local ServiceContainer = requireStep("ServiceContainer", "src/Core/ServiceContainer.luau")
	local DOM = requireStep("DOM", "src/UI/DOM.luau")

	local function registerStep(name: string, service: any)
		trace("Register service: " .. name)
		ServiceContainer:Register(name, service)
		trace("Registered service: " .. name)
	end

	registerStep("Disposer", masterDisposer)
	registerStep("Environment", Environment)
	registerStep("EventBus", EventBus)
	registerStep("StateStore", StateStore)
	registerStep("TaskScheduler", TaskScheduler)
	registerStep("Require", requireModule)
	registerStep("DOM", DOM)

	local KeyService = requireStep("KeyService", "src/Services/KeyService.luau", ServiceContainer)
	local ConfigService = requireStep("ConfigService", "src/Services/ConfigService.luau", ServiceContainer)
	local PlayerTracker = requireStep("PlayerTracker", "src/Services/PlayerTracker.luau", ServiceContainer)
	local OptimizerService = requireStep("OptimizerService", "src/Services/OptimizerService.luau", ServiceContainer)
	registerStep("KeyService", KeyService)
	registerStep("ConfigService", ConfigService)
	registerStep("PlayerTracker", PlayerTracker)
	registerStep("OptimizerService", OptimizerService)

	-- Register each dependency before loading consumers that resolve it during
	-- their factory call. This keeps the bootstrap order deterministic.
	local DrawingPool = requireStep("DrawingPool", "src/Visuals/DrawingPool.luau", ServiceContainer)
	registerStep("DrawingPool", DrawingPool)

	local TargetFilter = requireStep("TargetFilter", "src/Combat/TargetFilter.luau", ServiceContainer)
	registerStep("TargetFilter", TargetFilter)

	local ESPController = requireStep("ESPController", "src/Visuals/ESPController.luau", ServiceContainer)
	local OverlayController = requireStep("OverlayController", "src/Visuals/OverlayController.luau", ServiceContainer)
	registerStep("ESPController", ESPController)
	registerStep("OverlayController", OverlayController)

	local LocomotionService = requireStep("LocomotionService", "src/Locomotion/LocomotionService.luau", ServiceContainer)
	local FlightService = requireStep("FlightService", "src/Locomotion/FlightService.luau", ServiceContainer)
	registerStep("LocomotionService", LocomotionService)
	registerStep("FlightService", FlightService)

	local AimbotService = requireStep("AimbotService", "src/Combat/AimbotService.luau", ServiceContainer)
	local TriggerbotService = requireStep("TriggerbotService", "src/Combat/TriggerbotService.luau", ServiceContainer)
	registerStep("AimbotService", AimbotService)
	registerStep("TriggerbotService", TriggerbotService)

	local PluginManager = requireStep("PluginManager", "src/Plugins/PluginManager.luau", ServiceContainer)
	registerStep("PluginManager", PluginManager)

	local ThemeEngine = requireStep("ThemeEngine", "src/UI/ThemeEngine.luau", ServiceContainer)
	registerStep("ThemeEngine", ThemeEngine)

	local UIEngine = requireStep("UIEngine", "src/UI/UIEngine.luau", ServiceContainer)
	registerStep("UIEngine", UIEngine)

	local function initializeStep(name: string, service: any)
		trace("Initialize: " .. name)
		service:Initialize()
		trace("Initialized: " .. name)
	end

	local function launch()
		initializeStep("PlayerTracker", PlayerTracker)
		initializeStep("OptimizerService", OptimizerService)
		initializeStep("ESPController", ESPController)
		initializeStep("OverlayController", OverlayController)
		initializeStep("LocomotionService", LocomotionService)
		initializeStep("FlightService", FlightService)
		initializeStep("AimbotService", AimbotService)
		initializeStep("TriggerbotService", TriggerbotService)
		initializeStep("ConfigService", ConfigService)
		initializeStep("PluginManager", PluginManager)

		trace("Constructing interface")
		UIEngine:ConstructInterface()
		trace("Interface constructed")
		trace("Loading autoload configuration")
		ConfigService:LoadAutoload()
		print("[B0Xaz] Interface & Systems Ready.")
	end

	trace("Checking saved credentials")
	local isVerified, tier, msg = KeyService:VerifySavedKey()
	if isVerified then
		trace("Saved credentials accepted")
		StateStore:SetTier(tier)
		launch()
	else
		trace("Saved credentials unavailable; showing authentication modal")
		local KeyAuthModal = requireStep("KeyAuthModal", "src/UI/Modals/KeyAuthModal.luau", ServiceContainer)
		KeyAuthModal:Show(function(verifiedTier)
			trace("Credentials accepted from modal")
			StateStore:SetTier(verifiedTier)
			launch()
		end, msg)
	end
	trace("Bootstrap complete")
end

trace("Invoking bootstrap")
bootstrap()
