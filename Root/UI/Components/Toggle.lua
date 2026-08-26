-- ════════════════════════════════════════════════════════════════════════════
-- UI/Components/Toggle.lua
-- Declarative state toggle switch widget
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
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = self._theme.Current.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -46, 1, 0),
	})

	self.Container = DOM.Create("Frame", {
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		Parent = parent,
	}, { labelView })

	themeEngine:Bind(labelView, "TextColor3", "Text")

	self.Button = DOM.Create("TextButton", {
		Size = UDim2.fromOffset(36, 20),
		Position = UDim2.new(1, -36, 0.5, -10),
		BackgroundColor3 = self._state and self._theme.Current.ToggleOn or self._theme.Current.ToggleOff,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Parent = self.Container,
	}, {
		DOM.CreateStroke(self._theme.Current.BorderDim, 1),
		DOM.CreateCorner("full"),
	})

	self.Pill = DOM.Create("Frame", {
		Size = UDim2.fromOffset(14, 14),
		Position = self._state and UDim2.new(1, -18, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Parent = self.Button,
	}, {
		DOM.CreateCorner("full"),
	})

	self.Button.MouseButton1Click:Connect(function()
		self:Set(not self._state)
	end)

	return self
end

function Toggle:Set(state, silent)
	self._state = state == true
	self.Button.BackgroundColor3 = self._state and self._theme.Current.ToggleOn or self._theme.Current.ToggleOff
	self.Pill.Position = self._state and UDim2.new(1, -18, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)

	if not silent and type(self._callback) == "function" then
		pcall(self._callback, self._state)
	end
end

function Toggle:Get()
	return self._state
end

return Toggle
