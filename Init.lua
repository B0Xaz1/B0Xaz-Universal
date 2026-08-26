-- ════════════════════════════════════════════════════════════════════════════
-- Init.lua (Final Path Fix - Searching in 'Root/' folder)
-- ════════════════════════════════════════════════════════════════════════════

local env = (getgenv and getgenv()) or _G
local branch = env.B0XazRef or "main"
local baseUrl = env.B0XazBaseURL or ("https://raw.githubusercontent.com/B0Xaz1/Rewrite/" .. branch .. "/")

local moduleCache = {}

local function httpGet(url)
	local cacheBustUrl = url .. (url:find("%?") and "&" or "?") .. "t=" .. tostring(os.time())
	if game and game.HttpGet then return game:HttpGet(cacheBustUrl) end
	local req = request or http_request or (syn and syn.request)
	if req then
		local res = req({ Url = cacheBustUrl, Method = "GET" })
		return res and (res.Body or res.body)
	end
	error("No HttpGet capability.")
end

local function isValidLua(source)
	if type(source) ~= "string" or #source < 10 then return false end
	local lower = source:sub(1, 150):lower()
	if lower:find("404: not found", 1, true) or lower:find("404 not found", 1, true) then return false end
	if lower:find("<!doctype", 1, true) or lower:find("<html", 1, true) then return false end
	return true
end

local function getCandidatePaths(relativePath)
	local clean = relativePath:gsub("^%./", ""):gsub("^/", "")
	-- We add "Root/" because your screenshot shows everything is inside that folder
	return {
		"Root/" .. clean, 
		clean,
		"src/" .. clean,
		"Root/" .. clean:lower(),
		clean:lower()
	}
end

local function import(path)
	if moduleCache[path] then return moduleCache[path] end

	local candidates = getCandidatePaths(path)
	local source = nil
	local matchedPath = nil

	for _, candidate in ipairs(candidates) do
		local targetUrl = baseUrl .. candidate
		local ok, result = pcall(httpGet, targetUrl)
		if ok and isValidLua(result) then
			source = result
			matchedPath = candidate
			break
		end
	end

	if not source then
		error("[B0Xaz] 404: Could not find '" .. path .. "' in Root/ or base folder. Check GitHub!")
	end

	print("[B0Xaz] Success: " .. matchedPath)
	local chunk, err = loadstring(source, "@" .. matchedPath)
	if not chunk then error(err) end
	local ok, mod = pcall(chunk)
	if not ok then error(mod) end

	moduleCache[path] = mod
	return mod
end

-- Start Logic
if not game:IsLoaded() then game.Loaded:Wait() end
local Players = game:GetService("Players")
if not Players.LocalPlayer then while not Players.LocalPlayer do task.wait(0.1) end end

print("[B0Xaz] Loading Universal Suite...")

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

local function startApp()
	container:InitAll()
	container:StartAll()
	config:LoadProfile("_autoload")
	config:StartAutosave(2.0)
end

local auth = container:Get("AuthService")
local authenticated = auth:LoadAndVerify()

if authenticated then
	startApp()
else
	AuthModal.Show(auth, theme, startApp)
end
