-- // init.lua (Main Loader)
local BASE_URL = "https://raw.githubusercontent.com/B0Xaz1/B0Xaz-Universal/main/"
local LOAD_TIMEOUT = 15
local FETCH_DELAY = 0.05
local RETRY_ATTEMPTS = 2

local PATHS = {
	CLEANUP             = "src/Cleanup.lua",
	CONFIG              = "src/Config.lua",
	UTILS               = "src/Utils.lua",
	CONTEXT             = "src/Context.lua",
	RUNTIME             = "src/Runtime.lua",

	DRAWING_MANAGER     = "src/Visuals/DrawingManager.lua",
	OVERLAY_MANAGER     = "src/Visuals/OverlayManager.lua",

	THEME               = "src/UI/Theme.lua",
	UI_ENGINE           = "src/UI/UI.lua",
	BUILD_UI            = "src/UI/BuildUI.lua",

	KEY_SYSTEM          = "src/Systems/KeySystem.lua",
	CONFIG_SYSTEM       = "src/Systems/ConfigSystem.lua",
	AIMBOT_SYSTEM       = "src/Systems/AimbotSystem.lua",
	ESP_SYSTEM          = "src/Systems/ESPSystem.lua",
	FLING_SYSTEM        = "src/Systems/FlingSystem.lua",
	FLY_SYSTEM          = "src/Systems/FlySystem.lua",
	MOVEMENT_SYSTEM     = "src/Systems/MovementSystem.lua",
	PERFORMANCE_SYSTEM  = "src/Systems/PerformanceSystem.lua",
	PLAYERS_SYSTEM      = "src/Systems/PlayersSystem.lua",

	GAME_LOADER         = "src/Games/Loader.lua",
}

print("[B0Xaz] Initializing Universal Suite...")

local Players = game:GetService("Players")

if not game:IsLoaded() then
	pcall(function() game.Loaded:Wait() end)
end

if not Players.LocalPlayer then
	local t0 = os.clock()
	while not Players.LocalPlayer and (os.clock() - t0) < LOAD_TIMEOUT do
		task.wait(0.1)
	end
end

local env = (getgenv and getgenv()) or _G
local cache = {}
local lastFetchAt = 0

local function isValidSource(code)
	if type(code) ~= "string" or #code < 8 then
		return false, "empty response"
	end
	local head = code:sub(1, 80):lower()
	if head:find("404", 1, true) or head:find("not found", 1, true) then
		return false, "404 not found"
	end
	if head:find("<!doctype", 1, true) or head:find("<html", 1, true) then
		return false, "html page"
	end
	return true, nil
end

local function throttle()
	local now = os.clock()
	local waitFor = FETCH_DELAY - (now - lastFetchAt)
	if waitFor > 0 then
		task.wait(waitFor)
	end
	lastFetchAt = os.clock()
end

local function fetchSource(path)
	local base = env.B0XazBaseURL or BASE_URL
	local clean = path:gsub("^%./", ""):gsub("^/", "")
	local url = base .. clean

	local lastErr = "unknown"
	for attempt = 1, RETRY_ATTEMPTS do
		throttle()
		local fullUrl = url
		if attempt > 1 then
			fullUrl = url .. (url:find("?", 1, true) and "&" or "?") .. "t=" .. tostring(os.time())
		end

		local ok, response = pcall(function()
			return game:HttpGet(fullUrl)
		end)

		if ok then
			local valid, reason = isValidSource(response)
			if valid then
				return response, nil
			end
			lastErr = reason or "invalid body"
		else
			lastErr = "HttpGet error: " .. tostring(response)
		end

		task.wait(0.1 * attempt)
	end

	return nil, lastErr
end

local function import(path, isOptional)
	if cache[path] ~= nil then
		return cache[path] or nil
	end

	local source, fetchErr = fetchSource(path)
	if not source then
		cache[path] = false
		if not isOptional then
			warn("[B0Xaz] Fetch failed: " .. path .. " (" .. tostring(fetchErr) .. ")")
		end
		return nil
	end

	local chunk, compileErr = loadstring(source, "@" .. path)
	if not chunk then
		cache[path] = false
		warn("[B0Xaz] Compile failed: " .. path .. " → " .. tostring(compileErr))
		return nil
	end

	local ok, result = pcall(chunk)
	if not ok then
		cache[path] = false
		warn("[B0Xaz] Runtime failed: " .. path .. " → " .. tostring(result))
		return nil
	end

	if result == nil then
		cache[path] = false
		warn("[B0Xaz] Module returned nil: " .. path)
		return nil
	end

	print("[B0Xaz] Loaded: " .. path)
	cache[path] = result
	return result
end

local function callFactory(factory, ...)
	if type(factory) ~= "function" then
		return nil
	end
	local ok, result = pcall(factory, ...)
	if ok then
		return result
	end
	warn("[B0Xaz] Factory error: " .. tostring(result))
	return nil
end

-- 1) Cleanup
do
	local fn = import(PATHS.CLEANUP, true)
	if type(fn) == "function" then pcall(fn) end
end

-- 2) Config & Default Lighting
local configData, defaultLighting = {}, {}
do
	local fn = import(PATHS.CONFIG)
	if type(fn) == "function" then
		local ok, cfg, lighting = pcall(fn)
		if ok then
			configData = cfg or {}
			defaultLighting = lighting or {}
		end
	end
end

-- 3) Utils
local utils = callFactory(import(PATHS.UTILS), configData) or {}
if type(utils.WaitForGameLoad) == "function" then
	pcall(utils.WaitForGameLoad, LOAD_TIMEOUT)
end

-- 4) Drawing Manager
local drawingManager = callFactory(import(PATHS.DRAWING_MANAGER)) or { Available = false }

-- 5) Context
local context = callFactory(import(PATHS.CONTEXT), configData, defaultLighting, utils, drawingManager) or {}
context.import = import
context.CONFIG = context.CONFIG or configData
context.Utils = context.Utils or utils
context.DrawingManager = context.DrawingManager or drawingManager
context.DefaultLighting = context.DefaultLighting or defaultLighting

-- 6) Theme
do
	local fn = import(PATHS.THEME)
	if type(fn) == "function" then
		local ok, theme, manager = pcall(fn)
		if ok then
			context.Theme = theme or {}
			context.ThemeManager = manager or {}
		end
	end
end
context.Theme = context.Theme or {}
context.ThemeManager = context.ThemeManager or {}

-- 7) UI Engine
context.UIEngine = callFactory(import(PATHS.UI_ENGINE), context, context.Theme) or {}

-- 8) Key System
context.KeySystem = callFactory(import(PATHS.KEY_SYSTEM), context, import) or {}

-- 9) Feature Systems
local function initSystem(path)
	return callFactory(import(path), context) or {}
end

context.ConfigSystem      = initSystem(PATHS.CONFIG_SYSTEM)
context.AimbotSystem      = initSystem(PATHS.AIMBOT_SYSTEM)
context.ESPSystem         = initSystem(PATHS.ESP_SYSTEM)
context.FlingSystem       = initSystem(PATHS.FLING_SYSTEM)
context.FlySystem         = initSystem(PATHS.FLY_SYSTEM)
context.MovementSystem    = initSystem(PATHS.MOVEMENT_SYSTEM)
context.PerformanceSystem = initSystem(PATHS.PERFORMANCE_SYSTEM)
context.PlayersSystem     = initSystem(PATHS.PLAYERS_SYSTEM)
context.OverlayManager    = initSystem(PATHS.OVERLAY_MANAGER)

-- 10) Game Loader
context.GameLoader = callFactory(import(PATHS.GAME_LOADER), context, import) or {
	GetDisplayName = function() return "Universal" end,
	IsSupported = function() return false end,
	Load = function() return nil end,
	BuildUI = function() return false, "Loader unavailable" end,
	Update = function() end,
	Destroy = function() end,
}

env.B0XazContext = context

----------------------------------------------------------------
-- Application Launch
----------------------------------------------------------------
local function startApplication()
	print("[B0Xaz] Launching UI & runtime...")

	if context.ESPSystem and context.ESPSystem.InitializeAll then
		pcall(context.ESPSystem.InitializeAll)
	end
	if context.ConfigSystem and context.ConfigSystem.LoadAutoload then
		pcall(context.ConfigSystem.LoadAutoload)
	end
	if context.ConfigSystem and context.ConfigSystem.StartAutosaveLoop then
		pcall(context.ConfigSystem.StartAutosaveLoop)
	end

	local buildUi = import(PATHS.BUILD_UI)
	if type(buildUi) == "function" then
		local ok, err = pcall(buildUi, context)
		if not ok then warn("[B0Xaz] BuildUI error: " .. tostring(err)) end
	end

	local runtime = import(PATHS.RUNTIME)
	if type(runtime) == "function" then
		local ok, err = pcall(runtime, context)
		if not ok then warn("[B0Xaz] Runtime error: " .. tostring(err)) end
	end

	print("[B0Xaz] Universal Hub loaded.")
end

local verified = false
if context.KeySystem and context.KeySystem.LoadAndVerify then
	local ok, result = pcall(context.KeySystem.LoadAndVerify)
	verified = ok and result == true
end

if verified then
	startApplication()
elseif context.UIEngine and type(context.UIEngine.CreateKeyPrompt) == "function" then
	local ok, err = pcall(
		context.UIEngine.CreateKeyPrompt,
		context.UIEngine,
		context.KeySystem,
		context.Theme,
		startApplication,
		""
	)
	if not ok then
		warn("[B0Xaz] Key prompt failed: " .. tostring(err) .. " — launching anyway")
		startApplication()
	end
else
	startApplication()
end
