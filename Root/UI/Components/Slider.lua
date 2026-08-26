-- ════════════════════════════════════════════════════════════════════════════
-- UI/Components/Slider.lua
-- Draggable numeric slider widget with suffix formatting
-- ════════════════════════════════════════════════════════════════════════════

local UserInputService = game:GetService("UserInputService")
local DOM = require(script.Parent.Parent.DOM)

local Slider = {}
Slider.__index = Slider

function Slider.new(parent, label, defaultVal, min, max, callback, suffix, themeEngine)
	local self = setmetatable({}, Slider)
	self._theme = themeEngine
	self._min = min or 0
	self._max = max or 100
	self._value = math.clamp(defaultVal or self._min, self._min, self._max)
	self._callback = callback
	self._suffix = suffix or ""
	self._dragging = false

	self.Container = DOM.Create("Frame", {
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 1,
		Parent = parent,
	})

	local topRow = DOM.Create("Frame", {
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		Parent = self.Container,
	})

	self.TitleLabel = DOM.Create("TextLabel", {
		Text = label or "Slider",
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = self._theme.Current.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(0.7, 0, 1, 0),
		Parent = topRow,
	})

	self.ValueLabel = DOM.Create("TextLabel", {
		Text = tostring(self._value) .. self._suffix,
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextColor3 = self._theme.Current.TextDim,
		TextXAlignment = Enum.TextXAlignment.Right,
		BackgroundTransparency = 1,
		Size = UDim2.new(0.3, 0, 1, 0),
		Position = UDim2.new(0.7, 0, 0, 0),
		Parent = topRow,
	})

	self.Track = DOM.Create("TextButton", {
		Size = UDim2.new(1, 0, 0, 12),
		Position = UDim2.new(0, 0, 0, 20),
		BackgroundColor3 = self._theme.Current.Elem,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Parent = self.Container,
	}, {
		DOM.CreateStroke(self._theme.Current.BorderDim, 1),
		DOM.CreateCorner(6),
	})

	local ratio = (self._value - self._min) / (self._max - self._min)
	self.Fill = DOM.Create("Frame", {
		Size = UDim2.new(ratio, 0, 1, 0),
		BackgroundColor3 = self._theme.Current.Accent,
		BorderSizePixel = 0,
		Parent = self.Track,
	}, {
		DOM.CreateCorner(6),
	})

	self._theme:Bind(self.TitleLabel, "TextColor3", "Text")
	self._theme:Bind(self.ValueLabel, "TextColor3", "TextDim")
	self._theme:Bind(self.Track, "BackgroundColor3", "Elem")
	self._theme:Bind(self.Fill, "BackgroundColor3", "Accent")

	local function updateFromInput(inputX)
		local trackAbsPos = self.Track.AbsolutePosition.X
		local trackAbsSize = self.Track.AbsoluteSize.X
		local norm = math.clamp((inputX - trackAbsPos) / trackAbsSize, 0, 1)
		local calculated = math.floor(self._min + (self._max - self._min) * norm + 0.5)
		self:Set(calculated)
	end

	self.Track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			self._dragging = true
			updateFromInput(input.Position.X)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			self._dragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if self._dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromInput(input.Position.X)
		end
	end)

	return self
end

function Slider:Set(value, silent)
	self._value = math.clamp(tonumber(value) or self._min, self._min, self._max)
	local ratio = (self._value - self._min) / (self._max - self._min)
	self.Fill.Size = UDim2.new(ratio, 0, 1, 0)
	self.ValueLabel.Text = tostring(self._value) .. self._suffix

	if not silent and type(self._callback) == "function" then
		pcall(self._callback, self._value)
	end
end

function Slider:Get()
	return self._value
end

return Slider
