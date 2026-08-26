--!strict
-- ══════════════════════════════════════════════════════════════════════════════
-- B0XazUniversal - Unified Bootstrap Orchestrator (Path Resilient)
-- ══════════════════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")

local LOAD_TIMEOUT: number = 15
local RETRY_ATTEMPTS: number = 3

local globalEnv = (getgenv and getgenv()) or _G
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

-- Session ID & Cleanup
local currentSessionId: number = (tonumber(globalEnv.B0XazSessionId) or 0) + 1
globalEnv.B0XazSessionId = currentSessionId

if globalEnv.B0XazMasterDisposer and typeof(globalEnv.B0XazMasterDisposer.Dispose) == "function" then
	pcall(function() globalEnv.B0XazMasterDisposer:Dispose() end)
	globalEnv.B0XazMasterDisposer = nil
end

-- Wait for Game Load
if not game:IsLoaded() then
	local start = os.clock()
	while not game:IsLoaded() and (os.clock() - start) < LOAD_TIMEOUT do task.wait(0.1) end
end
if not Players.LocalPlayer then
	local start = os.clock()
	while not Players.LocalPlayer and (os.clock() - start) < LOAD_TIMEOUT do task.wait(0.1) end
end

local sourceCache: { [string]: string } = {}
local compiledCache: { [string]: any } = {}

local function fetchSource(path: string): string
	-- Strip prefixes for clean path resolution across repos
	local cleanPath = path:gsub("^%./", ""):gsub("^/", ""):gsub("^B0XazUniversal/", "")
	if sourceCache[cleanPath] then return sourceCache[cleanPath] end

	local lastErr = "Unknown"
	for attempt = 1, RETRY_ATTEMPTS do
		local url = BASE_URL .. cleanPath .. (attempt > 1 and ("?t=" .. os.clock()) or "")
		local ok, response = pcall(game.HttpGet, game, url)
		if ok and type(response) == "string" and #response > 10 and not response:find("404: Not Found", 1, true) then
			sourceCache[cleanPath] = response
			return response
		end
		lastErr = tostring(response)
		task.wait(0.1 * attempt)
	end
	error(string.format("[B0Xaz] Fetch failed for '%s': %s", cleanPath, lastErr))
end

local function requireModule(path: string, ...: any): any
	local cleanPath = path:gsub("^%./", ""):gsub("^/", ""):gsub("^B0XazUniversal/", "")
	if compiledCache[cleanPath] ~= nil then return compiledCache[cleanPath] end

	local source = fetchSource(cleanPath)
	local chunk, compileErr = loadstring(source, "@" .. cleanPath)
	if not chunk then
		error(string.format("[B0Xaz] Syntax Error in '%s': %s", cleanPath, tostring(compileErr)))
	end

	local execOk, factory = pcall(chunk)
	if not execOk then
		error(string.format("[B0Xaz] Runtime Error in '%s': %s", cleanPath, tostring(factory)))
	end

	local result = factory
	if typeof(factory) == "function" then
		local initOk, initialized = pcall(factory, ...)
		if not initOk then
			error(string.format("[B0Xaz] Init Error in '%s': %s", cleanPath, tostring(initialized)))
		end
		result = initialized
	end

	compiledCache[cleanPath] = result
	return result
end

-- Execution Pipeline
local function bootstrap()
	print("[B0Xaz] Starting Suite Engine...")

	local Disposer = requireModule("src/Core/Disposer.luau")
	local masterDisposer = Disposer.new("MasterDisposer")
	globalEnv.B0XazMasterDisposer = masterDisposer

	local Environment = requireModule("src/Core/Environment.luau", masterDisposer)
	local EventBus = requireModule("src/Core/EventBus.luau", masterDisposer)
	local StateStore = requireModule("src/Core/StateStore.luau", EventBus, masterDisposer)
	local TaskScheduler = requireModule("src/Core/TaskScheduler.luau", masterDisposer)
	local ServiceContainer = requireModule("src/Core/ServiceContainer.luau")

	ServiceContainer:Register("Disposer", masterDisposer)
	ServiceContainer:Register("Environment", Environment)
	ServiceContainer:Register("EventBus", EventBus)
	ServiceContainer:Register("StateStore", StateStore)
	ServiceContainer:Register("TaskScheduler", TaskScheduler)
	ServiceContainer:Register("Require", requireModule)

	local KeyService = requireModule("src/Services/KeyService.luau", ServiceContainer)
	local ConfigService = requireModule("src/Services/ConfigService.luau", ServiceContainer)
	local PlayerTracker = requireModule("src/Services/PlayerTracker.luau", ServiceContainer)
	local OptimizerService = requireModule("src/Services/OptimizerService.luau", ServiceContainer)

	ServiceContainer:Register("KeyService", KeyService)
	ServiceContainer:Register("ConfigService", ConfigService)
	ServiceContainer:Register("PlayerTracker", PlayerTracker)
	ServiceContainer:Register("OptimizerService", OptimizerService)

	local DrawingPool = requireModule("src/Visuals/DrawingPool.luau", ServiceContainer)
	local ESPController = requireModule("src/Visuals/ESPController.luau", ServiceContainer)
	local OverlayController = requireModule("src/Visuals/OverlayController.luau", ServiceContainer)
	local LocomotionService = requireModule("src/Locomotion/LocomotionService.luau", ServiceContainer)
	local FlightService = requireModule("src/Locomotion/FlightService.luau", ServiceContainer)

	ServiceContainer:Register("DrawingPool", DrawingPool)
	ServiceContainer:Register("ESPController", ESPController)
	ServiceContainer:Register("OverlayController", OverlayController)
	ServiceContainer:Register("LocomotionService", LocomotionService)
	ServiceContainer:Register("FlightService", FlightService)

	local TargetFilter = requireModule("src/Combat/TargetFilter.luau", ServiceContainer)
	local AimbotService = requireModule("src/Combat/AimbotService.luau", ServiceContainer)
	local TriggerbotService = requireModule("src/Combat/TriggerbotService.luau", ServiceContainer)

	ServiceContainer:Register("TargetFilter", TargetFilter)
	ServiceContainer:Register("AimbotService", AimbotService)
	ServiceContainer:Register("TriggerbotService", TriggerbotService)

	local PluginManager = requireModule("src/Plugins/PluginManager.luau", ServiceContainer)
	ServiceContainer:Register("PluginManager", PluginManager)

	local ThemeEngine = requireModule("src/UI/ThemeEngine.luau", ServiceContainer)
	local UIEngine = requireModule("src/UI/UIEngine.luau", ServiceContainer)
	ServiceContainer:Register("ThemeEngine", ThemeEngine)
	ServiceContainer:Register("UIEngine", UIEngine)

	local function launch()
		PlayerTracker:Initialize()
		OptimizerService:Initialize()
		ESPController:Initialize()
		OverlayController:Initialize()
		LocomotionService:Initialize()
		FlightService:Initialize()
		AimbotService:Initialize()
		TriggerbotService:Initialize()
		PluginManager:Initialize()

		UIEngine:ConstructInterface()
		ConfigService:LoadAutoload()
		print("[B0Xaz] Interface & Systems Ready.")
	end

	local isVerified, tier, msg = KeyService:VerifySavedKey()
	if isVerified then
		StateStore:SetTier(tier)
		launch()
	else
		local KeyAuthModal = requireModule("src/UI/Modals/KeyAuthModal.luau", ServiceContainer)
		KeyAuthModal:Show(function(verifiedTier)
			StateStore:SetTier(verifiedTier)
			launch()
		end, msg)
	end
end

bootstrap()
