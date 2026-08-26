-- ════════════════════════════════════════════════════════════════════════════
-- UI/Components/Toggle.lua
-- Square checkbox-style toggle widget
-- ════════════════════════════════════════════════════════════════════════════

local DOM = require(script.Parent.Parent.DOM)

local Toggle = {}
Toggle.__index = Toggle

function Toggle.new(parent, label, defaultState, callback, themeEngine)
	local self = setmetatable({}, Toggle)
	self._theme = themeEngine
	self._state = defaultState == true
	self._callback = callback

	local labelView = DOM.Create("TextLabel", {
		Text = label or "Toggle",
		Font = Enum.Font.Code,
		TextSize = 11,
		TextColor3 = self._theme.Current.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -30, 1, 0),
	})

	self.Container = DOM.Create("Frame", {
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
		Parent = parent,
	}, { labelView })

	themeEngine:Bind(labelView, "TextColor3", "Text")

	self.Button = DOM.Create("TextButton", {
		Size = UDim2.fromOffset(16, 16),
		Position = UDim2.new(1, -24, 0.5, -8),
		BackgroundColor3 = self._state and self._theme.Current.ToggleOn or self._theme.Current.ToggleOff,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Parent = self.Container,
	}, {
		DOM.CreateStroke(self._theme.Current.Border, 1),
	})

	self.Button.MouseButton1Click:Connect(function()
		self:Set(not self._state)
	end)

	return self
end

function Toggle:Set(state, silent)
	self._state = state == true
	self.Button.BackgroundColor3 = self._state and self._theme.Current.ToggleOn or self._theme.Current.ToggleOff

	if not silent and type(self._callback) == "function" then
		pcall(self._callback, self._state)
	end
end

function Toggle:Get()
	return self._state
end

return Toggle
