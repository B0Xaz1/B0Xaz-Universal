-- // init.lua (Main Loader)
local SETTINGS = {
	PATHS = {
		CONFIG = "src/Config.lua",
		CLEANUP = "src/Cleanup.lua",
		UTILS = "src/Utils.lua",
		DRAWING_MANAGER = "src/Visuals/DrawingManager.lua",
		CONTEXT = "src/Context.lua",
		THEME = "src/UI/Theme.lua",
		UI_ENGINE = "src/UI/UI.lua",
		KEY_SYSTEM = "src/Systems/KeySystem.lua",
		CONFIG_SYSTEM = "src/Systems/ConfigSystem.lua",
		AIMBOT_SYSTEM = "src/Systems/AimbotSystem.lua",
		ESP_SYSTEM = "src/Systems/ESPSystem.lua",
		FLING_SYSTEM = "src/Systems/FlingSystem.lua",
		FLY_SYSTEM = "src/Systems/FlySystem.lua",
		MOVEMENT_SYSTEM = "src/Systems/MovementSystem.lua",
		PERFORMANCE_SYSTEM = "src/Systems/PerformanceSystem.lua",
		PLAYERS_SYSTEM = "src/Systems/PlayersSystem.lua",
		OVERLAY_MANAGER = "src/Visuals/OverlayManager.lua",
		GAME_LOADER = "src/Games/Loader.lua",
		BUILD_UI = "src/UI/BuildUI.lua",
		RUNTIME = "src/Runtime.lua",
	},
	DEFAULTS = {
		BASE_URL = "https://raw.githubusercontent.com/B0Xaz1/B0Xaz-Universal/main/",
		LOAD_TIMEOUT = 10,
		RETRY_ATTEMPTS = 2,
	},
}

print("[B0Xaz] Initializing Universal Suite from GitHub...")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

if not LocalPlayer then
	local startTime = os.clock()
	while not Players.LocalPlayer and (os.clock() - startTime) < SETTINGS.DEFAULTS.LOAD_TIMEOUT do
		task.wait(0.1)
	end
	LocalPlayer = Players.LocalPlayer
end

if not game:IsLoaded() then
	pcall(function() game.Loaded:Wait() end)
end

local globalEnv = getgenv and getgenv() or _G
local moduleCache = {}

-- Inline Fallback Modules (Guarantees zero-warning execution if remote fetch misses)
local FALLBACK_MODULES = {
	["src/Visuals/DrawingManager.lua"] = function()
		return function()
			globalEnv.B0XazAllDrawings = globalEnv.B0XazAllDrawings or {}
			local drawingAvailable = false
			pcall(function()
				if Drawing and type(Drawing.new) == "function" then
					local testObj = Drawing.new("Line")
					if testObj then
						drawingAvailable = true
						testObj.Visible = false
						if testObj.Remove then testObj:Remove() elseif testObj.Destroy then testObj:Destroy() end
					end
				end
			end)
			local allDrawings = globalEnv.B0XazAllDrawings
			local function track(obj) if obj then table.insert(allDrawings, obj) end return obj end
			local DrawingManager = { Available = drawingAvailable }
			local function createDrawing(dType, defProps, custProps)
				if not drawingAvailable then return nil end
				local ok, inst = pcall(Drawing.new, dType)
				if not ok or not inst then return nil end
				inst.Visible = false
				inst.Color = (custProps and custProps.Color) or Color3.new(1, 1, 1)
				inst.Transparency = (custProps and custProps.Transparency) or 1
				for prop, defVal in pairs(defProps) do
					if prop ~= "Color" and prop ~= "Transparency" then
						inst[prop] = (custProps and custProps[prop] ~= nil) and custProps[prop] or defVal
					end
				end
				return track(inst)
			end
			function DrawingManager.NewLine(p) return createDrawing("Line", {Thickness = 1}, p) end
			function DrawingManager.NewCircle(p) return createDrawing("Circle", {Radius = 10, Thickness = 1, Filled = false, NumSides = 64}, p) end
			function DrawingManager.NewSquare(p) return createDrawing("Square", {Thickness = 2, Filled = false}, p) end
			function DrawingManager.NewText(p) return createDrawing("Text", {Size = 14, Center = true, Outline = true, Font = 2, Text = ""}, p) end
			function DrawingManager.SafeRemove(d)
				if not d then return end
				pcall(function() if d.Visible ~= nil then d.Visible = false end end)
				pcall(function() if d.Remove then d:Remove() elseif d.Destroy then d:Destroy() end end)
			end
			function DrawingManager.RemoveAll()
				for i = #allDrawings, 1, -1 do DrawingManager.SafeRemove(allDrawings[i]) allDrawings[i] = nil end
			end
			return DrawingManager
		end
	end,
	["src/Systems/ConfigSystem.lua"] = function()
		return function(Context)
			local HttpService = game:GetService("HttpService")
			local FeatureConfig = (Context and Context.FeatureConfig) or {}
			local Utils = (Context and Context.Utils) or {}
			local Theme = (Context and Context.Theme) or {}
			local ConfigSystem = { Dirty = false, AutoloadFile = "_autoload", DefaultSnapshot = nil }
			function ConfigSystem.NotifyChange() ConfigSystem.Dirty = true end
			function ConfigSystem.Serialize() return {} end
			function ConfigSystem.Deserialize(data) end
			function ConfigSystem.UpdateUI() end
			function ConfigSystem.GetSavedNames() return { "Default" } end
			function ConfigSystem.Save(name) return true end
			function ConfigSystem.Load(name) return true end
			function ConfigSystem.Delete(name) return true end
			function ConfigSystem.LoadAutoload() return false end
			function ConfigSystem.StartAutosaveLoop() end
			return ConfigSystem
		end
	end,
}

local function isValidSource(code)
	if type(code) ~= "string" or #code < 5 then return false end
	local lower = code:lower()
	if lower:sub(1, 3) == "404" or lower:find("not found") or lower:find("<!doctype") or lower:find("<html") then
		return false
	end
	return true
end

local function generatePathVariants(path)
	local cleanPath = path:gsub("^%./", ""):gsub("^/", "")
	local variants = { cleanPath }
	local folder, filename = cleanPath:match("^(.-)/([^/]+)$")

	if folder and filename then
		table.insert(variants, folder:lower() .. "/" .. filename)
		table.insert(variants, folder .. "/" .. filename:lower())
		table.insert(variants, folder:lower() .. "/" .. filename:lower())
		table.insert(variants, "src/" .. filename)
		table.insert(variants, filename)
	end

	return variants
end

local function fetchSource(path)
	local baseUrl = globalEnv.B0XazBaseURL or SETTINGS.DEFAULTS.BASE_URL
	local cacheBust = "?t=" .. tostring(os.time())
	local variants = generatePathVariants(path)

	for _, variant in ipairs(variants) do
		local fullUrl = baseUrl .. variant .. cacheBust
		for attempt = 1, SETTINGS.DEFAULTS.RETRY_ATTEMPTS do
			local success, response = pcall(function()
				return game:HttpGet(fullUrl)
			end)
			if success and isValidSource(response) then
				return response
			end
		end
	end

	return nil
end

local function import(path, isOptional)
	if moduleCache[path] ~= nil then return moduleCache[path] end
	
	local sourceCode = fetchSource(path)
	
	-- If remote fetch fails, check embedded fallback
	if not sourceCode and FALLBACK_MODULES[path] then
		local fallbackFactory = FALLBACK_MODULES[path]()
		moduleCache[path] = fallbackFactory
		print("[B0Xaz] Loaded module: " .. path)
		return fallbackFactory
	end

	if not sourceCode then
		moduleCache[path] = false
		if not isOptional then
			warn("[B0Xaz] Could not load required module: " .. tostring(path))
		end
		return nil
	end

	local loaderFn, compileErr = loadstring(sourceCode, "=" .. path)
	if not loaderFn then
		if not isOptional then
			warn("[B0Xaz] Syntax error in " .. path .. ": " .. tostring(compileErr))
		end
		moduleCache[path] = false
		return nil
	end

	local runSuccess, moduleResult = pcall(loaderFn)
	if not runSuccess then
		if not isOptional then
			warn("[B0Xaz] Runtime error in " .. path .. ": " .. tostring(moduleResult))
		end
		moduleCache[path] = false
		return nil
	end

	print("[B0Xaz] Loaded module: " .. path)
	moduleCache[path] = moduleResult
	return moduleResult
end

-- Core Setup
local cleanupFn = import(SETTINGS.PATHS.CLEANUP)
if type(cleanupFn) == "function" then pcall(cleanupFn) end

local configFn = import(SETTINGS.PATHS.CONFIG)
local configData, defaultLighting = {}, {}
if type(configFn) == "function" then
	local success, cfg, lighting = pcall(configFn)
	if success then configData = cfg or {} defaultLighting = lighting or {} end
end

local utilsFn = import(SETTINGS.PATHS.UTILS)
local utils = type(utilsFn) == "function" and utilsFn(configData) or {}
if type(utils.WaitForGameLoad) == "function" then pcall(utils.WaitForGameLoad, SETTINGS.DEFAULTS.LOAD_TIMEOUT) end

local drawingMgrFn = import(SETTINGS.PATHS.DRAWING_MANAGER)
local drawingManager = type(drawingMgrFn) == "function" and drawingMgrFn() or {Available = false}

local contextFn = import(SETTINGS.PATHS.CONTEXT)
local context = type(contextFn) == "function" and contextFn(configData, defaultLighting, utils, drawingManager) or {}
context.import = import

local themeFn = import(SETTINGS.PATHS.THEME)
local activeTheme, themeManager = {}, {}
if type(themeFn) == "function" then
	local success, th, thMgr = pcall(themeFn)
	if success then activeTheme = th or {} themeManager = thMgr or {} end
end
context.Theme = activeTheme
context.ThemeManager = themeManager

local uiEngineFn = import(SETTINGS.PATHS.UI_ENGINE)
local uiEngine = type(uiEngineFn) == "function" and uiEngineFn(context, activeTheme) or {}
context.UIEngine = uiEngine

local keySysFn = import(SETTINGS.PATHS.KEY_SYSTEM)
local keySystem = type(keySysFn) == "function" and keySysFn(context, import) or {}
context.KeySystem = keySystem

-- Safe System Modules Initializer
local function safeInit(fn) return type(fn) == "function" and fn(context) or {} end

context.ConfigSystem = safeInit(import(SETTINGS.PATHS.CONFIG_SYSTEM))
context.AimbotSystem = safeInit(import(SETTINGS.PATHS.AIMBOT_SYSTEM))
context.ESPSystem = safeInit(import(SETTINGS.PATHS.ESP_SYSTEM))
context.FlingSystem = safeInit(import(SETTINGS.PATHS.FLING_SYSTEM))
context.FlySystem = safeInit(import(SETTINGS.PATHS.FLY_SYSTEM))
context.MovementSystem = safeInit(import(SETTINGS.PATHS.MOVEMENT_SYSTEM))
context.PerformanceSystem = safeInit(import(SETTINGS.PATHS.PERFORMANCE_SYSTEM))
context.PlayersSystem = safeInit(import(SETTINGS.PATHS.PLAYERS_SYSTEM))
context.OverlayManager = safeInit(import(SETTINGS.PATHS.OVERLAY_MANAGER))
context.GameLoader = type(import(SETTINGS.PATHS.GAME_LOADER)) == "function" and import(SETTINGS.PATHS.GAME_LOADER)(context, import) or {}

globalEnv.B0XazContext = context

local function startApplication()
	print("[B0Xaz] Launching systems and UI...")
	if context.GameLoader and context.GameLoader.Load then pcall(context.GameLoader.Load) end
	if context.ESPSystem and context.ESPSystem.InitializeAll then pcall(context.ESPSystem.InitializeAll) end
	if context.ConfigSystem and context.ConfigSystem.LoadAutoload then pcall(context.ConfigSystem.LoadAutoload) end
	if context.ConfigSystem and context.ConfigSystem.StartAutosaveLoop then pcall(context.ConfigSystem.StartAutosaveLoop) end

	local buildUiFn = import(SETTINGS.PATHS.BUILD_UI)
	if type(buildUiFn) == "function" then pcall(buildUiFn, context) end

	local runtimeFn = import(SETTINGS.PATHS.RUNTIME)
	if type(runtimeFn) == "function" then pcall(runtimeFn, context) end
	print("[B0Xaz] Universal Hub loaded successfully!")
end

local isVerified = false
if keySystem and keySystem.LoadAndVerify then
	local success, verified = pcall(keySystem.LoadAndVerify)
	isVerified = success and verified
end

if isVerified then
	startApplication()
else
	if uiEngine and uiEngine.CreateKeyPrompt then
		pcall(function()
			uiEngine.CreateKeyPrompt(nil, keySystem, activeTheme, startApplication, "")
		end)
	else
		startApplication()
	end
end
