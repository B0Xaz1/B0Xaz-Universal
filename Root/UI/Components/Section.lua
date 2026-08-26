-- ════════════════════════════════════════════════════════════════════════════
-- UI/Components/Section.lua
-- Group header: accent tick, bold label, and a hairline rule
-- ════════════════════════════════════════════════════════════════════════════

local DOM = require(script.Parent.Parent.DOM)

local Section = {}
Section.__index = Section

function Section.new(parent, title, themeEngine)
	local self = setmetatable({}, Section)
	local theme = themeEngine.Current

	self.Frame = DOM.Create("Frame", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		Parent = parent,
	})

	self.Bar = DOM.Create("Frame", {
		Size = UDim2.fromOffset(3, 14),
		Position = UDim2.fromOffset(0, 8),
		BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0,
		Parent = self.Frame,
	}, { DOM.CreateCorner(2) })

	self.Label = DOM.Create("TextLabel", {
		Text = title or "Section",
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 8),
		Size = UDim2.new(1, -20, 0, 14),
		Parent = self.Frame,
	})

	self.Line = DOM.Create("Frame", {
		Size = UDim2.new(1, -20, 0, 1),
		Position = UDim2.new(0, 10, 0, 28),
		BackgroundColor3 = theme.BorderDim,
		BorderSizePixel = 0,
		Parent = self.Frame,
	})

	themeEngine:Bind(self.Bar, "BackgroundColor3", "Accent")
	themeEngine:Bind(self.Label, "TextColor3", "Text")
	themeEngine:Bind(self.Line, "BackgroundColor3", "BorderDim")

	return self
end

return Section
