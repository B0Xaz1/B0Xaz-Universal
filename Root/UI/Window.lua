-- ════════════════════════════════════════════════════════════════════════════
-- UI/Window.lua
-- Draggable master window controller, tab navigator, and notification HUD
-- ════════════════════════════════════════════════════════════════════════════

local UserInputService = game:GetService("UserInputService")
local DOM = require(script.Parent.DOM)

local Window = {}
Window.__index = Window

local TITLE_HEIGHT = 34
local TAB_HEIGHT = 34

function Window.new(title, themeEngine, container)
	local self = setmetatable({}, Window)
	self._theme = themeEngine
	self._container = container
	self._tabs = {}
	self._activeTab = nil
	self.Visible = true

	local safeParent = DOM.GetSafeParent()
	local theme = themeEngine.Current

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
		BackgroundColor3 = theme.Bg,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = self.ScreenGui,
	}, {
		DOM.CreateCorner(10),
	})
	local mainStroke = DOM.CreateStroke(theme.Border, 1)
	mainStroke.Parent = self.MainFrame
	self._theme:Bind(self.MainFrame, "BackgroundColor3", "Bg")
	self._theme:Bind(mainStroke, "Color", "Border")

	-- Title Bar
	self.TitleBar = DOM.Create("Frame", {
		Size = UDim2.new(1, 0, 0, TITLE_HEIGHT),
		BackgroundColor3 = theme.Side,
		BorderSizePixel = 0,
		Parent = self.MainFrame,
	})
	self.TitleDot = DOM.Create("Frame", {
		Size = UDim2.fromOffset(8, 8),
		Position = UDim2.fromOffset(14, 13),
		BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0,
		Parent = self.TitleBar,
	}, { DOM.CreateCorner(2) })
	self.TitleLabel = DOM.Create("TextLabel", {
		Text = title or "B0Xaz Universal",
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(28, 0),
		Size = UDim2.new(1, -104, 1, 0),
		Parent = self.TitleBar,
	})
	self.TitleTag = DOM.Create("TextLabel", {
		Text = "universal hub",
		Font = Enum.Font.Gotham,
		TextSize = 9,
		TextColor3 = theme.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Right,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -76, 0, 0),
		Size = UDim2.fromOffset(60, TITLE_HEIGHT),
		Parent = self.TitleBar,
	})
	self.TitleLine = DOM.Create("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, -1),
		BackgroundColor3 = theme.BorderDim,
		BorderSizePixel = 0,
		Parent = self.TitleBar,
	})
	self._theme:Bind(self.TitleBar, "BackgroundColor3", "Side")
	self._theme:Bind(self.TitleDot, "BackgroundColor3", "Accent")
	self._theme:Bind(self.TitleLabel, "TextColor3", "Text")
	self._theme:Bind(self.TitleTag, "TextColor3", "TextMuted")
	self._theme:Bind(self.TitleLine, "BackgroundColor3", "BorderDim")

	-- Dragging Logic
	self:_initDragging(self.TitleBar, self.MainFrame)

	-- Tab Navigation Strip
	self.TabBar = DOM.Create("Frame", {
		Size = UDim2.new(1, 0, 0, TAB_HEIGHT),
		Position = UDim2.new(0, 0, 0, TITLE_HEIGHT),
		BackgroundColor3 = theme.Side,
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
		Size = UDim2.new(1, 0, 1, -TITLE_HEIGHT - TAB_HEIGHT),
		Position = UDim2.new(0, 0, 0, TITLE_HEIGHT + TAB_HEIGHT),
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

	-- Repaint tab states whenever the active theme preset changes
	local themeSignal = self._theme.OnThemeUpdated
	if themeSignal and type(themeSignal.Connect) == "function" then
		themeSignal:Connect(function()
			self:_paintTabs()
		end)
	end

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
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = self._theme.Current.Accent,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Visible = false,
			Parent = self.Content,
		}, {
			DOM.Create("UIListLayout", { Padding = UDim.new(0, 10) }),
			DOM.CreatePadding(14),
		}),
		Button = DOM.Create("TextButton", {
			Text = name,
			Font = Enum.Font.Gotham,
			TextSize = 11,
			TextColor3 = self._theme.Current.TextDim,
			BackgroundColor3 = self._theme.Current.ElemHover,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(80, 22),
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Parent = self.TabList,
		}, { DOM.CreateCorner(11) }),
	}

	tab.Button.MouseButton1Click:Connect(function()
		self:SelectTab(tab)
	end)
	tab.Button.MouseEnter:Connect(function()
		if tab ~= self._activeTab then
			tab.Button.BackgroundTransparency = 0
			tab.Button.BackgroundColor3 = self._theme.Current.ElemHover
			tab.Button.TextColor3 = self._theme.Current.Text
		end
	end)
	tab.Button.MouseLeave:Connect(function()
		self:_paintTabs()
	end)

	-- Convenience forwarder so presenters can notify through the tab they own
	tab.Notify = function(_, title, message, duration, color)
		self:Notify(title, message, duration, color)
	end

	table.insert(self._tabs, tab)
	if #self._tabs == 1 then
		self:SelectTab(tab)
	end
	return tab
end

function Window:_paintTab(tab)
	local active = (tab == self._activeTab)
	if active then
		tab.Button.BackgroundTransparency = 0
		tab.Button.BackgroundColor3 = self._theme.Current.Accent
		tab.Button.TextColor3 = Color3.new(0, 0, 0)
	else
		tab.Button.BackgroundTransparency = 1
		tab.Button.TextColor3 = self._theme.Current.TextDim
	end
end

function Window:_paintTabs()
	for _, t in ipairs(self._tabs) do
		self:_paintTab(t)
	end
end

function Window:SelectTab(tab)
	for _, t in ipairs(self._tabs) do
		t.Page.Visible = false
	end
	tab.Page.Visible = true
	self._activeTab = tab
	self:_paintTabs()
end

function Window:Notify(title, message, duration, color)
	local accent = color or self._theme.Current.Accent
	local card = DOM.Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = self._theme.Current.Panel,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = self.NotifyContainer,
	}, {
		DOM.CreateCorner(10),
		DOM.CreateStroke(accent, 1),
	})

	-- Left accent tick
	DOM.Create("Frame", {
		Size = UDim2.new(0, 3, 1, -10),
		Position = UDim2.fromOffset(2, 5),
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
		Parent = card,
	})

	DOM.Create("TextLabel", {
		Text = title or "Notification",
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = self._theme.Current.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 8),
		Size = UDim2.new(1, -18, 0, 14),
		Parent = card,
	})

	DOM.Create("TextLabel", {
		Text = message or "",
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextColor3 = self._theme.Current.TextDim,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 24),
		Size = UDim2.new(1, -18, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = card,
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
