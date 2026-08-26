-- ════════════════════════════════════════════════════════════════════════════
-- UI/Components/Dropdown.lua
-- Expandable popover selection dropdown widget
-- ════════════════════════════════════════════════════════════════════════════

local DOM = require(script.Parent.Parent.DOM)

local Dropdown = {}
Dropdown.__index = Dropdown

function Dropdown.new(parent, label, items, callback, defaultItem, themeEngine)
	local self = setmetatable({}, Dropdown)
	self._theme = themeEngine
	self._items = items or {}
	self._selected = defaultItem or self._items[1] or "None"
	self._callback = callback
	self._open = false

	self.Container = DOM.Create("Frame", {
		Size = UDim2.new(1, 0, 0, 48),
		BackgroundTransparency = 1,
		Parent = parent,
	})

	DOM.Create("TextLabel", {
		Text = label or "Dropdown",
		Font = Enum.Font.Code,
		TextSize = 11,
		TextColor3 = self._theme.Current.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 14),
		Parent = self.Container,
	})

	self.Button = DOM.Create("TextButton", {
		Size = UDim2.new(1, 0, 0, 26),
		Position = UDim2.new(0, 0, 0, 18),
		BackgroundColor3 = self._theme.Current.Elem,
		BorderSizePixel = 0,
		Text = " " .. tostring(self._selected),
		Font = Enum.Font.Code,
		TextSize = 11,
		TextColor3 = self._theme.Current.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutoButtonColor = false,
		Parent = self.Container,
	}, {
		DOM.CreateStroke(self._theme.Current.BorderDim, 1),
	})

	self.Arrow = DOM.Create("TextLabel", {
		Text = "▼",
		Font = Enum.Font.Code,
		TextSize = 9,
		TextColor3 = self._theme.Current.TextDim,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 20, 1, 0),
		Position = UDim2.new(1, -20, 0, 0),
		Parent = self.Button,
	})

	self.ListFrame = DOM.Create("ScrollingFrame", {
		Size = UDim2.new(1, 0, 0, 100),
		Position = UDim2.new(0, 0, 1, 2),
		BackgroundColor3 = self._theme.Current.Panel,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = self._theme.Current.Accent,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false,
		ZIndex = 20,
		Parent = self.Button,
	}, {
		DOM.CreateStroke(self._theme.Current.Border, 1),
		DOM.Create("UIListLayout", { Padding = UDim.new(0, 2) }),
		DOM.CreatePadding(2),
	})

	self._theme:Bind(self.Button, "BackgroundColor3", "Elem")
	self._theme:Bind(self.Button, "TextColor3", "Text")
	self._theme:Bind(self.ListFrame, "BackgroundColor3", "Panel")

	self:_renderItems()

	self.Button.MouseButton1Click:Connect(function()
		self:Toggle()
	end)

	return self
end

function Dropdown:_renderItems()
	for _, child in ipairs(self.ListFrame:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end

	for _, item in ipairs(self._items) do
		local itmBtn = DOM.Create("TextButton", {
			Size = UDim2.new(1, 0, 0, 20),
			BackgroundColor3 = self._theme.Current.Elem,
			BackgroundTransparency = (item == self._selected) and 0 or 1,
			BorderSizePixel = 0,
			Text = " " .. tostring(item),
			Font = Enum.Font.Code,
			TextSize = 10,
			TextColor3 = (item == self._selected) and self._theme.Current.Accent or self._theme.Current.TextDim,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 21,
			Parent = self.ListFrame,
		})

		itmBtn.MouseButton1Click:Connect(function()
			self:Set(item)
			self:Toggle(false)
		end)
	end
end

function Dropdown:Toggle(forceState)
	self._open = forceState ~= nil and forceState or not self._open
	self.ListFrame.Visible = self._open
	self.Arrow.Text = self._open and "▲" or "▼"
end

function Dropdown:Set(item, silent)
	self._selected = tostring(item)
	self.Button.Text = " " .. self._selected
	self:_renderItems()

	if not silent and type(self._callback) == "function" then
		pcall(self._callback, self._selected)
	end
end

function Dropdown:Refresh(newList, keepSelection)
	self._items = newList or {}
	if not keepSelection or not table.find(self._items, self._selected) then
		self._selected = self._items[1] or "None"
		self.Button.Text = " " .. self._selected
	end
	self:_renderItems()
end

function Dropdown:Get()
	return self._selected
end

return Dropdown
