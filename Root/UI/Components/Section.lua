-- ════════════════════════════════════════════════════════════════════════════
-- UI/Components/Section.lua
-- Group header: plain label with a hairline rule underneath
-- ════════════════════════════════════════════════════════════════════════════

local DOM = require(script.Parent.Parent.DOM)

local Section = {}
Section.__index = Section

function Section.new(parent, title, themeEngine)
	local self = setmetatable({}, Section)
	local theme = themeEngine.Current

	self.Frame = DOM.Create("Frame", {
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		Parent = parent,
	})

	self.Label = DOM.Create("TextLabel", {
		Text = title or "Section",
		Font = Enum.Font.Code,
		TextSize = 12,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.new(1, 0, 0, 16),
		Parent = self.Frame,
	})

	self.Line = DOM.Create("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 0, 22),
		BackgroundColor3 = theme.BorderDim,
		BorderSizePixel = 0,
		Parent = self.Frame,
	})

	themeEngine:Bind(self.Label, "TextColor3", "Text")
	themeEngine:Bind(self.Line, "BackgroundColor3", "BorderDim")

	return self
end

return Section
