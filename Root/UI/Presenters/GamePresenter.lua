-- ════════════════════════════════════════════════════════════════════════════
-- UI/Presenters/GamePresenter.lua
-- Binds game-specific scripts and dynamically loads Custom Game Adapter UI
-- ════════════════════════════════════════════════════════════════════════════

local DOM = require(script.Parent.Parent.DOM)
local Section = require(script.Parent.Parent.Components.Section)

local GamePresenter = {}

function GamePresenter.Build(tab, container, themeEngine)
	local gameLoader = container:Get("GameLoader")
	local page = tab.Page

	Section.new(page, "Game Modification Hub", themeEngine)

	DOM.Create("TextLabel", {
		Text = "Place Context: " .. tostring(game.PlaceId),
		Font = Enum.Font.Code,
		TextSize = 11,
		TextColor3 = themeEngine.Current.TextDim,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 16),
		Parent = page,
	})

	if gameLoader and gameLoader:IsSupported() then
		local adapter = gameLoader:Load()
		if adapter and type(adapter.BuildUI) == "function" then
			local ok, err = pcall(adapter.BuildUI, adapter, tab)
			if not ok then
				DOM.Create("TextLabel", {
					Text = "Adapter UI Error: " .. tostring(err),
					Font = Enum.Font.Code,
					TextSize = 11,
					TextColor3 = themeEngine.Current.Danger,
					TextWrapped = true,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 40),
					Parent = page,
				})
			end
		end
	else
		DOM.Create("TextLabel", {
			Text = "Universal fallbacks active. There are no bespoke modifications available for this place.",
			Font = Enum.Font.Code,
			TextSize = 11,
			TextColor3 = themeEngine.Current.TextMuted,
			TextWrapped = true,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 40),
			Parent = page,
		})
	end
end

return GamePresenter
