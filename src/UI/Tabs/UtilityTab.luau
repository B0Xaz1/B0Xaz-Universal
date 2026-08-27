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

	local Toggle = Require("src/UI/Components/Toggle.luau", services)
	local Slider = Require("src/UI/Components/Slider.luau", services)
	local Components = Require("src/UI/Components/Textbox.luau", services)

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

	local hitboxSec = createSection(tab.LeftCol, "Hitbox Expansion")
	Toggle.new(hitboxSec, "Expand Character Hitboxes", "Extras.Hitbox.Enabled", nil, 1)
	Slider.new(hitboxSec, "Hitbox Radius", 4, 60, "Extras.Hitbox.Size", 2, " studs")

	local spinSec = createSection(tab.LeftCol, "Spin Bot System")
	Toggle.new(spinSec, "Enable Spin Bot", "Extras.SpinBot.Enabled", nil, 1)
	Slider.new(spinSec, "Spin Velocity Speed", 1, 100, "Extras.SpinBot.Speed", 5)

	-- Blocks the velocity impulse a fling attack applies to your character;
	-- your own teleports/flings/flight are auto-suppressed so they never
	-- trip the guard.
	local antiFlingSec = createSection(tab.LeftCol, "Fling Defense")
	Toggle.new(antiFlingSec, "Anti Fling (Block Impulses)", "Extras.AntiFling.Enabled", nil, 1)
	Slider.new(antiFlingSec, "Impulse Threshold", 200, 5000, "Extras.AntiFling.Threshold", 50, " u/s²")
	Toggle.new(antiFlingSec, "Snap Back Position", "Extras.AntiFling.SnapBack")

	local serverSec = createSection(tab.RightCol, "Anti-AFK & Server Management")

	-- Bind/Unbind by key keeps at most one anti-AFK connection registered
	-- with the disposer no matter how often the toggle is flipped.
	local function updateAntiAfk(enabled: boolean)
		if enabled and Players.LocalPlayer then
			local conn = Players.LocalPlayer.Idled:Connect(function()
				pcall(function()
					VirtualUser:CaptureController()
					VirtualUser:ClickButton2(Vector2.zero)
				end)
			end)
			Disposer:Bind("B0XazAntiAfk", conn)
		else
			Disposer:Unbind("B0XazAntiAfk")
		end
	end

	Toggle.new(serverSec, "Enable Anti-AFK", "Settings.AntiAfk", updateAntiAfk)

	local lastHopTime = 0
	Components.CreateButton(serverSec, "Server Hop (Public Matchmaking)", function()
		-- A short cooldown prevents double-clicks from stacking hops
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
					-- Queue the launcher source first so the new instance
					-- auto-runs the suite right after the teleport lands.
					local globalEnv = (getgenv and getgenv()) or _G
					local initUrl = tostring(globalEnv.B0XazInitURL or "")
					if initUrl ~= "" then
						Environment.QueueTeleport("loadstring(game:HttpGet('" .. initUrl .. "'))()")
					end
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
