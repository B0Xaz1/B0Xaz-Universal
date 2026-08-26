-- ════════════════════════════════════════════════════════════════════════════
-- UI/Components/ColorPicker.lua
-- Compact inline color picker widget with preset palette selection
-- ════════════════════════════════════════════════════════════════════════════

local DOM = require(script.Parent.Parent.DOM)

local ColorPicker = {}
ColorPicker.__index = ColorPicker

local QUICK_PALETTE = {
	Color3.fromRGB(0, 220, 70),   -- Green
	Color3.fromRGB(255, 255, 255), -- White
	Color3.fromRGB(235, 50, 65),   -- Red
	Color3.fromRGB(0, 200, 220),   -- Cyan
	Color3.fromRGB(170, 70, 250),  -- Purple
	Color3.fromRGB(255, 200, 50),  -- Yellow
}

function ColorPicker.new(parent, label, defaultColor, callback, themeEngine)
	local self = setmetatable({}, ColorPicker)
	self._theme = themeEngine
	self._color = typeof(defaultColor) == "Color3" and defaultColor or Color3.new(1, 1, 1)
	self._callback = callback
	self._expanded = false

	local labelView = DOM.Create("TextLabel", {
		Text = label or "Color",
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

	self.Preview = DOM.Create("TextButton", {
		Size = UDim2.fromOffset(18, 18),
		Position = UDim2.new(1, -24, 0.5, -9),
		BackgroundColor3 = self._color,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Parent = self.Container,
	}, {
		DOM.CreateStroke(self._theme.Current.Border, 1),
	})

	self.PaletteFrame = DOM.Create("Frame", {
		Size = UDim2.new(1, 0, 0, 26),
		Position = UDim2.new(0, 0, 1, 4),
		BackgroundColor3 = self._theme.Current.Panel,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 15,
		Parent = self.Container,
	}, {
		DOM.CreateStroke(self._theme.Current.Border, 1),
		DOM.Create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 4),
			VerticalAlignment = Enum.VerticalAlignment.Center,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		}),
	})

	for _, col in ipairs(QUICK_PALETTE) do
		local btn = DOM.Create("TextButton", {
			Size = UDim2.fromOffset(16, 16),
			BackgroundColor3 = col,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 16,
			Parent = self.PaletteFrame,
		}, {
			DOM.CreateStroke(Color3.fromRGB(40, 40, 40), 1),
		})

		btn.MouseButton1Click:Connect(function()
			self:Set(col)
			self._expanded = false
			self.PaletteFrame.Visible = false
		end)
	end

	self.Preview.MouseButton1Click:Connect(function()
		self._expanded = not self._expanded
		self.PaletteFrame.Visible = self._expanded
	end)

	themeEngine:Bind(labelView, "TextColor3", "Text")

	return self
end

function ColorPicker:Set(color, silent)
	if typeof(color) ~= "Color3" then return end
	self._color = color
	self.Preview.BackgroundColor3 = color

	if not silent and type(self._callback) == "function" then
		pcall(self._callback, color)
	end
end

function ColorPicker:Get()
	return self._color
end

return ColorPicker
