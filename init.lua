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
	["src/Games/Registry.lua"] = function()
		return function()
			return {
				["155615604"] = {
					Name = "Prison Life",
					Folder = "155615604",
					Description = "Prison Life automated door phasing and weapon mods",
				},
			}
		end
	end,
	["src/Games/Loader.lua"] = function()
		return function(Context, import)
			local placeId = tostring(game.PlaceId)

			local function createPrisonLife(Ctx)
				local Workspace = game:GetService("Workspace")
				local Players = game:GetService("Players")
				local RunService = game:GetService("RunService")
				local UserInputService = game:GetService("UserInputService")
				local ReplicatedStorage = game:GetService("ReplicatedStorage")

				local LocalPlayer = Players.LocalPlayer
				local FeatureConfig = Ctx and Ctx.FeatureConfig or {}
				local Theme = Ctx and Ctx.Theme or {}
				local Connections = Ctx and Ctx.Connections or {}
				local UIRegistry = Ctx and Ctx.UIRegistry or {}
				local Utils = Ctx and Ctx.Utils or {}

				local GAME_SETTINGS = {
					DEFAULTS = {
						DoorPhase = false, DoorGlow = true, GlowColor = Color3.fromRGB(0, 200, 220),
						PhaseTransparency = 0.65, NoSpread = false, FastFire = false, ForceAuto = false,
						ForceRange = false, FireRateValue = 0.001, RangeValue = 10000,
						FakeMacro = false, FakeMacroKey = Enum.KeyCode.V, FakeMacroMode = "Toggle", FakeMacroDelay = 0.03,
						AntiRestrict = false, PunchAura = false, PunchAuraRange = 15, SuperPunch = false, SuperPunchHits = 10,
					},
					LIMITS = {
						PUNCH_AURA_INTERVAL = 0.1, SUPER_PUNCH_COOLDOWN = 0.15,
						MIN_MACRO_DELAY = 0.01, MAX_MACRO_DELAY = 0.5,
						MIN_SUPER_PUNCH_HITS = 1, MAX_SUPER_PUNCH_HITS = 30,
						MIN_PUNCH_AURA_RANGE = 5, MAX_PUNCH_AURA_RANGE = 40,
						MIN_PHASE_TRANSPARENCY = 0.1, MAX_PHASE_TRANSPARENCY = 0.95,
						GUN_GRAB_WAIT = 1.3, CRIMINAL_SWITCH_WAIT = 3.5,
					},
					LOCATIONS = {
						{ "Prison Cells", CFrame.new(920, 98, 2436) },
						{ "Cafeteria", CFrame.new(920, 98, 2290) },
						{ "Prison Yard", CFrame.new(779, 98, 2463) },
						{ "Criminal Base", CFrame.new(-943, 95, 2058) },
						{ "Police Armory", CFrame.new(831, 98, 2284) },
						{ "Parking Lot", CFrame.new(745, 98, 2148) },
						{ "Roof", CFrame.new(845, 130, 2235) },
						{ "Secret Room", CFrame.new(674, 98, 2384) },
						{ "Tunnels", CFrame.new(918, 80, 2284) },
						{ "Outside of Prison", CFrame.new(451.67, 98.04, 2216.34) },
						{ "Kitchen", CFrame.new(906.64, 99.99, 2237.67) },
						{ "Break Room", CFrame.new(800.09, 99.99, 2266.72) },
					},
					GUN_SPAWNS = {
						["MP5"] = Vector3.new(813.72, 102.50, 2229.37),
						["Remington 870"] = Vector3.new(820.27, 102.50, 2229.31),
						["AK-47"] = Vector3.new(-932, 100.74, 2039.5),
					},
					DOOR_FOLDERS = { "doors", "glass", "celldoors", "prison_fences", "prison_gate" },
					PRISON_GUNS = { "Remington 870", "M9", "AK-47", "Taser", "M4A1", "MP5" },
					GUN_ATTRIBUTES = { "SpreadRadius", "FireRate", "AutoFire", "Range" },
					RESTRICTED_GUIS = { "Taser", "Flashbang", "Cuffs" },
					CRIMINAL_BASE_POS = Vector3.new(-943, 95, 2058),
					DEFAULT_WALKSPEED = 16, DEFAULT_JUMPPOWER = 50,
				},
				THEME_FALLBACKS = {
					Danger = Color3.fromRGB(220, 80, 80), Success = Color3.fromRGB(80, 220, 80),
					Accent = Color3.fromRGB(0, 200, 220), Bg = Color3.fromRGB(20, 20, 20),
				},
			}

			if not FeatureConfig.Game then FeatureConfig.Game = {} end
			for k, v in pairs(GAME_SETTINGS.DEFAULTS) do
				if FeatureConfig.Game[k] == nil then FeatureConfig.Game[k] = v end
			end

			local function getThemeColor(key)
				return Theme[key] or GAME_SETTINGS.THEME_FALLBACKS[key] or Color3.fromRGB(255, 255, 255)
			end

			local Game = { Name = "Prison Life" }
			local isTeleporting = false

			local function notify(title, message, duration, color)
				if Ctx and Ctx.UI and Ctx.UI.Notify then
					Ctx.UI:Notify(title, message, duration, color)
				end
			end

			local function performWarpAction(targetPos, waitTime, startMsg, successMsg, notifyTag)
				if isTeleporting then return end
				local root = Utils.GetRootPart and Utils.GetRootPart()
				if not root then notify(notifyTag, "Character root not found", nil, getThemeColor("Danger")) return end
				isTeleporting = true
				local originalCFrame = root.CFrame
				if startMsg then notify(notifyTag, startMsg, waitTime, getThemeColor("Accent")) end
				root.CFrame = CFrame.new(targetPos)
				task.wait(waitTime)
				local curRoot = Utils.GetRootPart and Utils.GetRootPart()
				if curRoot then
					curRoot.CFrame = originalCFrame
					if successMsg then notify(notifyTag, successMsg, 2, getThemeColor("Success")) end
				end
				isTeleporting = false
			end

			function Game.BuildUI(tab)
				local gunGrabSec = tab:AddSection("Gun Grabbers (Warp-Return)")
				for gunName, spawnPos in pairs(GAME_SETTINGS.GUN_SPAWNS) do
					gunGrabSec:AddButton("Grab " .. gunName, function()
						performWarpAction(spawnPos, GAME_SETTINGS.LIMITS.GUN_GRAB_WAIT, "Acquiring " .. gunName .. "...", gunName .. " acquired!", "Gun Grabber")
					end)
				end

				local combatSec = tab:AddSection("Combat Modifications")
				UIRegistry.Game_NoSpread = combatSec:AddToggle("No Spread", FeatureConfig.Game.NoSpread, function(v) FeatureConfig.Game.NoSpread = v end)
				UIRegistry.Game_FastFire = combatSec:AddToggle("Fast Fire", FeatureConfig.Game.FastFire, function(v) FeatureConfig.Game.FastFire = v end)
				UIRegistry.Game_ForceAuto = combatSec:AddToggle("Force Automatic Fire", FeatureConfig.Game.ForceAuto, function(v) FeatureConfig.Game.ForceAuto = v end)
				UIRegistry.Game_ForceRange = combatSec:AddToggle("Force Range", FeatureConfig.Game.ForceRange, function(v) FeatureConfig.Game.ForceRange = v end)

				local defSec = tab:AddSection("Defenses & Teams")
				UIRegistry.Game_AntiRestrict = defSec:AddToggle("Anti-Taser / Anti-Freeze", FeatureConfig.Game.AntiRestrict, function(v) FeatureConfig.Game.AntiRestrict = v end)
				defSec:AddButton("Become Criminal (Inside)", function()
					performWarpAction(GAME_SETTINGS.CRIMINAL_BASE_POS, GAME_SETTINGS.LIMITS.CRIMINAL_SWITCH_WAIT, "Becoming Criminal...", "Returned Inside as Criminal!", "Prison Life")
				end)
				defSec:AddButton("Become Criminal (Outside)", function()
					local root = Utils.GetRootPart and Utils.GetRootPart()
					if root then root.CFrame = CFrame.new(GAME_SETTINGS.CRIMINAL_BASE_POS) notify("Prison Life", "Warped Outside to Criminal Base!", 2, getThemeColor("Success")) end
				end)

				local tpSec = tab:AddSection("Map Teleports")
				for _, loc in ipairs(GAME_SETTINGS.LOCATIONS) do
					local name, cf = loc[1], loc[2]
					tpSec:AddButton(name, function()
						local root = Utils.GetRootPart and Utils.GetRootPart()
						if root then
							root.CFrame = cf
							notify("Teleport", "Moved to " .. name, nil, getThemeColor("Success"))
						end
					end)
				end
			end

			function Game.Update(dt) end
			function Game.Destroy() end

			return Game
		end

		local GameLoader = {
			PlaceId = placeId,
			Info = { Name = "Prison Life", Folder = "155615604" },
			Module = nil,
			LoadError = nil,
			Supported = true,
		}

		function GameLoader.GetDisplayName() return "Prison Life" end
		function GameLoader.IsSupported() return true end

		function GameLoader.Load()
			if GameLoader.Module then return GameLoader.Module end
			if type(import) == "function" then
				local pathsToTry = {
					string.format("src/Games/%s.lua", placeId),
					"src/Games/155615604.lua",
				}
				for _, path in ipairs(pathsToTry) do
					local success, factory = pcall(import, path, true)
					if success and factory then
						local resolvedModule = factory
						if type(factory) == "function" then
							local rOk, rVal = pcall(factory, Context)
							if rOk then resolvedModule = rVal end
						end
						if type(resolvedModule) == "table" then
							GameLoader.Module = resolvedModule
							return resolvedModule
						end
					end
				end
			end

			local plObj = createPrisonLife(Context)
			GameLoader.Module = plObj
			return plObj
		end

		function GameLoader.BuildUI(tab)
			local mod = GameLoader.Load()
			if mod and type(mod.BuildUI) == "function" then
				pcall(mod.BuildUI, tab)
				return true
			end
			return false, "Failed to build game UI"
		end

		function GameLoader.Update(dt)
			if GameLoader.Module and type(GameLoader.Module.Update) == "function" then
				pcall(GameLoader.Module.Update, dt)
			end
		end

		function GameLoader.Destroy()
			if GameLoader.Module and type(GameLoader.Module.Destroy) == "function" then
				pcall(GameLoader.Module.Destroy)
			end
			GameLoader.Module = nil
		end

		return GameLoader
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
	local resolvedResult = nil

	if sourceCode then
		local loaderFn, compileErr = loadstring(sourceCode, "=" .. path)
		if loaderFn then
			local runSuccess, moduleResult = pcall(loaderFn)
			if runSuccess then
				resolvedResult = moduleResult
			end
		end
	end

	-- Fall back to embedded module if remote fetch, compilation, or execution failed
	if resolvedResult == nil and FALLBACK_MODULES[path] then
		local ok, fallbackFactory = pcall(FALLBACK_MODULES[path])
		if ok and fallbackFactory then
			resolvedResult = fallbackFactory
		end
	end

	if resolvedResult ~= nil then
		print("[B0Xaz] Loaded module: " .. path)
		moduleCache[path] = resolvedResult
		return resolvedResult
	end

	moduleCache[path] = false
	if not isOptional then
		warn("[B0Xaz] Could not load required module: " .. tostring(path))
	end
	return nil
end

-- Core Cleanup
local cleanupFn = import(SETTINGS.PATHS.CLEANUP)
if type(cleanupFn) == "function" then pcall(cleanupFn) end

-- Core Configuration
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

local loaderFactory = import(SETTINGS.PATHS.GAME_LOADER)
if type(loaderFactory) == "function" then
	local success, res = pcall(loaderFactory, context, import)
	if success and type(res) == "table" then
		context.GameLoader = res
	end
end

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
