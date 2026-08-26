-- ════════════════════════════════════════════════════════════════════════════
-- Bootstrap.lua
-- Master Bootstrapper, Dependency Resolver, and Application Lifecycle Gate
-- ════════════════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")

-- Wait for engine loading
if not game:IsLoaded() then game.Loaded:Wait() end
if not Players.LocalPlayer then Players:GetPropertyChangedSignal("LocalPlayer"):Wait() end

-- 1. Dependency Resolution & Core Utilities
local Janitor = require(script.Parent.Core.Janitor)
local Signal = require(script.Parent.Core.Signal)
local Container = require(script.Parent.Core.Container)
local Scheduler = require(script.Parent.Core.Scheduler)

local Constants = require(script.Parent.Shared.Constants)
local Crypto = require(script.Parent.Shared.Crypto)
local MathUtil = require(script.Parent.Shared.MathUtil)
local SpatialUtil = require(script.Parent.Shared.SpatialUtil)
local HttpUtil = require(script.Parent.Shared.HttpUtil)

-- 2. Domain Services
local AuthService = require(script.Parent.Services.AuthService)
local ConfigService = require(script.Parent.Services.ConfigService)
local EntityService = require(script.Parent.Services.EntityService)
local InputService = require(script.Parent.Services.InputService)
local LocomotionService = require(script.Parent.Services.LocomotionService)
local CombatService = require(script.Parent.Services.CombatService)
local FlingService = require(script.Parent.Services.FlingService)
local VisualsService = require(script.Parent.Services.VisualsService)
local OverlayService = require(script.Parent.Services.OverlayService)
local EnvironmentService = require(script.Parent.Services.EnvironmentService)
local ServerService = require(script.Parent.Services.ServerService)
local GameLoader = require(script.Parent.Games.GameLoader)

-- 3. UI Framework & Presenters
local ThemeEngine = require(script.Parent.UI.ThemeEngine)
local UIManager = require(script.Parent.UI.UIManager)
local AuthModal = require(script.Parent.UI.Components.Modals.AuthModal)

-- Session Invalidation & Cleanup
local env = (getgenv and getgenv()) or _G
if env.B0XazActiveJanitor then
	pcall(function() env.B0XazActiveJanitor:Destroy() end)
end

local masterJanitor = Janitor.new()
env.B0XazActiveJanitor = masterJanitor

-- Build Container
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

-- Startup Application Routine
local function startApp()
	print("[B0Xaz] Launching suite subsystems...")
	container:InitAll()
	container:StartAll()

	-- Load Autoload Profile
	config:LoadProfile(Constants.AUTOLOAD_FILE or "_autoload")
	config:StartAutosave(2.0)

	print("[B0Xaz] ✓ Suite operational.")
end

-- Key Authentication Gate
local authenticated, _, _ = auth:LoadAndVerify()

if authenticated then
	startApp()
else
	AuthModal.Show(auth, theme, function()
		startApp()
	end)
end
