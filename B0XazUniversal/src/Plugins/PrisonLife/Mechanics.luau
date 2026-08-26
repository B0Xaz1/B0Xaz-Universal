--!strict
-- ══════════════════════════════════════════════════════════════════════════════
-- B0XazUniversal - Prison Life Mechanics & UI Controller
-- Zero-allocation weapon macro, punch aura, multi-hit super punch,
-- map teleports, gun grabbers, and full Prison Life UI mount.
-- ══════════════════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

return function(services: any)
	local StateStore = services:Get("StateStore")
	local TaskScheduler = services:Get("TaskScheduler")
	local LocomotionService = services:Get("LocomotionService")
	local PlayerTracker = services:Get("PlayerTracker")
	local TargetFilter = services:Get("TargetFilter")
	local Environment = services:Get("Environment")
	local ThemeEngine = services:Get("ThemeEngine")
	local UIEngine = services:Get("UIEngine")
	local Require = services:Get("Require")
	local DOM = services:Get("DOM")

	local Manifest = Require("B0XazUniversal/src/Plugins/PrisonLife/Manifest.luau")
	local WorldPhase = Require("B0XazUniversal/src/Plugins/PrisonLife/WorldPhase.luau")(services, Manifest)
	local WeaponMods = Require("B0XazUniversal/src/Plugins/PrisonLife/WeaponMods.luau")(services, Manifest)

	local Toggle = Require("B0XazUniversal/src/UI/Components/Toggle.luau")
	local Slider = Require("B0XazUniversal/src/UI/Components/Slider.luau")
	local Dropdown = Require("B0XazUniversal/src/UI/Components/Dropdown.luau")
	local ColorPicker = Require("B0XazUniversal/src/UI/Components/ColorPicker.luau")
	local Keybind = Require("B0XazUniversal/src/UI/Components/Keybind.luau")
	local Components = Require("B0XazUniversal/src/UI/Components/Textbox.luau")

	local LocalPlayer = Players.LocalPlayer
	local meleeRemote = ReplicatedStorage:FindFirstChild("meleeEvent")

	local PrisonLifePlugin = {
		Name = "Prison Life",
		_macroRunning = false,
		_macroSlotIndex = 1,
		_gunBuffer = table.create(10) :: { Tool },
		_lastPunchTime = 0,
		_lastSuperTime = 0,
	}

	local function fireMelee(target: Player?)
		if not meleeRemote then
			meleeRemote = ReplicatedStorage:FindFirstChild("meleeEvent")
		end
		if meleeRemote then
			pcall(function()
				if target then
					(meleeRemote :: RemoteEvent):FireServer(target)
				else
					(meleeRemote :: RemoteEvent):FireServer()
				end
			end)
		end
	end

	-- ─────────────────────────────────────────────────────────────────────────
	-- Weapon Macro (Zero Memory Allocation Loop)
	-- ─────────────────────────────────────────────────────────────────────────
	function PrisonLifePlugin:StartMacro()
		if self._macroRunning then return end
		self._macroRunning = true

		task.spawn(function()
			while self._macroRunning do
				local myAssets = PlayerTracker:GetLocalAssets()
				local bp = LocalPlayer and LocalPlayer:FindFirstChildOfClass("Backpack")
				if myAssets and myAssets.Humanoid and bp then
					table.clear(self._gunBuffer)
					for _, tool in ipairs(bp:GetChildren()) do
						if tool:IsA("Tool") and Manifest.PRISON_GUNS[tool.Name] then
							table.insert(self._gunBuffer, tool)
						end
					end
					for _, tool in ipairs(myAssets.Character:GetChildren()) do
						if tool:IsA("Tool") and Manifest.PRISON_GUNS[tool.Name] then
							table.insert(self._gunBuffer, tool)
						end
					end

					if #self._gunBuffer >= 2 then
						self._macroSlotIndex = (self._macroSlotIndex % #self._gunBuffer) + 1
						local nextTool = self._gunBuffer[self._macroSlotIndex]
						if nextTool and nextTool.Parent ~= myAssets.Character then
							myAssets.Humanoid:EquipTool(nextTool)
						end
					end
				end
				local delayTime = math.clamp(tonumber(StateStore:Get("Game.FakeMacroDelay")) or 0.03, 0.03, 0.5)
				task.wait(delayTime)
			end
		end)
	end

	function PrisonLifePlugin:StopMacro()
		self._macroRunning = false
	end

	-- ─────────────────────────────────────────────────────────────────────────
	-- Punch Aura Tick Update
	-- ─────────────────────────────────────────────────────────────────────────
	local function onHeartbeat(dt: number)
		if not StateStore:Get("Game.PunchAura") then return end
		local now = os.clock()
		if (now - PrisonLifePlugin._lastPunchTime) < 0.1 then return end
		PrisonLifePlugin._lastPunchTime = now

		local myAssets = PlayerTracker:GetLocalAssets()
		if not myAssets or not myAssets.RootPart then return end

		local auraRange = math.clamp(tonumber(StateStore:Get("Game.PunchAuraRange")) or 15, 5, 40)
		local maxRangeSq = auraRange * auraRange
		local myPos = myAssets.RootPart.Position

		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and PlayerTracker:IsAlive(player) then
				if not TargetFilter:IsTeammate(player) and not TargetFilter:HasForceField(player) then
					local assets = PlayerTracker:GetPlayerAssets(player)
					if assets and assets.RootPart then
						local distSq = (myPos - assets.RootPart.Position).Magnitude ^ 2
						if distSq <= maxRangeSq then
							fireMelee(player)
						end
					end
				end
			end
		end
	end

	-- ─────────────────────────────────────────────────────────────────────────
	-- Super Punch Click Interceptor
	-- ─────────────────────────────────────────────────────────────────────────
	local function onInputBegan(input: InputObject, gp: boolean)
		if gp then return end

		-- Macro Hotkey
		local macroBind = Environment.ParseKeybind(StateStore:Get("Game.FakeMacroKey"))
		if macroBind and (input.KeyCode == macroBind or input.UserInputType == macroBind) then
			if StateStore:Get("Game.FakeMacroMode") == "Toggle" then
				local newState = not StateStore:Get("Game.FakeMacro")
				StateStore:Set("Game.FakeMacro", newState)
				if newState then PrisonLifePlugin:StartMacro() else PrisonLifePlugin:StopMacro() end
			else
				PrisonLifePlugin:StartMacro()
			end
		end

		-- Super Punch Burst
		if StateStore:Get("Game.SuperPunch") and input.UserInputType == Enum.UserInputType.MouseButton1 then
			local now = os.clock()
			if (now - PrisonLifePlugin._lastSuperTime) >= 0.15 then
				PrisonLifePlugin._lastSuperTime = now
				local myAssets = PlayerTracker:GetLocalAssets()
				if myAssets and myAssets.Character and not myAssets.Character:FindFirstChildOfClass("Tool") then
					local hits = math.clamp(tonumber(StateStore:Get("Game.SuperPunchHits")) or 10, 1, 30)
					for _ = 1, hits do
						fireMelee()
					end
				end
			end
		end
	end

	local function onInputEnded(input: InputObject)
		local macroBind = Environment.ParseKeybind(StateStore:Get("Game.FakeMacroKey"))
		if macroBind and (input.KeyCode == macroBind or input.UserInputType == macroBind) then
			if StateStore:Get("Game.FakeMacroMode") == "Hold" then
				PrisonLifePlugin:StopMacro()
			end
		end
	end

	-- ─────────────────────────────────────────────────────────────────────────
	-- UI Mount Builder
	-- ─────────────────────────────────────────────────────────────────────────
	function PrisonLifePlugin:BuildUI(tab: any)
		local function createSec(parent: Instance, title: string): Frame
			local secFrame = DOM.Create("Frame", {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundColor3 = ThemeEngine:GetToken("Panel"),
				BorderSizePixel = 0,
				Parent = parent,
			}, {
				DOM.CreateStroke(ThemeEngine:GetToken("Border"), 1),
				DOM.Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }),
			}) :: Frame
			ThemeEngine:BindToken(secFrame, "BackgroundColor3", "Panel")

			local header = DOM.Create("Frame", {
				Size = UDim2.new(1, 0, 0, 20),
				BackgroundColor3 = ThemeEngine:GetToken("Side"),
				BorderSizePixel = 0,
				Parent = secFrame,
			}, {
				DOM.Create("Frame", {
					Size = UDim2.new(1, 0, 0, 1),
					Position = UDim2.new(0, 0, 1, -1),
					BackgroundColor3 = ThemeEngine:GetToken("Accent"),
					BorderSizePixel = 0,
				}),
				DOM.Create("TextLabel", {
					Text = "  " .. title,
					Font = Enum.Font.Code,
					TextSize = 11,
					TextColor3 = ThemeEngine:GetToken("TextDim"),
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
				}),
			})
			ThemeEngine:BindToken(header, "BackgroundColor3", "Side")

			local content = DOM.Create("Frame", {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Parent = secFrame,
			}, {
				DOM.Create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }),
				DOM.CreatePadding(4, 6, 6, 6),
			}) :: Frame
			return content
		end

		-- Left Column: Gun Grabbers & Combat Mods
		local grabSec = createSec(tab.LeftCol, "Armory Gun Grabbers")
		for name, pos in pairs(Manifest.GUN_SPAWNS) do
			Components.CreateButton(grabSec, "Acquire " .. name, function()
				LocomotionService:TeleportToPosition(pos)
				UIEngine:Notify("Armory", "Warped to " .. name, 2, ThemeEngine:GetToken("Success"))
			end)
		end

		local combatSec = createSec(tab.LeftCol, "Combat Weapon Mods")
		Toggle.new(combatSec, "No Spread", "Game.NoSpread", function() WeaponMods:ScanAllWeapons() end)
		Toggle.new(combatSec, "Fast Fire Rate", "Game.FastFire", function() WeaponMods:ScanAllWeapons() end)
		Toggle.new(combatSec, "Force Full-Auto", "Game.ForceAuto", function() WeaponMods:ScanAllWeapons() end)
		Toggle.new(combatSec, "Force Infinite Range", "Game.ForceRange", function() WeaponMods:ScanAllWeapons() end)

		-- Right Column: Door Phasing, Macro & Melee
		local doorSec = createSec(tab.RightCol, "Obstacles & Doors")
		Toggle.new(doorSec, "Phase Doors & Fences", "Game.DoorPhase", function(active)
			if active then WorldPhase:ScanAllDoors() else WorldPhase:RestoreAll() end
		end)
		Toggle.new(doorSec, "Neon Glow Effect", "Game.DoorGlow", function() WorldPhase:ScanAllDoors() end)
		Slider.new(doorSec, "Door Transparency", 10, 95, 65, 5, "%", function(t)
			StateStore:Set("Game.PhaseTransparency", t / 100)
			WorldPhase:ScanAllDoors()
		end)
		ColorPicker.new(doorSec, "Glow Color", "Game.GlowColor", function() WorldPhase:ScanAllDoors() end)

		local macroSec = createSec(tab.RightCol, "Weapon Switch Macro")
		Toggle.new(macroSec, "Enable Fake Macro", "Game.FakeMacro", function(v)
			if v then PrisonLifePlugin:StartMacro() else PrisonLifePlugin:StopMacro() end
		end)
		Keybind.new(macroSec, "Macro Hotkey", "Game.FakeMacroKey")
		Dropdown.new(macroSec, "Macro Trigger Mode", { "Toggle", "Hold" }, "Game.FakeMacroMode")
		Slider.new(macroSec, "Cycle Switch Delay", 30, 500, 30, 10, " ms", function(ms)
			StateStore:Set("Game.FakeMacroDelay", ms / 1000)
		end)

		local meleeSec = createSec(tab.RightCol, "Melee Exploits")
		Toggle.new(meleeSec, "Punch Aura", "Game.PunchAura")
		Slider.new(meleeSec, "Aura Radius", 5, 40, "Game.PunchAuraRange", 1, " studs")
		Toggle.new(meleeSec, "Super Multi-Punch", "Game.SuperPunch")
		Slider.new(meleeSec, "Hit Multiplier", 1, 30, "Game.SuperPunchHits", 1, " hits")

		local teleSec = createSec(tab.RightCol, "Prison Map Teleports")
		for _, loc in ipairs(Manifest.LOCATIONS) do
			Components.CreateButton(teleSec, loc.Name, function()
				LocomotionService:TeleportToPosition(loc.CFrame.Position)
				UIEngine:Notify("Teleport", "Warped to " .. loc.Name, 1.5, ThemeEngine:GetToken("Success"))
			end)
		end
	end

	function PrisonLifePlugin:Initialize()
		WorldPhase:Initialize()
		WeaponMods:Initialize()

		TaskScheduler:RegisterHeartbeat("PrisonLifeHeartbeat", 20, onHeartbeat)
		UserInputService.InputBegan:Connect(onInputBegan)
		UserInputService.InputEnded:Connect(onInputEnded)
	end

	function PrisonLifePlugin:Destroy()
		self:StopMacro()
		WorldPhase:RestoreAll()
		WeaponMods:RestoreAll()
	end

	return PrisonLifePlugin
end
