-- ════════════════════════════════════════════════════════════════════════════
-- Init.lua (V2 ACTIVE - DEBUG VERSION)
-- ════════════════════════════════════════════════════════════════════════════

local env = (getgenv and getgenv()) or _G
-- I am hardcoding 'Root/' into the base URL so it cannot fail.
local baseUrl = "https://raw.githubusercontent.com/B0Xaz1/Rewrite/main/Root/"

local moduleCache = {}

local function import(path)
	local cleanPath = path:gsub("^%./", ""):gsub("^/", "")
	if moduleCache[cleanPath] then return moduleCache[cleanPath] end

	-- This URL construction is now absolute
	local targetUrl = baseUrl .. cleanPath .. "?t=" .. tostring(math.random(1, 100000))
	
	-- Note: Using [V2] so you know for sure the new script is running
	print("[B0Xaz V2] Attempting: " .. targetUrl)

	local ok, result = pcall(function() return game:HttpGet(targetUrl) end)
	
	if not ok or result:find("404: Not Found") or #result < 10 then
		error("[B0Xaz] 404: File not found at " .. targetUrl)
	end

	local chunk, compileErr = loadstring(result, "@" .. cleanPath)
	if not chunk then error("[B0Xaz] Syntax Error: " .. tostring(compileErr)) end

	local ok2, module = pcall(chunk)
	if not ok2 then error("[B0Xaz] Runtime Error: " .. tostring(module)) end

	moduleCache[cleanPath] = module
	return module
end

-- Wait for Game
if not game:IsLoaded() then game.Loaded:Wait() end
local Players = game:GetService("Players")
if not Players.LocalPlayer then while not Players.LocalPlayer do task.wait(0.1) end end

print("[B0Xaz V2] Starting Framework...")

-- 1. Core
local Janitor = import("Core/Janitor.lua")
local Signal = import("Core/Signal.lua")
local Container = import("Core/Container.lua")
local Scheduler = import("Core/Scheduler.lua")

-- 2. Shared
local Constants = import("Shared/Constants.lua")
local Crypto = import("Shared/Crypto.lua")
local MathUtil = import("Shared/MathUtil.lua")
local SpatialUtil = import("Shared/SpatialUtil.lua")
local HttpUtil = import("Shared/HttpUtil.lua")

-- 3. Services
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

-- 4. UI
local ThemeEngine = import("UI/ThemeEngine.lua")
local UIManager = import("UI/UIManager.lua")
local AuthModal = import("UI/Components/Modals/AuthModal.lua")

-- Global Cleanup
if env.B0XazActiveJanitor then pcall(function() env.B0XazActiveJanitor:Destroy() end) end
local masterJanitor = Janitor.new()
env.B0XazActiveJanitor = masterJanitor

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

container:Register("AuthService", AuthService.new())
local config = container:Register("ConfigService", ConfigService.new())
container:Register("EntityService", EntityService.new())
container:Register("InputService", InputService.new())
container:Register("LocomotionService", LocomotionService.new())
container:Register("CombatService", CombatService.new())
container:Register("FlingService", FlingService.new())
container:Register("VisualsService", VisualsService.new())
container:Register("OverlayService", OverlayService.new())
container:Register("EnvironmentService", EnvironmentService.new())
container:Register("ServerService", ServerService.new())
container:Register("GameLoader", GameLoader.new())
local theme = container:Register("ThemeEngine", ThemeEngine.new())
container:Register("UIManager", UIManager.new())

container:InitAll()
container:StartAll()

local auth = container:Get("AuthService")
local authenticated, _, _ = auth:LoadAndVerify()

local function launch()
	config:LoadProfile("_autoload")
	config:StartAutosave(2.0)
	print("[B0Xaz V2] ✓ Success.")
end

if authenticated then
	launch()
else
	AuthModal.Show(auth, theme, launch)
end
