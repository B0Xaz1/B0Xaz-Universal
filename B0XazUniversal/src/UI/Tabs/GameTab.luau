--!strict
-- ══════════════════════════════════════════════════════════════════════════════
-- B0XazUniversal - Dynamic Game Plugin UI Tab
-- Inspects active runtime PlaceId metadata and dynamically mounts game-specific
-- plugin interfaces when supported.
-- ══════════════════════════════════════════════════════════════════════════════

return function(services: any, tab: any)
	local ThemeEngine = services:Get("ThemeEngine")
	local PluginManager = services:Get("PluginManager")
	local Environment = services:Get("Environment")
	local UIEngine = services:Get("UIEngine")
	local Require = services:Get("Require")
	local DOM = services:Get("DOM")

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
	-- Target Place Context & Plugin Mounting
	-- ─────────────────────────────────────────────────────────────────────────
	local infoSec = createSection(tab.LeftCol, "Target Game Context")

	Components.CreateButton(infoSec, "Place ID: " .. tostring(game.PlaceId), function()
		Environment.SetClipboard(tostring(game.PlaceId))
		UIEngine:Notify("Place ID", "Copied to clipboard.", 2, ThemeEngine:GetToken("Success"))
	end)

	local pluginName = PluginManager:GetActivePluginName()
	Components.CreateButton(infoSec, "Active Plugin: " .. pluginName, function() end)

	if PluginManager:IsGameSupported() then
		PluginManager:MountUI(tab)
	else
		local unsupSec = createSection(tab.RightCol, "No Plugin Detected")
		Components.CreateButton(unsupSec, "No modifications available for this place.", function() end)
	end
end
