-- // src/Games/Loader.lua
local SETTINGS = {
	PATHS = {
		REGISTRY = "src/Games/Registry.lua",
		MODULE_INIT = "src/Games/%s/init.lua",
		MODULE_SINGLE = "src/Games/%s.lua",
	},
	FALLBACK_REGISTRY = {
		["155615604"] = {
			Name = "Prison Life",
			Folder = "155615604",
			Description = "Prison Life automated door phasing and weapon enhancements",
		},
	},
	FALLBACK_NAME_FORMAT = "Universal (%s)",
	ERRORS = {
		IMPORT_UNAVAILABLE = "Import function unavailable",
		REGISTRY_UNAVAILABLE = "Game registry unavailable",
		BUILD_UI_MISSING = "Module missing or no BuildUI function",
	},
}

-- Embedded Prison Life Fallback Factory (Ensures 100% load success if remote fetch fails)
local EMBEDDED_GAMES = {
	["155615604"] = function(Context)
		local Workspace = game:GetService("Workspace")
		local Players = game:GetService("Players")
		local RunService = game:GetService("RunService")
		local UserInputService = game:GetService("UserInputService")
		local ReplicatedStorage = game:GetService("ReplicatedStorage")

		local LocalPlayer = Players.LocalPlayer
		local FeatureConfig = Context and Context.FeatureConfig or {}
		local Theme = Context and Context.Theme or {}
		local Connections = Context and Context.Connections or {}
		local UIRegistry = Context and Context.UIRegistry or {}
		local Utils = Context and Context.Utils or {}

		local GAME_SETTINGS = {
			DEFAULTS = {
				DoorPhase = false,
				DoorGlow = true,
				GlowColor = Color3.fromRGB(0, 200, 220),
				PhaseTransparency = 0.65,
				NoSpread = false,
				FastFire = false,
				ForceAuto = false,
				ForceRange = false,
				FireRateValue = 0.001,
				RangeValue = 10000,
				FakeMacro = false,
				FakeMacroKey = Enum.KeyCode.V,
				FakeMacroMode = "Toggle",
				FakeMacroDelay = 0.03,
				AntiRestrict = false,
				PunchAura = false,
				PunchAuraRange = 15,
				SuperPunch = false,
				SuperPunchHits = 10,
			},
			LIMITS = {
				PUNCH_AURA_INTERVAL = 0.1,
				SUPER_PUNCH_COOLDOWN = 0.15,
				MIN_MACRO_DELAY = 0.01,
				MAX_MACRO_DELAY = 0.5,
				MIN_SUPER_PUNCH_HITS = 1,
				MAX_SUPER_PUNCH_HITS = 30,
				MIN_PUNCH_AURA_RANGE = 5,
				MAX_PUNCH_AURA_RANGE = 40,
				MIN_PHASE_TRANSPARENCY = 0.1,
				MAX_PHASE_TRANSPARENCY = 0.95,
				GUN_GRAB_WAIT = 1.3,
				CRIMINAL_SWITCH_WAIT = 3.5,
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
			DEFAULT_WALKSPEED = 16,
			DEFAULT_JUMPPOWER = 50,
			THEME_FALLBACKS = {
				Danger = Color3.fromRGB(220, 80, 80),
				Success = Color3.fromRGB(80, 220, 80),
				Accent = Color3.fromRGB(0, 200, 220),
				Bg = Color3.fromRGB(20, 20, 20),
				Side = Color3.fromRGB(25, 25, 25),
				Panel = Color3.fromRGB(30, 30, 30),
				Border = Color3.fromRGB(45, 45, 45),
				Text = Color3.fromRGB(255, 255, 255),
				TextDim = Color3.fromRGB(180, 180, 180),
			},
		}

		if not FeatureConfig.Game then FeatureConfig.Game = {} end
		for key, value in pairs(GAME_SETTINGS.DEFAULTS) do
			if FeatureConfig.Game[key] == nil then FeatureConfig.Game[key] = value end
		end

		local function getThemeColor(key)
			return Theme[key] or GAME_SETTINGS.THEME_FALLBACKS[key] or Color3.fromRGB(255, 255, 255)
		end

		local doorFolderLookup = {}
		for _, folderName in ipairs(GAME_SETTINGS.DOOR_FOLDERS) do doorFolderLookup[folderName] = true end

		local prisonGunsLookup = {}
		for _, gunName in ipairs(GAME_SETTINGS.PRISON_GUNS) do prisonGunsLookup[gunName] = true end

		local doorCache = getgenv().B0XazDoorCache or {}
		getgenv().B0XazDoorCache = doorCache
		local doorPartsSet = getgenv().B0XazDoorParts or {}
		getgenv().B0XazDoorParts = doorPartsSet
		local gunCache = getgenv().B0XazGunCache or {}
		getgenv().B0XazGunCache = gunCache

		local Game = { Name = "Prison Life" }
		local isTeleporting = false

		local function notify(title, message, duration, color)
			if Context and Context.UI and Context.UI.Notify then
				Context.UI:Notify(title, message, duration, color)
			end
		end

		local function performWarpAction(targetPosition, waitTime, startMsg, successMsg, notifyTag)
			if isTeleporting then return end
			local root = Utils.GetRootPart and Utils.GetRootPart()
			if not root then
				notify(notifyTag, "Character root not found", nil, getThemeColor("Danger"))
				return
			end
			isTeleporting = true
			local originalCFrame = root.CFrame
			if startMsg then notify(notifyTag, startMsg, waitTime, getThemeColor("Accent")) end
			root.CFrame = CFrame.new(targetPosition)
			task.wait(waitTime)
			local currentRoot = Utils.GetRootPart and Utils.GetRootPart()
			if currentRoot then
				currentRoot.CFrame = originalCFrame
				if successMsg then notify(notifyTag, successMsg, 2, getThemeColor("Success")) end
			end
			isTeleporting = false
		end

		local function grabGun(gunName, targetPos)
			performWarpAction(targetPos, GAME_SETTINGS.LIMITS.GUN_GRAB_WAIT, "Acquiring " .. gunName .. "...", gunName .. " acquired!", "Gun Grabber")
		end

		function Game.BecomeCriminalInside()
			performWarpAction(GAME_SETTINGS.CRIMINAL_BASE_POS, GAME_SETTINGS.LIMITS.CRIMINAL_SWITCH_WAIT, "Becoming Criminal (Returning in 3.5s)...", "Returned Inside as Criminal!", "Prison Life")
		end

		function Game.BecomeCriminalOutside()
			if isTeleporting then return end
			local root = Utils.GetRootPart and Utils.GetRootPart()
			if not root then return end
			root.CFrame = CFrame.new(GAME_SETTINGS.CRIMINAL_BASE_POS)
			notify("Prison Life", "Warped Outside to Criminal Base!", 2, getThemeColor("Success"))
		end

		function Game.BuildUI(tab)
			local gunGrabSec = tab:AddSection("Gun Grabbers (Warp-Return)")
			for gunName, spawnPos in pairs(GAME_SETTINGS.GUN_SPAWNS) do
				gunGrabSec:AddButton("Grab " .. gunName, function() grabGun(gunName, spawnPos) end)
			end

			local combatSec = tab:AddSection("Combat Modifications")
			UIRegistry.Game_NoSpread = combatSec:AddToggle("No Spread", FeatureConfig.Game.NoSpread, function(v) FeatureConfig.Game.NoSpread = v end)
			UIRegistry.Game_FastFire = combatSec:AddToggle("Fast Fire", FeatureConfig.Game.FastFire, function(v) FeatureConfig.Game.FastFire = v end)
			UIRegistry.Game_ForceAuto = combatSec:AddToggle("Force Automatic Fire", FeatureConfig.Game.ForceAuto, function(v) FeatureConfig.Game.ForceAuto = v end)
			UIRegistry.Game_ForceRange = combatSec:AddToggle("Force Range", FeatureConfig.Game.ForceRange, function(v) FeatureConfig.Game.ForceRange = v end)

			local defSec = tab:AddSection("Defenses & Teams")
			UIRegistry.Game_AntiRestrict = defSec:AddToggle("Anti-Taser / Anti-Freeze", FeatureConfig.Game.AntiRestrict, function(v) FeatureConfig.Game.AntiRestrict = v end)
			defSec:AddButton("Become Criminal (Inside)", function() Game.BecomeCriminalInside() end)
			defSec:AddButton("Become Criminal (Outside)", function() Game.BecomeCriminalOutside() end)

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
	end,
}

return function(Context, import)
	local placeId = tostring(game.PlaceId)
	local universeId = tostring(game.GameId)

	local registry = SETTINGS.FALLBACK_REGISTRY
	if type(import) == "function" then
		local success, regResult = pcall(import, SETTINGS.PATHS.REGISTRY, true)
		if success and type(regResult) == "function" then
			local callSuccess, callResult = pcall(regResult)
			if callSuccess and type(callResult) == "table" then
				registry = callResult
			end
		elseif success and type(regResult) == "table" then
			registry = regResult
		end
	end

	local gameInfo = registry[placeId]

	local GameLoader = {
		PlaceId = placeId,
		UniverseId = universeId,
		Info = gameInfo,
		Module = nil,
		LoadError = nil,
		Supported = gameInfo ~= nil,
	}

	function GameLoader.GetDisplayName()
		if GameLoader.Info and GameLoader.Info.Name then
			return GameLoader.Info.Name
		end
		return string.format(SETTINGS.FALLBACK_NAME_FORMAT, placeId)
	end

	function GameLoader.IsSupported()
		return GameLoader.Supported
	end

	function GameLoader.ListSupported()
		local list = {}
		for id, info in pairs(registry) do
			if type(info) == "table" then
				table.insert(list, {
					PlaceId = tostring(id),
					Name = info.Name or tostring(id),
					Description = info.Description or "",
				})
			end
		end
		table.sort(list, function(a, b)
			return a.Name < b.Name
		end)
		return list
	end

	function GameLoader.Load()
		if not GameLoader.Supported then
			return nil
		end
		if GameLoader.Module then
			return GameLoader.Module
		end

		local targetName = GameLoader.Info and (GameLoader.Info.Folder or GameLoader.Info.Name) or placeId
		local cleanName = targetName:gsub("%s+", "")

		local pathsToTry = {
			string.format("src/Games/%s.lua", placeId),
			string.format("src/Games/%s.lua", cleanName),
			string.format("src/Games/%s.lua", targetName),
			string.format(SETTINGS.PATHS.MODULE_SINGLE, targetName),
			string.format(SETTINGS.PATHS.MODULE_SINGLE, cleanName),
			string.format(SETTINGS.PATHS.MODULE_INIT, targetName),
			string.format("src/Games/%s/init.lua", placeId),
		}

		local lastErr = ""

		-- 1. Attempt remote/local import
		if type(import) == "function" then
			for _, path in ipairs(pathsToTry) do
				local success, factory = pcall(import, path, true)
				if success and factory then
					local resolvedModule = factory
					if type(factory) == "function" then
						local runSuccess, runResult = pcall(factory, Context)
						if runSuccess then
							resolvedModule = runResult
						else
							lastErr = tostring(runResult)
							resolvedModule = nil
						end
					end

					if type(resolvedModule) == "table" then
						GameLoader.Module = resolvedModule
						GameLoader.LoadError = nil
						return resolvedModule
					end
				else
					if factory then lastErr = tostring(factory) end
				end
			end
		end

		-- 2. Fallback to embedded game factory if remote import misses
		if EMBEDDED_GAMES[placeId] then
			local embeddedFactory = EMBEDDED_GAMES[placeId]
			local runSuccess, runResult = pcall(embeddedFactory, Context)
			if runSuccess and type(runResult) == "table" then
				GameLoader.Module = runResult
				GameLoader.LoadError = nil
				return runResult
			end
		end

		GameLoader.LoadError = lastErr ~= "" and lastErr or SETTINGS.ERRORS.REGISTRY_UNAVAILABLE
		GameLoader.Module = nil
		return nil
	end

	function GameLoader.BuildUI(tab)
		local mod = GameLoader.Load()
		if mod and type(mod.BuildUI) == "function" then
			local success, err = pcall(mod.BuildUI, tab)
			if not success then
				return false, tostring(err)
			end
			return true
		end
		return false, GameLoader.LoadError or SETTINGS.ERRORS.BUILD_UI_MISSING
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
		GameLoader.LoadError = nil
	end

	return GameLoader
end
