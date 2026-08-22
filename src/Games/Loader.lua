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
			Description = "Prison Life automated door phasing, gun grabbers, and melee exploits",
		},
	},
	FALLBACK_NAME_FORMAT = "Universal (%s)",
	ERRORS = {
		IMPORT_UNAVAILABLE = "Import function unavailable",
		REGISTRY_UNAVAILABLE = "Game registry unavailable",
		BUILD_UI_MISSING = "Module missing or no BuildUI function",
	},
}

-- Embedded Prison Life Module Factory
local BUILTIN_GAMES = {
	["155615604"] = function(Context)
		local SETTINGS_PL = {
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
				WARNING_COUNTDOWN = 3,
				WARNING_HOLD_TIME = 2.0,
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
				BorderDim = Color3.fromRGB(35, 35, 35),
				Elem = Color3.fromRGB(35, 35, 35),
				ElemHover = Color3.fromRGB(45, 45, 45),
				Text = Color3.fromRGB(255, 255, 255),
				TextDim = Color3.fromRGB(180, 180, 180),
				TextMuted = Color3.fromRGB(120, 120, 120),
			},
		}

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

		if not FeatureConfig.Game then FeatureConfig.Game = {} end
		for key, value in pairs(SETTINGS_PL.DEFAULTS) do
			if FeatureConfig.Game[key] == nil then FeatureConfig.Game[key] = value end
		end

		local function getThemeColor(key)
			return Theme[key] or SETTINGS_PL.THEME_FALLBACKS[key] or Color3.fromRGB(255, 255, 255)
		end

		local doorFolderLookup = {}
		for _, folderName in ipairs(SETTINGS_PL.DOOR_FOLDERS) do doorFolderLookup[folderName] = true end

		local prisonGunsLookup = {}
		for _, gunName in ipairs(SETTINGS_PL.PRISON_GUNS) do prisonGunsLookup[gunName] = true end

		local doorCache = getgenv().B0XazDoorCache or {}
		getgenv().B0XazDoorCache = doorCache
		local doorPartsSet = getgenv().B0XazDoorParts or {}
		getgenv().B0XazDoorParts = doorPartsSet
		local gunCache = getgenv().B0XazGunCache or {}
		getgenv().B0XazGunCache = gunCache

		local Game = { Name = "Prison Life" }

		local macroLoopActive = false
		local macroThread = nil
		local currentToolIndex = 1
		local isKeyPressed = false
		local isTeleporting = false
		local hasAcceptedBannableWarning = false
		local lastPunchAuraTime = 0
		local lastSuperPunchTime = 0

		local MeleeEvent = ReplicatedStorage:FindFirstChild("meleeEvent")

		local function notify(title, message, duration, color)
			if Context and Context.UI and Context.UI.Notify then
				Context.UI:Notify(title, message, duration, color)
			end
		end

		local function fireMelee(targetPlayer)
			if not MeleeEvent then MeleeEvent = ReplicatedStorage:FindFirstChild("meleeEvent") end
			if MeleeEvent then
				pcall(function()
					if targetPlayer then MeleeEvent:FireServer(targetPlayer) else MeleeEvent:FireServer() end
				end)
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
			performWarpAction(targetPos, SETTINGS_PL.LIMITS.GUN_GRAB_WAIT, "Acquiring " .. gunName .. "...", gunName .. " acquired!", "Gun Grabber")
		end

		function Game.BecomeCriminalInside()
			performWarpAction(SETTINGS_PL.CRIMINAL_BASE_POS, SETTINGS_PL.LIMITS.CRIMINAL_SWITCH_WAIT, "Becoming Criminal (Returning in 3.5s)...", "Returned Inside as Criminal!", "Prison Life")
		end

		function Game.BecomeCriminalOutside()
			if isTeleporting then return end
			local root = Utils.GetRootPart and Utils.GetRootPart()
			if not root then return end
			root.CFrame = CFrame.new(SETTINGS_PL.CRIMINAL_BASE_POS)
			notify("Prison Life", "Warped Outside to Criminal Base!", 2, getThemeColor("Success"))
		end

		local function runPunchAura()
			if not FeatureConfig.Game.PunchAura then return end
			local now = os.clock()
			if (now - lastPunchAuraTime) < SETTINGS_PL.LIMITS.PUNCH_AURA_INTERVAL then return end
			lastPunchAuraTime = now

			local myRoot = Utils.GetRootPart and Utils.GetRootPart()
			if not myRoot then return end

			local maxDist = math.clamp(
				FeatureConfig.Game.PunchAuraRange or SETTINGS_PL.DEFAULTS.PunchAuraRange,
				SETTINGS_PL.LIMITS.MIN_PUNCH_AURA_RANGE,
				SETTINGS_PL.LIMITS.MAX_PUNCH_AURA_RANGE
			)

			for _, player in ipairs(Players:GetPlayers()) do
				if player ~= LocalPlayer and Utils.IsAlive and Utils.IsAlive(player) and not (Utils.SameTeam and Utils.SameTeam(player)) then
					local character = player.Character
					local targetRoot = character and character:FindFirstChild("HumanoidRootPart")
					if targetRoot and (targetRoot.Position - myRoot.Position).Magnitude <= maxDist then
						fireMelee(player)
					end
				end
			end
		end

		local function isInsideVendingModel(object)
			local current = object
			while current and current ~= Workspace do
				if current:IsA("Model") and current.Name == "Model" and current.Parent and current.Parent.Name == "vending machine" then
					return true
				end
				current = current.Parent
			end
			return false
		end

		local function isDoorPart(part)
			if not part or not part:IsA("BasePart") then return false end
			if isInsideVendingModel(part) then return true end
			local current = part.Parent
			while current and current ~= Workspace do
				if doorFolderLookup[current.Name:lower()] then return true end
				current = current.Parent
			end
			return false
		end

		local function restorePart(part)
			local cached = doorCache[part]
			if cached and part and part.Parent then
				pcall(function()
					part.CanCollide = cached.CanCollide
					part.Transparency = cached.Transparency
					part.Color = cached.Color
					part.Material = cached.Material
				end)
			end
			doorCache[part] = nil
			doorPartsSet[part] = nil
		end

		local function restoreAllDoors()
			for part in pairs(doorCache) do restorePart(part) end
			table.clear(doorCache)
			table.clear(doorPartsSet)
		end

		local function cachePart(part)
			if doorCache[part] then return end
			doorCache[part] = {
				CanCollide = part.CanCollide,
				Transparency = part.Transparency,
				Color = part.Color,
				Material = part.Material,
			}
		end

		local function processPart(part)
			if not isDoorPart(part) then return end
			cachePart(part)
			doorPartsSet[part] = true
		end

		local function scanAllDoors()
			for _, folderName in ipairs(SETTINGS_PL.DOOR_FOLDERS) do
				for _, child in ipairs(Workspace:GetChildren()) do
					if child.Name:lower() == folderName then
						for _, descendant in ipairs(child:GetDescendants()) do
							if descendant:IsA("BasePart") then processPart(descendant) end
						end
					end
				end
			end
			for _, object in ipairs(Workspace:GetDescendants()) do
				if object:IsA("BasePart") and isInsideVendingModel(object) then processPart(object) end
			end
		end

		local function enforcePart(part)
			local cached = doorCache[part]
			if not cached or not part or not part.Parent then
				doorPartsSet[part] = nil
				doorCache[part] = nil
				return
			end
			if not FeatureConfig.Game.DoorPhase then return end

			pcall(function()
				if part.CanCollide then part.CanCollide = false end
				local targetTrans = math.clamp(
					FeatureConfig.Game.PhaseTransparency or SETTINGS_PL.DEFAULTS.PhaseTransparency,
					SETTINGS_PL.LIMITS.MIN_PHASE_TRANSPARENCY,
					SETTINGS_PL.LIMITS.MAX_PHASE_TRANSPARENCY
				)
				if math.abs(part.Transparency - targetTrans) > 0.01 then part.Transparency = targetTrans end
				if FeatureConfig.Game.DoorGlow then
					local glowColor = FeatureConfig.Game.GlowColor or SETTINGS_PL.DEFAULTS.GlowColor
					if part.Material ~= Enum.Material.Neon then part.Material = Enum.Material.Neon end
					if part.Color ~= glowColor then part.Color = glowColor end
				else
					if part.Material ~= cached.Material then part.Material = cached.Material end
					if part.Color ~= cached.Color then part.Color = cached.Color end
				end
			end)
		end

		local function getGunContainers()
			local list = {}
			if LocalPlayer then
				local backpack = LocalPlayer:FindFirstChild("Backpack")
				if backpack then table.insert(list, backpack) end
				if LocalPlayer.Character then table.insert(list, LocalPlayer.Character) end
			end
			return list
		end

		local function cacheGunAttrs(instance)
			if gunCache[instance] then return end
			local entry = {}
			for _, name in ipairs(SETTINGS_PL.GUN_ATTRIBUTES) do
				local val = instance:GetAttribute(name)
				if val ~= nil then entry[name] = val end
			end
			gunCache[instance] = entry
		end

		local function applyGunModsTo(instance)
			if not instance or not instance.Parent then return end
			local function modifyAttributes(obj)
				cacheGunAttrs(obj)
				if FeatureConfig.Game.NoSpread and obj:GetAttribute("SpreadRadius") ~= nil and obj:GetAttribute("SpreadRadius") ~= 0 then
					pcall(function() obj:SetAttribute("SpreadRadius", 0) end)
				end
				if FeatureConfig.Game.FastFire and obj:GetAttribute("FireRate") ~= nil then
					local rate = FeatureConfig.Game.FireRateValue or SETTINGS_PL.DEFAULTS.FireRateValue
					if obj:GetAttribute("FireRate") ~= rate then pcall(function() obj:SetAttribute("FireRate", rate) end) end
				end
				if FeatureConfig.Game.ForceAuto and obj:GetAttribute("AutoFire") ~= nil and obj:GetAttribute("AutoFire") ~= true then
					pcall(function() obj:SetAttribute("AutoFire", true) end)
				end
				if FeatureConfig.Game.ForceRange and obj:GetAttribute("Range") ~= nil then
					local range = FeatureConfig.Game.RangeValue or SETTINGS_PL.DEFAULTS.RangeValue
					if obj:GetAttribute("Range") ~= range then pcall(function() obj:SetAttribute("Range", range) end) end
				end
			end

			if instance:IsA("Tool") then
				modifyAttributes(instance)
				for _, descendant in ipairs(instance:GetDescendants()) do
					for _, attr in ipairs(SETTINGS_PL.GUN_ATTRIBUTES) do
						if descendant:GetAttribute(attr) ~= nil then modifyAttributes(descendant) break end
					end
				end
			else
				for _, attr in ipairs(SETTINGS_PL.GUN_ATTRIBUTES) do
					if instance:GetAttribute(attr) ~= nil then modifyAttributes(instance) break end
				end
			end
		end

		local function anyGunModEnabled()
			return FeatureConfig.Game.NoSpread or FeatureConfig.Game.FastFire or FeatureConfig.Game.ForceAuto or FeatureConfig.Game.ForceRange
		end

		local function scanGuns()
			for _, container in ipairs(getGunContainers()) do
				for _, child in ipairs(container:GetChildren()) do
					if child:IsA("Tool") then applyGunModsTo(child) end
				end
			end
		end

		local function restoreGuns()
			for instance, entry in pairs(gunCache) do
				if instance and instance.Parent and type(entry) == "table" then
					for name, original in pairs(entry) do pcall(function() instance:SetAttribute(name, original) end) end
				end
				gunCache[instance] = nil
			end
			table.clear(gunCache)
		end

		local function enforceGuns()
			if not anyGunModEnabled() then return end
			scanGuns()
		end

		if Connections and Connections.Add then
			if FeatureConfig.Game.DoorPhase then task.spawn(scanAllDoors) end

			Connections.Add(RunService.Heartbeat:Connect(function()
				runPunchAura()
				if FeatureConfig.Game.AntiRestrict then
					local hum = Utils.GetHumanoid and Utils.GetHumanoid()
					if hum then
						local flyActive = FeatureConfig.Movement and FeatureConfig.Movement.FlyEnabled
						if hum.WalkSpeed < SETTINGS_PL.DEFAULT_WALKSPEED and not flyActive then
							hum.WalkSpeed = (FeatureConfig.Movement and FeatureConfig.Movement.Speed) or SETTINGS_PL.DEFAULT_WALKSPEED
						end
						if hum.JumpPower < SETTINGS_PL.DEFAULT_JUMPPOWER then
							hum.JumpPower = (FeatureConfig.Movement and FeatureConfig.Movement.JumpPower) or SETTINGS_PL.DEFAULT_JUMPPOWER
						end
						if hum.PlatformStand then hum.PlatformStand = false end
					end

					local pGui = LocalPlayer:FindFirstChild("PlayerGui")
					if pGui then
						for _, guiName in ipairs(SETTINGS_PL.RESTRICTED_GUIS) do
							local gui = pGui:FindFirstChild(guiName)
							if gui and gui.Enabled then gui.Enabled = false end
						end
					end
				end
			end))

			Connections.Add(RunService.Stepped:Connect(function()
				if FeatureConfig.Game.DoorPhase then
					for part in pairs(doorPartsSet) do enforcePart(part) end
				end
				if anyGunModEnabled() then enforceGuns() end
			end))

			Connections.Add(Workspace.DescendantAdded:Connect(function(descendant)
				if FeatureConfig.Game.DoorPhase and descendant:IsA("BasePart") then
					task.defer(function() processPart(descendant) end)
				end
			end))

			local function hookContainer(container)
				if not container then return end
				Connections.Add(container.ChildAdded:Connect(function(child)
					if anyGunModEnabled() and child:IsA("Tool") then
						task.defer(function() applyGunModsTo(child) end)
					end
				end))
			end

			if LocalPlayer:FindFirstChild("Backpack") then hookContainer(LocalPlayer.Backpack) end
			if LocalPlayer.Character then hookContainer(LocalPlayer.Character) end

			Connections.Add(LocalPlayer.CharacterAdded:Connect(function(char)
				hookContainer(char)
				task.wait(0.5)
				if anyGunModEnabled() then scanGuns() end
			end))
		end

		function Game.BuildUI(tab)
			local gunGrabSec = tab:AddSection("Gun Grabbers (Warp-Return)")
			for gunName, spawnPos in pairs(SETTINGS_PL.GUN_SPAWNS) do
				gunGrabSec:AddButton("Grab " .. gunName, function() grabGun(gunName, spawnPos) end)
			end

			local combatSec = tab:AddSection("Combat Modifications")
			UIRegistry.Game_NoSpread = combatSec:AddToggle("No Spread", FeatureConfig.Game.NoSpread, function(v)
				FeatureConfig.Game.NoSpread = v
				if anyGunModEnabled() then scanGuns() else restoreGuns() end
			end)
			UIRegistry.Game_FastFire = combatSec:AddToggle("Fast Fire", FeatureConfig.Game.FastFire, function(v)
				FeatureConfig.Game.FastFire = v
				if anyGunModEnabled() then scanGuns() else restoreGuns() end
			end)
			UIRegistry.Game_ForceAuto = combatSec:AddToggle("Force Automatic Fire", FeatureConfig.Game.ForceAuto, function(v)
				FeatureConfig.Game.ForceAuto = v
				if anyGunModEnabled() then scanGuns() else restoreGuns() end
			end)
			UIRegistry.Game_ForceRange = combatSec:AddToggle("Force Range", FeatureConfig.Game.ForceRange, function(v)
				FeatureConfig.Game.ForceRange = v
				if anyGunModEnabled() then scanGuns() else restoreGuns() end
			end)
			combatSec:AddButton("Force Apply Gun Mods", function()
				scanGuns()
				notify("Prison Life", "Gun mods enforced", nil, getThemeColor("Accent"))
			end)

			local doorsSec = tab:AddSection("Doors & Obstacles")
			UIRegistry.Game_DoorPhase = doorsSec:AddToggle("Phase Doors, Fences & Vending", FeatureConfig.Game.DoorPhase, function(v)
				FeatureConfig.Game.DoorPhase = v
				if v then scanAllDoors() else restoreAllDoors() end
			end)
			UIRegistry.Game_DoorGlow = doorsSec:AddToggle("Obstacle Glow Effect", FeatureConfig.Game.DoorGlow, function(v)
				FeatureConfig.Game.DoorGlow = v
				if FeatureConfig.Game.DoorPhase then scanAllDoors() end
			end)

			local defSec = tab:AddSection("Defenses & Teams")
			UIRegistry.Game_AntiRestrict = defSec:AddToggle("Anti-Taser / Anti-Freeze", FeatureConfig.Game.AntiRestrict, function(v) FeatureConfig.Game.AntiRestrict = v end)
			defSec:AddButton("Become Criminal (Inside)", function() Game.BecomeCriminalInside() end)
			defSec:AddButton("Become Criminal (Outside)", function() Game.BecomeCriminalOutside() end)

			local tpSec = tab:AddSection("Map Teleports")
			for _, loc in ipairs(SETTINGS_PL.LOCATIONS) do
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

		function Game.Update(dt)
			if FeatureConfig.Game.DoorPhase then for part in pairs(doorPartsSet) do enforcePart(part) end end
			if anyGunModEnabled() then enforceGuns() end
		end

		function Game.Destroy()
			restoreAllDoors()
			restoreGuns()
		end

		getgenv().B0XazRestoreDoors = restoreAllDoors
		getgenv().B0XazRestoreGuns = restoreGuns

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

	local gameInfo = registry[placeId] or registry["155615604"]

	local GameLoader = {
		PlaceId = placeId,
		UniverseId = universeId,
		Info = gameInfo,
		Module = nil,
		LoadError = nil,
		Supported = true,
	}

	function GameLoader.GetDisplayName()
		if GameLoader.Info and GameLoader.Info.Name then
			return GameLoader.Info.Name
		end
		return "Prison Life"
	end

	function GameLoader.IsSupported()
		return true
	end

	function GameLoader.ListSupported()
		return {
			{ PlaceId = "155615604", Name = "Prison Life", Description = "Prison Life mods" }
		}
	end

	function GameLoader.Load()
		if GameLoader.Module then
			return GameLoader.Module
		end

		-- 1. Check embedded games first
		if BUILTIN_GAMES[placeId] or BUILTIN_GAMES["155615604"] then
			local factory = BUILTIN_GAMES[placeId] or BUILTIN_GAMES["155615604"]
			local runSuccess, runResult = pcall(factory, Context)
			if runSuccess and type(runResult) == "table" then
				GameLoader.Module = runResult
				GameLoader.LoadError = nil
				return runResult
			end
		end

		-- 2. Fallback to remote import
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
						local runSuccess, runResult = pcall(factory, Context)
						if runSuccess then resolvedModule = runResult end
					end
					if type(resolvedModule) == "table" then
						GameLoader.Module = resolvedModule
						GameLoader.LoadError = nil
						return resolvedModule
					end
				end
			end
		end

		GameLoader.LoadError = SETTINGS.ERRORS.REGISTRY_UNAVAILABLE
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
