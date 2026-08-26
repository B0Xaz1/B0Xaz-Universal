-- ════════════════════════════════════════════════════════════════════════════
-- Init.lua (Magic Virtual-Require Bootstrapper)
-- ════════════════════════════════════════════════════════════════════════════

local env = (getgenv and getgenv()) or _G
local branch = env.B0XazRef or "main"
local baseUrl = "https://raw.githubusercontent.com/B0Xaz1/Rewrite/" .. branch .. "/Root/"

local moduleCache = {}
local nativeRequire = require

local function httpGet(url)
	local cacheBustUrl = url .. (url:find("%?") and "&" or "?") .. "t=" .. tostring(math.random(1, 100000))
	return game:HttpGet(cacheBustUrl)
end

-- Virtual Instance graph:
-- Modules in the tree are written like real Roblox code, i.e. they pull
-- siblings with require(script.Parent.Child.Module). Each loaded module gets
-- a synthetic 'script' that mirrors the on-disk hierarchy, so those paths
-- resolve to virtual paths and are routed back into import().
local function makeVirtualNode(path, name)
	local node = {}
	node.__virtualPath = path
	setmetatable(node, {
		__index = function(_, key)
			if key == "Name" then
				return name
			elseif key == "Parent" then
				-- Only the Root folder itself (path "") parents into the game;
				-- every top-level folder (Core, UI, Games, ...) parents into Root.
				if path == "" then
					return game
				end
				local parentPath = path:match("^(.+)/[^/]+$") or ""
				return makeVirtualNode(parentPath, parentPath ~= "" and parentPath:match("[^/]+$") or "Root")
			end
			return makeVirtualNode(path .. "/" .. key, key)
		end,
	})
	return node
end

-- Virtual Module Loader
local function import(path)
	-- Normalize path (handles both "Core/Janitor" and "Core/Janitor.lua")
	local cleanPath = path:gsub("^%./", ""):gsub("^/", "")
	if not cleanPath:find("%.lua$") then cleanPath = cleanPath .. ".lua" end
	
	if moduleCache[cleanPath] then return moduleCache[cleanPath] end

	local targetUrl = baseUrl .. cleanPath
	local ok, result = pcall(httpGet, targetUrl)
	
	if not ok or result:find("404: Not Found") or #result < 10 then
		-- Try one fallback: lowercase
		targetUrl = baseUrl .. cleanPath:lower()
		ok, result = pcall(httpGet, targetUrl)
	end

	if not ok or result:find("404: Not Found") or #result < 10 then
		error("[B0Xaz] 404: File not found at " .. targetUrl)
	end

	local chunk, compileErr = loadstring(result, "@" .. cleanPath)
	if not chunk then error("[B0Xaz] Syntax Error: " .. tostring(compileErr)) end

	-- MAGIC INJECTION:
	-- This replaces 'require' inside the module with our 'import' function
	-- and provides a synthetic 'script' that mirrors the on-disk hierarchy,
	-- so require(script.Parent.Child.Module) resolves exactly like it would
	-- in a real Roblox tree. Plain string paths and real Instances still work.
	local proxyScript = makeVirtualNode(cleanPath, cleanPath:match("[^/]+$"))
	setfenv(chunk, setmetatable({
		require = function(arg)
			if type(arg) == "string" then
				return import(arg)
			end
			if type(arg) == "table" and rawget(arg, "__virtualPath") then
				return import(arg.__virtualPath)
			end
			return nativeRequire(arg)
		end,
		script = proxyScript,
	}, { __index = getfenv(0) }))

	local ok2, module = pcall(chunk)
	if not ok2 then error("[B0Xaz] Runtime Error in " .. cleanPath .. ": " .. tostring(module)) end

	moduleCache[cleanPath] = module
	return module
end

-- Wait for Game
if not game:IsLoaded() then game.Loaded:Wait() end
local Players = game:GetService("Players")
if not Players.LocalPlayer then while not Players.LocalPlayer do task.wait(0.1) end end

print("[B0Xaz] Bootstrapping System...")

-- 1. Load Core
local Janitor = import("Core/Janitor")
local Signal = import("Core/Signal")
local Container = import("Core/Container")
local Scheduler = import("Core/Scheduler")

-- 2. Load Shared
local Constants = import("Shared/Constants")
local Crypto = import("Shared/Crypto")
local MathUtil = import("Shared/MathUtil")
local SpatialUtil = import("Shared/SpatialUtil")
local HttpUtil = import("Shared/HttpUtil")

-- 3. Services
local AuthService = import("Services/AuthService")
local ConfigService = import("Services/ConfigService")
local EntityService = import("Services/EntityService")
local InputService = import("Services/InputService")
local LocomotionService = import("Services/LocomotionService")
local CombatService = import("Services/CombatService")
local FlingService = import("Services/FlingService")
local VisualsService = import("Services/VisualsService")
local OverlayService = import("Services/OverlayService")
local EnvironmentService = import("Services/EnvironmentService")
local ServerService = import("Services/ServerService")
local GameLoader = import("Games/GameLoader")

-- 4. UI
local ThemeEngine = import("UI/ThemeEngine")
local UIManager = import("UI/UIManager")
local AuthModal = import("UI/Components/Modals/AuthModal")

-- Teardown
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
	print("[B0Xaz] ✓ Universal Hub Online.")
end

if authenticated then
	launch()
else
	AuthModal.Show(auth, theme, launch)
end
