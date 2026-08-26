-- ════════════════════════════════════════════════════════════════════════════
-- UI/Components/Button.lua
-- Executor-safe action button component (flat, bordered)
-- ════════════════════════════════════════════════════════════════════════════

local DOM = require(script.Parent.Parent.DOM)

local Button = {}
Button.__index = Button

function Button.new(parent, text, callback, themeEngine, domModule)
	local dom = domModule or DOM
	local self = setmetatable({}, Button)
	self._theme = themeEngine
	self._callback = callback

	self.Frame = dom.Create("TextButton", {
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundColor3 = self._theme.Current.Elem,
		BorderSizePixel = 0,
		Text = text or "Button",
		Font = Enum.Font.Code,
		TextSize = 12,
		TextColor3 = self._theme.Current.Text,
		AutoButtonColor = false,
		Parent = parent,
	}, {
		dom.CreateStroke(self._theme.Current.BorderDim, 1),
	})

	self._theme:Bind(self.Frame, "BackgroundColor3", "Elem")
	self._theme:Bind(self.Frame, "TextColor3", "Text")

	self.Frame.MouseEnter:Connect(function()
		self.Frame.BackgroundColor3 = self._theme.Current.ElemHover
	end)
	self.Frame.MouseLeave:Connect(function()
		self.Frame.BackgroundColor3 = self._theme.Current.Elem
	end)
	self.Frame.MouseButton1Click:Connect(function()
		if type(self._callback) == "function" then
			pcall(self._callback)
		end
	end)

	return self
end

return Button
