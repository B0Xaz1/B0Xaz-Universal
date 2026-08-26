-- ════════════════════════════════════════════════════════════════════════════
-- init.lua (Force-Updating & Debugging Bootstrapper)
-- ════════════════════════════════════════════════════════════════════════════

local env = (getgenv and getgenv()) or _G

-- Base URL configuration
local branch = env.B0XazRef or "main"
local baseUrl = env.B0XazBaseURL or ("https://raw.githubusercontent.com/B0Xaz1/testmenu/" .. branch .. "/")

local moduleCache = {}

-- Polymorphic HttpGet with Forced Cache Invalidation
local function httpGet(url)
	-- Append aggressive cache-busting query parameter
	local cacheBustUrl = url .. (url:find("%?") and "&" or "?") .. "nocache=" .. tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999))
	
	if game and game.HttpGet then
		return game:HttpGet(cacheBustUrl)
	end
	
	local req = request or http_request or (syn and syn.request)
	if req then
		local res = req({
			Url = cacheBustUrl,
			Method = "GET",
			Headers = { ["Cache-Control"] = "no-cache, no-store, must-revalidate" }
		})
		return res and (res.Body or res.body)
	end
	
	error("No HttpGet capability available.")
end

-- Check if source code is valid Luau
local function isValidLua(source)
	if type(source) ~= "string" or #source < 10 then return false end
	local head = source:sub(1, 150):lower()
	if head:find("404: not found", 1, true) or head:find("404 not found", 1, true) then return false end
	if head:find("<!doctype", 1, true) or head:find("<html", 1, true) then return false end
	return true
end

-- Virtual Module Import Engine
local function import(path)
	local cleanPath = path:gsub("^%./", ""):gsub("^/", ""):gsub("^src/", "")
	
	if moduleCache[cleanPath] then
		return moduleCache[cleanPath]
	end

	local targetUrl = baseUrl .. cleanPath
	print("[B0Xaz Debug] Fetching: " .. targetUrl)

	local source = nil
	local lastErr = "Unknown error"

	for attempt = 1, 3 do
		local ok, result = pcall(httpGet, targetUrl)
		if ok and isValidLua(result) then
			source = result
			break
		else
			lastErr = tostring(result)
		end
		task.wait(0.1)
	end

	if not source then
		warn("[B0Xaz Error] Failed link: " .. targetUrl)
		error("[B0Xaz Loader] 404 Not Found on GitHub: '" .. cleanPath .. "'. Click the debug link above in console to verify file exists.")
	end

	local chunk, compileErr = loadstring(source, "@" .. cleanPath)
	if not chunk then
		error("[B0Xaz Loader] Syntax Error in '" .. cleanPath .. "': " .. tostring(compileErr))
	end

	local ok, module = pcall(chunk)
	if not ok then
		error("[B0Xaz Loader] Runtime Error in '" .. cleanPath .. "': " .. tostring(module))
	end

	moduleCache[cleanPath] = module
	return module
end

-- Ensure game environment readiness
if not game:IsLoaded() then game.Loaded:Wait() end
local Players = game:GetService("Players")
if not Players.LocalPlayer then
	while not Players.LocalPlayer do task.wait(0.1) end
end

print("[B0Xaz] Framework Bootstrapping Starting...")

-- 1. Core Framework
local Janitor = import("Core/Janitor.lua")
local Signal = import("Core/Signal.lua")
local Container = import("Core/Container.lua")
local Scheduler = import("Core/Scheduler.lua")

-- 2. Shared Utilities
local Constants = import("Shared/Constants.lua")
local Crypto = import("Shared/Crypto.lua")
local MathUtil = import("Shared/MathUtil.lua")
local SpatialUtil = import("Shared/SpatialUtil.lua")
local HttpUtil = import("Shared/HttpUtil.lua")

-- 3. Domain Services
local AuthService = import("Services/AuthService.lua")
local ConfigService = import("Services/ConfigService.lua")
local EntityService = import("Services/EntityService.lua")
local InputService = import("Services/InputService.lua")
local LocomotionService = import("Services/LocomotionService.lua")
local CombatService = import("Services/CombatService.lua")
local FlingService = import("Services/FlingService.lua")
local VisualsService = import("Services/VisualsService.lua")
local OverlayService = import("Services/OverlayService.lua")
local EnvironmentService = import("Services/EnvironmentService.lua")
local ServerService = import("Services/ServerService.lua")
local GameLoader = import("Games/GameLoader.lua")

-- 4. UI Framework
local ThemeEngine = import("UI/ThemeEngine.lua")
local UIManager = import("UI/UIManager.lua")
local AuthModal = import("UI/Components/Modals/AuthModal.lua")

-- Clean up existing session
if env.B0XazActiveJanitor then
	pcall(function() env.B0XazActiveJanitor:Destroy() end)
end

local masterJanitor = Janitor.new()
env.B0XazActiveJanitor = masterJanitor

-- Dependency Injection Setup
local container = Container.new()
container:Register("Janitor", masterJanitor)
container:Register("Signal", Signal)
container:Register("Constants", Constants)
container:Register("Crypto", Crypto)
container:Register("MathUtil", MathUtil)
container:Register("SpatialUtil", SpatialUtil)
container:Register("HttpUtil", HttpUtil)
container:Register("Import", import)

local scheduler = Scheduler.new()
scheduler:Init()
masterJanitor:Add(scheduler)
container:Register("Scheduler", scheduler)

-- Register Services
local auth = container:Register("AuthService", AuthService.new())
local config = container:Register("ConfigService", ConfigService.new())
local entity = container:Register("EntityService", EntityService.new())
local input = container:Register("InputService", InputService.new())
local locomotion = container:Register("LocomotionService", LocomotionService.new())
local combat = container:Register("CombatService", CombatService.new())
local fling = container:Register("FlingService", FlingService.new())
local visuals = container:Register("VisualsService", VisualsService.new())
local overlay = container:Register("OverlayService", OverlayService.new())
local environment = container:Register("EnvironmentService", EnvironmentService.new())
local server = container:Register("ServerService", ServerService.new())
local games = container:Register("GameLoader", GameLoader.new())

local theme = container:Register("ThemeEngine", ThemeEngine.new())
local ui = container:Register("UIManager", UIManager.new())

-- Application Launcher
local function startApp()
	print("[B0Xaz] Initializing services...")
	container:InitAll()
	container:StartAll()

	config:LoadProfile(Constants.AUTOLOAD_FILE or "_autoload")
	config:StartAutosave(2.0)

	print("[B0Xaz] ✓ Universal Hub loaded successfully.")
end

-- Licensing Verification Check
local authenticated, _, _ = auth:LoadAndVerify()

if authenticated then
	startApp()
else
	AuthModal.Show(auth, theme, function()
		startApp()
	end)
end
