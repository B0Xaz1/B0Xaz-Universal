-- ════════════════════════════════════════════════════════════════════════════
-- init.lua (Executor Bootstrapper)
-- Dynamically fetches and boots all modular framework components
-- ════════════════════════════════════════════════════════════════════════════

local env = (getgenv and getgenv()) or _G

-- Base URL configuration (fallback to main branch if not set)
local branch = env.B0XazRef or "main"
local baseUrl = env.B0XazBaseURL or ("https://raw.githubusercontent.com/B0Xaz1/testmenu/" .. branch .. "/")

local moduleCache = {}

-- Polymorphic HttpGet wrapper
local function httpGet(url)
	if game and game.HttpGet then
		return game:HttpGet(url)
	end
	local req = request or http_request or (syn and syn.request)
	if req then
		local res = req({ Url = url, Method = "GET" })
		return res and (res.Body or res.body)
	end
	error("No valid HttpGet capability found in executor.")
end

-- Remote / Virtual Module Loader
local function import(path)
	local cleanPath = path:gsub("^%./", ""):gsub("^/", "")
	if moduleCache[cleanPath] then
		return moduleCache[cleanPath]
	end

	local url = baseUrl .. cleanPath
	local source = nil

	for attempt = 1, 3 do
		local ok, result = pcall(httpGet, url .. (attempt > 1 and ("?t=" .. os.time()) or ""))
		if ok and type(result) == "string" and #result > 10 and not result:find("<!DOCTYPE") then
			source = result
			break
		end
		task.wait(0.1 * attempt)
	end

	if not source then
		error("[B0Xaz Loader] Failed to fetch remote module: " .. cleanPath)
	end

	local chunk, compileErr = loadstring(source, "@" .. cleanPath)
	if not chunk then
		error("[B0Xaz Loader] Syntax error in " .. cleanPath .. ": " .. tostring(compileErr))
	end

	local ok, module = pcall(chunk)
	if not ok then
		error("[B0Xaz Loader] Runtime error in " .. cleanPath .. ": " .. tostring(module))
	end

	moduleCache[cleanPath] = module
	return module
end

-- Wait for game environment readiness
if not game:IsLoaded() then game.Loaded:Wait() end
local Players = game:GetService("Players")
if not Players.LocalPlayer then
	while not Players.LocalPlayer do task.wait(0.1) end
end

print("[B0Xaz] Loading Universal Suite Framework...")

-- 1. Load Core Engine
local Janitor = import("src/Core/Janitor.lua")
local Signal = import("src/Core/Signal.lua")
local Container = import("src/Core/Container.lua")
local Scheduler = import("src/Core/Scheduler.lua")

-- 2. Load Shared Utilities
local Constants = import("src/Shared/Constants.lua")
local Crypto = import("src/Shared/Crypto.lua")
local MathUtil = import("src/Shared/MathUtil.lua")
local SpatialUtil = import("src/Shared/SpatialUtil.lua")
local HttpUtil = import("src/Shared/HttpUtil.lua")

-- 3. Load Domain Services
local AuthService = import("src/Services/AuthService.lua")
local ConfigService = import("src/Services/ConfigService.lua")
local EntityService = import("src/Services/EntityService.lua")
local InputService = import("src/Services/InputService.lua")
local LocomotionService = import("src/Services/LocomotionService.lua")
local CombatService = import("src/Services/CombatService.lua")
local FlingService = import("src/Services/FlingService.lua")
local VisualsService = import("src/Services/VisualsService.lua")
local OverlayService = import("src/Services/OverlayService.lua")
local EnvironmentService = import("src/Services/EnvironmentService.lua")
local ServerService = import("src/Services/ServerService.lua")
local GameLoader = import("src/Games/GameLoader.lua")

-- 4. Load UI Framework
local ThemeEngine = import("src/UI/ThemeEngine.lua")
local UIManager = import("src/UI/UIManager.lua")
local AuthModal = import("src/UI/Components/Modals/AuthModal.lua")

-- Teardown prior session if present
if env.B0XazActiveJanitor then
	pcall(function() env.B0XazActiveJanitor:Destroy() end)
end

local masterJanitor = Janitor.new()
env.B0XazActiveJanitor = masterJanitor

-- Setup IoC Container
local container = Container.new()
container:Register("Janitor", masterJanitor)
container:Register("Signal", Signal)
container:Register("Constants", Constants)
container:Register("Crypto", Crypto)
container:Register("MathUtil", MathUtil)
container:Register("SpatialUtil", SpatialUtil)
container:Register("HttpUtil", HttpUtil)

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

-- Application Launcher Routine
local function startApp()
	print("[B0Xaz] Initializing services...")
	container:InitAll()
	container:StartAll()

	-- Load Autoload Configuration
	config:LoadProfile(Constants.AUTOLOAD_FILE or "_autoload")
	config:StartAutosave(2.0)

	print("[B0Xaz] ✓ Suite fully operational.")
end

-- Key Authentication Check
local authenticated, _, _ = auth:LoadAndVerify()

if authenticated then
	startApp()
else
	AuthModal.Show(auth, theme, function()
		startApp()
	end)
end
