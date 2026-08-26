-- ════════════════════════════════════════════════════════════════════════════
-- UI/Components/Keybind.lua
-- Interactive key and mouse button binder component
-- ════════════════════════════════════════════════════════════════════════════

local UserInputService = game:GetService("UserInputService")
local DOM = require(script.Parent.Parent.DOM)

local Keybind = {}
Keybind.__index = Keybind

local function formatBind(bind)
	if not bind then return "None" end
	if typeof(bind) == "EnumItem" then return bind.Name end
	return tostring(bind)
end

function Keybind.new(parent, label, defaultBind, callback, themeEngine)
	local self = setmetatable({}, Keybind)
	self._theme = themeEngine
	self._bind = defaultBind
	self._callback = callback
	self._isBinding = false

	self.Container = DOM.Create("Frame", {
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1,
		Parent = parent,
	})

	DOM.Create("TextLabel", {
		Text = label or "Keybind",
		Font = Enum.Font.Code,
		TextSize = 11,
		TextColor3 = self._theme.Current.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -70, 1, 0),
		Parent = self.Container,
	})

	self.Button = DOM.Create("TextButton", {
		Size = UDim2.fromOffset(65, 18),
		Position = UDim2.new(1, -65, 0.5, -9),
		BackgroundColor3 = self._theme.Current.Elem,
		BorderSizePixel = 0,
		Text = "[" .. formatBind(self._bind) .. "]",
		Font = Enum.Font.Code,
		TextSize = 10,
		TextColor3 = self._theme.Current.TextDim,
		AutoButtonColor = false,
		Parent = self.Container,
	}, {
		DOM.CreateStroke(self._theme.Current.BorderDim, 1),
	})

	self._theme:Bind(self.Button, "BackgroundColor3", "Elem")

	self.Button.MouseButton1Click:Connect(function()
		if self._isBinding then return end
		self._isBinding = true
		self.Button.Text = "[...]"
		self.Button.TextColor3 = self._theme.Current.Accent

		local conn
		conn = UserInputService.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Keyboard then
				if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
					self:Set(nil)
				else
					self:Set(input.KeyCode)
				end
			elseif input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.MouseButton2
				or input.UserInputType == Enum.UserInputType.MouseButton3 then
				self:Set(input.UserInputType)
			end
			self._isBinding = false
			conn:Disconnect()
		end)
	end)

	return self
end

function Keybind:Set(bind, silent)
	self._bind = bind
	self.Button.Text = "[" .. formatBind(self._bind) .. "]"
	self.Button.TextColor3 = self._theme.Current.TextDim

	if not silent and type(self._callback) == "function" then
		pcall(self._callback, self._bind)
	end
end

function Keybind:Get()
	return self._bind
end

return Keybind
