-- ════════════════════════════════════════════════════════════════════════════
-- UI/Window.lua
-- Draggable master window controller, tab navigator, and notification HUD
-- ════════════════════════════════════════════════════════════════════════════

local UserInputService = game:GetService("UserInputService")
local DOM = require(script.Parent.DOM)

local Window = {}
Window.__index = Window

function Window.new(title, themeEngine, container)
	local self = setmetatable({}, Window)
	self._theme = themeEngine
	self._container = container
	self._tabs = {}
	self._activeTab = nil
	self.Visible = true

	local safeParent = DOM.GetSafeParent()

	-- Root ScreenGui
	self.ScreenGui = DOM.Create("ScreenGui", {
		Name = DOM.RandomName(),
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
		DisplayOrder = 999,
		Parent = safeParent,
	})

	-- Main Window Frame
	self.MainFrame = DOM.Create("Frame", {
		Size = UDim2.fromOffset(660, 460),
		Position = UDim2.new(0.5, -330, 0.5, -230),
		BackgroundColor3 = self._theme.Current.Bg,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = self.ScreenGui,
	})
	local mainStroke = DOM.CreateStroke(self._theme.Current.Border, 1)
	mainStroke.Parent = self.MainFrame
	self._theme:Bind(self.MainFrame, "BackgroundColor3", "Bg")
	self._theme:Bind(mainStroke, "Color", "Border")

	-- Title Bar
	self.TitleBar = DOM.Create("Frame", {
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundColor3 = self._theme.Current.Side,
		BorderSizePixel = 0,
		Parent = self.MainFrame,
	}, {
		DOM.Create("TextLabel", {
			Text = " " .. (title or "B0Xaz Universal"),
			Font = Enum.Font.Code,
			TextSize = 13,
			TextColor3 = self._theme.Current.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -30, 1, 0),
		}),
	})
	self._theme:Bind(self.TitleBar, "BackgroundColor3", "Side")

	-- Dragging Logic
	self:_initDragging(self.TitleBar, self.MainFrame)

	-- Tab Navigation Strip
	self.TabBar = DOM.Create("Frame", {
		Size = UDim2.new(1, 0, 0, 26),
		Position = UDim2.new(0, 0, 0, 28),
		BackgroundColor3 = self._theme.Current.Side,
		BorderSizePixel = 0,
		Parent = self.MainFrame,
	})
	self._theme:Bind(self.TabBar, "BackgroundColor3", "Side")

	self.TabList = DOM.Create("ScrollingFrame", {
		Size = UDim2.new(1, -8, 1, 0),
		Position = UDim2.new(0, 4, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.X,
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		Parent = self.TabBar,
	}, {
		DOM.Create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 4),
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
	})

	-- Tab Content View
	self.Content = DOM.Create("Frame", {
		Size = UDim2.new(1, 0, 1, -54),
		Position = UDim2.new(0, 0, 0, 54),
		BackgroundTransparency = 1,
		Parent = self.MainFrame,
	})

	-- Notifications Layer
	self.NotifyContainer = DOM.Create("Frame", {
		Size = UDim2.new(0, 280, 1, -20),
		Position = UDim2.new(1, -290, 0, 10),
		BackgroundTransparency = 1,
		Parent = self.ScreenGui,
	}, {
		DOM.Create("UIListLayout", {
			Padding = UDim.new(0, 6),
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
		}),
	})

	return self
end

function Window:_initDragging(handle, target)
	local dragging, dragStart, startPos = false, nil, nil

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = target.Position
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			target.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

function Window:AddTab(name)
	local tab = {
		Name = name,
		Page = DOM.Create("ScrollingFrame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = self._theme.Current.Accent,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Visible = false,
			Parent = self.Content,
		}, {
			DOM.Create("UIListLayout", { Padding = UDim.new(0, 8) }),
			DOM.CreatePadding(8),
		}),
		Button = DOM.Create("TextButton", {
			Text = name,
			Font = Enum.Font.Code,
			TextSize = 11,
			TextColor3 = self._theme.Current.TextDim,
			BackgroundColor3 = self._theme.Current.Elem,
			Size = UDim2.new(0, 80, 0, 20),
			BorderSizePixel = 0,
			Parent = self.TabList,
		}),
	}
	self._theme:Bind(tab.Button, "BackgroundColor3", "Elem")

	tab.Button.MouseButton1Click:Connect(function()
		self:SelectTab(tab)
	end)

	table.insert(self._tabs, tab)
	if #self._tabs == 1 then
		self:SelectTab(tab)
	end
	return tab
end

function Window:SelectTab(tab)
	for _, t in ipairs(self._tabs) do
		t.Page.Visible = false
		t.Button.TextColor3 = self._theme.Current.TextDim
	end
	tab.Page.Visible = true
	tab.Button.TextColor3 = self._theme.Current.Accent
	self._activeTab = tab
end

function Window:Notify(title, message, duration, color)
	local card = DOM.Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = self._theme.Current.Panel,
		BorderSizePixel = 0,
		Parent = self.NotifyContainer,
	}, {
		DOM.CreateStroke(color or self._theme.Current.Accent, 1),
		DOM.CreatePadding(6, 6, 8, 8),
		DOM.Create("UIListLayout", { Padding = UDim.new(0, 2) }),
		DOM.Create("TextLabel", {
			Text = title or "Notification",
			Font = Enum.Font.Code,
			TextSize = 12,
			TextColor3 = self._theme.Current.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 14),
		}),
		DOM.Create("TextLabel", {
			Text = message or "",
			Font = Enum.Font.Code,
			TextSize = 11,
			TextColor3 = self._theme.Current.TextDim,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
		}),
	})

	task.delay(duration or 3.5, function()
		if card and card.Parent then card:Destroy() end
	end)
end

function Window:SetVisible(visible)
	self.Visible = visible
	self.MainFrame.Visible = visible
end

function Window:Destroy()
	if self.ScreenGui then self.ScreenGui:Destroy() end
end

return Window
