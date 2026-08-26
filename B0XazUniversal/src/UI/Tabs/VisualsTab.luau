--!strict
-- ══════════════════════════════════════════════════════════════════════════════
-- B0XazUniversal - Visuals & ESP UI Tab
-- Controls 2D skeletal rendering, bounding boxes, health bars, highlights,
-- world lighting parameters, and speed line overlays.
-- ══════════════════════════════════════════════════════════════════════════════

local Lighting = game:GetService("Lighting")

return function(services: any, tab: any)
	local ThemeEngine = services:Get("ThemeEngine")
	local StateStore = services:Get("StateStore")
	local Require = services:Get("Require")
	local DOM = services:Get("DOM")

	local Toggle = Require("B0XazUniversal/src/UI/Components/Toggle.luau")
	local Slider = Require("B0XazUniversal/src/UI/Components/Slider.luau")
	local Dropdown = Require("B0XazUniversal/src/UI/Components/Dropdown.luau")
	local ColorPicker = Require("B0XazUniversal/src/UI/Components/ColorPicker.luau")
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
	-- Left Column: 2D ESP & Formatting
	-- ─────────────────────────────────────────────────────────────────────────
	local espMainSec = createSection(tab.LeftCol, "Player ESP")
	Toggle.new(espMainSec, "Enable Player ESP", "ESP.Enabled", nil, 2)
	Toggle.new(espMainSec, "Draw 2D Bounding Boxes", "ESP.Box")
	Toggle.new(espMainSec, "Show Display Names", "ESP.Name")
	Toggle.new(espMainSec, "Show Health Bar", "ESP.Health")
	Toggle.new(espMainSec, "Show Distance", "ESP.Distance")
	Toggle.new(espMainSec, "Show Equipped Weapon", "ESP.Tool")
	Toggle.new(espMainSec, "Show Backpack Items", "ESP.Backpack")
	Toggle.new(espMainSec, "Show Tracers", "ESP.Tracers")
	Toggle.new(espMainSec, "Show 2D Skeletons", "ESP.Skeleton")
	Toggle.new(espMainSec, "Draw Head Dot", "ESP.HeadDot")
	Toggle.new(espMainSec, "Look Direction Lines", "ESP.LookDir")
	Toggle.new(espMainSec, "Team Check Filter", "ESP.TeamCheck")

	local espConfigSec = createSection(tab.LeftCol, "ESP Configuration")
	Slider.new(espConfigSec, "Max Rendering Distance", 100, 2000, "ESP.MaxDist", 50, " studs")
	ColorPicker.new(espConfigSec, "Global ESP Color", "ESP.Color")
	Dropdown.new(espConfigSec, "ESP Font Style", { "Monospace", "UI", "System", "Plex" }, "ESP.Font")
	Toggle.new(espConfigSec, "Text Outlines", "ESP.Outline")
	Toggle.new(espConfigSec, "Auto-Scaling Distance", "ESP.AutoScaling")

	-- ─────────────────────────────────────────────────────────────────────────
	-- Right Column: 3D Chams, World Lighting & Speedlines
	-- ─────────────────────────────────────────────────────────────────────────
	local chamsSec = createSection(tab.RightCol, "Player Chams (Highlights)")
	Toggle.new(chamsSec, "Enable Highlights", "Chams.Enabled", nil, 2)
	Toggle.new(chamsSec, "Use Player Team Color", "Chams.UseTeamColor")
	Dropdown.new(chamsSec, "Depth Rendering Mode", { "AlwaysOnTop", "Occluded" }, "Chams.DepthMode")
	ColorPicker.new(chamsSec, "Highlight Fill Color", "Chams.FillColor")
	ColorPicker.new(chamsSec, "Highlight Outline Color", "Chams.OutlineColor")

	local lightingSec = createSection(tab.RightCol, "World & Lighting")
	Toggle.new(lightingSec, "Fullbright Mode", "Visuals.Fullbright", function(active)
		if active then
			Lighting.Ambient = Color3.new(1, 1, 1)
			Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
			Lighting.Brightness = 2
			Lighting.GlobalShadows = false
		end
	end, 1)

	Slider.new(lightingSec, "Time of Day", 0, 24, math.floor(Lighting.ClockTime), 1, "h", function(timeVal)
		Lighting.ClockTime = timeVal
	end)

	local fxSec = createSection(tab.RightCol, "Visual Effects")
	Toggle.new(fxSec, "Draw Radial Speed Lines", "Extras.SpeedLines", nil, 1)
end
