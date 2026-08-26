-- ════════════════════════════════════════════════════════════════════════════
-- UI/Components/Button.lua
-- Executor-safe action button component
-- ════════════════════════════════════════════════════════════════════════════

local DOM = setmetatable({}, {
	__index = function(_, k)
		return _G.B0XazDOM and _G.B0XazDOM[k]
	end
})

local Button = {}
Button.__index = Button

function Button.new(parent, text, callback, themeEngine, domModule)
	local dom = domModule or _G.B0XazDOM
	local self = setmetatable({}, Button)
	self._theme = themeEngine
	self._callback = callback

	self.Frame = dom.Create("TextButton", {
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundColor3 = self._theme.Current.Elem,
		BorderSizePixel = 0,
		Text = text or "Button",
		Font = Enum.Font.Code,
		TextSize = 11,
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
