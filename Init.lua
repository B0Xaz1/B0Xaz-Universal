-- ════════════════════════════════════════════════════════════════════════════
-- init.lua (Smart Auto-Path Executor Bootstrapper)
-- Dynamically fetches and boots all modular framework components with 404 fallbacks
-- ════════════════════════════════════════════════════════════════════════════

local env = (getgenv and getgenv()) or _G

-- Base URL configuration
local branch = env.B0XazRef or "main"
local baseUrl = env.B0XazBaseURL or ("https://raw.githubusercontent.com/B0Xaz1/testmenu/" .. branch .. "/")

local moduleCache = {}

-- Safe HttpGet wrapper
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

-- Validate Lua source code string
local function isValidLua(source)
	if type(source) ~= "string" or #source < 10 then return false end
	local lower = source:sub(1, 100):lower()
	if lower:find("404: not found", 1, true) or lower:find("404 not found", 1, true) then return false end
	if lower:find("<!doctype", 1, true) or lower:find("<html", 1, true) then return false end
	return true
end

-- Fetch source code from URL with fallback retry logic
local function fetchSource(relativePath)
	local cleanPath = relativePath:gsub("^%./", ""):gsub("^/", "")
	
	-- Paths to attempt: primary provided path, then path with/without 'src/' prefix
	local candidatePaths = { cleanPath }
	if cleanPath:sub(1, 4) == "src/" then
		table.insert(candidatePaths, cleanPath:sub(5))
	else
		table.insert(candidatePaths, "src/" .. cleanPath)
	end

	for _, path in ipairs(candidatePaths) do
		local url = baseUrl .. path
		for attempt = 1, 2 do
			local requestUrl = url .. (attempt > 1 and ("?t=" .. os.time()) or "")
			local ok, result = pcall(httpGet, requestUrl)
			if ok and isValidLua(result) then
				return result, path
			end
			task.wait(0.05)
		end
	end

	return nil, cleanPath
end

-- Remote / Virtual Module Loader
local function import(path)
	if moduleCache[path] then
		return moduleCache[path]
	end

	local source, resolvedPath = fetchSource(path)
	if not source then
		error("[B0Xaz Loader] File not found on GitHub (404): " .. tostring(path))
	end

	local chunk, compileErr = loadstring(source, "@" .. resolvedPath)
	if not chunk then
		error("[B0Xaz Loader] Syntax error in " .. resolvedPath .. ": " .. tostring(compileErr))
	end

	local ok, module = pcall(chunk)
	if not ok then
		error("[B0Xaz Loader] Runtime error in " .. resolvedPath .. ": " .. tostring(module))
	end

	moduleCache[path] = module
	return module
end

-- Wait for game environment readiness
if not game:IsLoaded() then game.Loaded:Wait() end
local Players = game:GetService("Players")
if not Players.LocalPlayer then
	while not Players.LocalPlayer do task.wait(0.1) end
end

print("[B0Xaz] Loading Universal Suite Framework...")

-- 1. Core Framework Modules
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

-- Teardown prior active sessions
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

	-- Load Autoload Profile
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
