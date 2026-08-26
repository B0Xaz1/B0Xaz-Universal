--!strict
-- ══════════════════════════════════════════════════════════════════════════════
-- B0XazUniversal - Utilities & Performance UI Tab
-- Performance strippers, hitbox dilations, spin bot parameters, on-screen
-- telemetry monitors, Anti-AFK hooks, and automated server hopping.
-- ══════════════════════════════════════════════════════════════════════════════

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local Players = game:GetService("Players")

return function(services: any, tab: any)
	local ThemeEngine = services:Get("ThemeEngine")
	local StateStore = services:Get("StateStore")
	local Disposer = services:Get("Disposer")
	local Environment = services:Get("Environment")
	local UIEngine = services:Get("UIEngine")
	local Require = services:Get("Require")
	local DOM = services:Get("DOM")

	local Toggle = Require("B0XazUniversal/src/UI/Components/Toggle.luau")
	local Slider = Require("B0XazUniversal/src/UI/Components/Slider.luau")
	local Components = Require("B0XazUniversal/src/UI/Components/Textbox.luau")

	local function createSection(parent: Instance, title: string): Frame
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

	-- ─────────────────────────────────────────────────────────────────────────
	-- Left Column: Performance Boosters, Hitbox & SpinBot
	-- ─────────────────────────────────────────────────────────────────────────
	local perfSec = createSection(tab.LeftCol, "Performance Boosters")
	Toggle.new(perfSec, "Strip Textures & Decals", "Performance.NoTextures")
	Toggle.new(perfSec, "Force Flat Smooth Plastic", "Performance.LowMaterials")
	Toggle.new(perfSec, "Reduce 3D Terrain Fidelity", "Performance.OptimizeTerrain")
	Toggle.new(perfSec, "Disable Post-Processing FX", "Performance.NoPostProcessing")
	Toggle.new(perfSec, "Disable Global Shadows", "Performance.NoShadows")
	Toggle.new(perfSec, "Disable Particle Emitters", "Performance.NoParticles")

	local hitboxSec = createSection(tab.LeftCol, "Hitbox Expansion")
	Toggle.new(hitboxSec, "Expand Character Hitboxes", "Extras.Hitbox.Enabled", nil, 1)
	Slider.new(hitboxSec, "Hitbox Radius", 4, 60, "Extras.Hitbox.Size", 2, " studs")

	local spinSec = createSection(tab.LeftCol, "Spin Bot System")
	Toggle.new(spinSec, "Enable Spin Bot", "Extras.SpinBot.Enabled", nil, 1)
	Slider.new(spinSec, "Spin Velocity Speed", 1, 100, "Extras.SpinBot.Speed", 5)

	-- ─────────────────────────────────────────────────────────────────────────
	-- Right Column: Telemetry & Server Management
	-- ─────────────────────────────────────────────────────────────────────────
	local statSec = createSection(tab.RightCol, "On-Screen Telemetry")
	Toggle.new(statSec, "Display FPS Counter", "Settings.ShowFPS")
	Toggle.new(statSec, "Display Ping Monitor", "Settings.ShowPing")

	local serverSec = createSection(tab.RightCol, "Anti-AFK & Server Management")

	-- Anti-AFK Hook
	local afkConn: RBXScriptConnection? = nil
	local function updateAntiAfk(enabled: boolean)
		if afkConn then
			afkConn:Disconnect()
			afkConn = nil
		end
		if enabled and Players.LocalPlayer then
			afkConn = Players.LocalPlayer.Idled:Connect(function()
				pcall(function()
					VirtualUser:CaptureController()
					VirtualUser:ClickButton2(Vector2.zero)
				end)
			end)
			Disposer:Add(afkConn)
		end
	end

	Toggle.new(serverSec, "Enable Anti-AFK", "Settings.AntiAfk", updateAntiAfk)

	-- Server Hop Pipeline
	local lastHopTime = 0
	Components.CreateButton(serverSec, "Server Hop (Public Matchmaking)", function()
		local now = os.clock()
		if (now - lastHopTime) < 3 then
			UIEngine:Notify("Server Hop", "Please wait before hopping again.", 2, ThemeEngine:GetToken("Warning"))
			return
		end
		lastHopTime = now
		UIEngine:Notify("Server Hop", "Searching for optimal public instances...", 3, ThemeEngine:GetToken("Accent"))

		task.spawn(function()
			local ok, rawData = pcall(function()
				return game:HttpGet(string.format("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100", tostring(game.PlaceId)))
			end)
			if not ok or not rawData then
				UIEngine:Notify("Server Hop", "Failed to reach Roblox API.", 3, ThemeEngine:GetToken("Danger"))
				return
			end

			local decodeOk, serverData = pcall(HttpService.JSONDecode, HttpService, rawData)
			if not decodeOk or typeof(serverData) ~= "table" or not serverData.data then
				UIEngine:Notify("Server Hop", "Malformed server response.", 3, ThemeEngine:GetToken("Danger"))
				return
			end

			for _, server in ipairs(serverData.data) do
				if server.id ~= game.JobId and server.playing and server.maxPlayers and server.playing < server.maxPlayers then
					Environment.QueueTeleport("loadstring(game:HttpGet('" .. tostring((getgenv and getgenv()).B0XazBaseURL or "") .. "init.luau'))()")
					pcall(function()
						TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, Players.LocalPlayer)
					end)
					return
				end
			end
			UIEngine:Notify("Server Hop", "No open servers found.", 3, ThemeEngine:GetToken("Warning"))
		end)
	end)
end
