local SETTINGS = {
	GEOMETRY = {
		DEFAULT_W = 660,
		DEFAULT_H = 460,
		TITLE_H = 28,
		TAB_H = 26,
		COL_GAP = 8,
		PAD = 8,
		ROW_HEIGHT = 22,
		DROPDOWN_ROW_H = 22,
		DROPDOWN_MAX_ROWS = 6,
		NOTIFY_DEFAULT_T = 3.5,
	},
	PRESETS = {
		COLORS = {
			WHITE = Color3.fromRGB(255, 255, 255),
			BLACK = Color3.fromRGB(0, 0, 0),
			RED = Color3.fromRGB(255, 50, 50),
			ORANGE = Color3.fromRGB(255, 150, 50),
			YELLOW = Color3.fromRGB(255, 230, 50),
			GREEN = Color3.fromRGB(50, 255, 80),
			CYAN = Color3.fromRGB(0, 200, 220),
			BLUE = Color3.fromRGB(80, 80, 255),
			PURPLE = Color3.fromRGB(200, 80, 255),
			PINK = Color3.fromRGB(255, 80, 180),
		},
	},
	MOUSE_MAP = {
		[Enum.UserInputType.MouseButton1] = "MB1",
		[Enum.UserInputType.MouseButton2] = "MB2",
		[Enum.UserInputType.MouseButton3] = "MB3",
	},
	DISPLAY_ORDERS = {
		AUTH = 10000,
		MAIN = 999,
	},
	LIMITS = {
		MIN_GEOM_SIZE = 1e-6,
	},
}

return function(Context, Theme)
	local UserInputService = game:GetService("UserInputService")
	local CoreGui = game:GetService("CoreGui")
	local Players = game:GetService("Players")

	local LocalPlayer = Players.LocalPlayer
	local CONFIG = (Context and Context.CONFIG) or {}
	local State = (Context and Context.State) or {}
	local Utils = (Context and Context.Utils) or {}
	local Connections = (Context and Context.Connections) or {}
	local ThemeManager = Context and Context.ThemeManager

	local UI_W = CONFIG.UI_W or SETTINGS.GEOMETRY.DEFAULT_W
	local UI_H = CONFIG.UI_H or SETTINGS.GEOMETRY.DEFAULT_H
	local TITLE_H = SETTINGS.GEOMETRY.TITLE_H
	local TAB_H = SETTINGS.GEOMETRY.TAB_H
	local COL_GAP = SETTINGS.GEOMETRY.COL_GAP
	local PAD = SETTINGS.GEOMETRY.PAD

	local activeDragCallback = nil

	local function createInstance(className, properties, children)
		local instance = Instance.new(className)
		if properties then
			for k, v in pairs(properties) do
				pcall(function() instance[k] = v end)
			end
		end
		if children then
			for _, child in ipairs(children) do
				child.Parent = instance
			end
		end
		return instance
	end

	local function createStroke(color, thickness)
		return createInstance("UIStroke", {
			Color = color or Theme.Border,
			Thickness = thickness or 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		})
	end

	local function createPadding(top, bottom, left, right)
		if bottom == nil then
			return createInstance("UIPadding", {
				PaddingTop = UDim.new(0, top),
				PaddingBottom = UDim.new(0, top),
				PaddingLeft = UDim.new(0, top),
				PaddingRight = UDim.new(0, top),
			})
		end
		return createInstance("UIPadding", {
			PaddingTop = UDim.new(0, top or 0),
			PaddingBottom = UDim.new(0, bottom or 0),
			PaddingLeft = UDim.new(0, left or 0),
			PaddingRight = UDim.new(0, right or 0),
		})
	end

	if Connections and Connections.Add then
		Connections.Add(UserInputService.InputChanged:Connect(function(input)
			if activeDragCallback and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				activeDragCallback(input.Position.X)
			end
		end))
		Connections.Add(UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				activeDragCallback = nil
			end
		end))
	end

	local UI = {}
	UI.__index = UI

	function UI.CreateKeyPrompt(_, KeySystem, CurrentTheme, onSuccess, initialError)
		local theme = CurrentTheme or Theme
		local parent = nil

		pcall(function()
			if gethui then parent = gethui() end
		end)
		if not parent then
			pcall(function() parent = CoreGui end)
		end
		if not parent and LocalPlayer then
			parent = LocalPlayer:WaitForChild("PlayerGui")
		end

		local gui = createInstance("ScreenGui", {
			Name = "B0XazAuth",
			DisplayOrder = SETTINGS.DISPLAY_ORDERS.AUTH,
			IgnoreGuiInset = true,
			ResetOnSpawn = false,
			Parent = parent,
		})

		local dim = createInstance("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.45,
			BorderSizePixel = 0,
			Parent = gui,
		})

		local modal = createInstance("Frame", {
			Size = UDim2.fromOffset(360, 230),
			Position = UDim2.new(0.5, -180, 0.5, -115),
			BackgroundColor3 = theme.Bg or Color3.fromRGB(18, 18, 20),
			BorderSizePixel = 0,
			Parent = dim,
		}, {
			createStroke(theme.Border or Color3.fromRGB(60, 60, 70), 1),
		})

		createInstance("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -20, 0, 28),
			Position = UDim2.fromOffset(10, 12),
			Font = Enum.Font.Code,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = theme.Text or Color3.fromRGB(230, 230, 230),
			Text = "Authentication Required",
			Parent = modal,
		})

		local errorLabel = createInstance("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -20, 0, 36),
			Position = UDim2.fromOffset(10, 44),
			Font = Enum.Font.Code,
			TextSize = 11,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = (initialError and initialError ~= "" and (theme.Danger or Color3.fromRGB(220, 80, 80))) or (theme.TextDim or Color3.fromRGB(160, 160, 170)),
			Text = (initialError and initialError ~= "" and initialError) or "Enter your access key to continue.",
			Parent = modal,
		})

		local boxBg = createInstance("Frame", {
			Size = UDim2.new(1, -20, 0, 32),
			Position = UDim2.fromOffset(10, 90),
			BackgroundColor3 = theme.Panel or Color3.fromRGB(28, 28, 32),
			BorderSizePixel = 0,
			Parent = modal,
		}, {
			createStroke(theme.Border or Color3.fromRGB(60, 60, 70), 1),
		})

		local box = createInstance("TextBox", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -12, 1, 0),
			Position = UDim2.fromOffset(6, 0),
			Font = Enum.Font.Code,
			TextSize = 12,
			Text = "",
			PlaceholderText = "Paste access key here...",
			TextColor3 = theme.Text or Color3.fromRGB(230, 230, 230),
			PlaceholderColor3 = theme.TextMuted or Color3.fromRGB(100, 100, 110),
			ClearTextOnFocus = false,
			Parent = boxBg,
		})

		local authenticateBtn = createInstance("TextButton", {
			Size = UDim2.fromOffset(150, 34),
			Position = UDim2.new(0.5, -75, 0, 138),
			BackgroundColor3 = theme.Accent or Color3.fromRGB(0, 200, 220),
			Text = "Authenticate",
			Font = Enum.Font.Code,
			TextSize = 12,
			TextColor3 = Color3.new(0, 0, 0),
			AutoButtonColor = true,
			BorderSizePixel = 0,
			Parent = modal,
		})

		local getKeyBtn = createInstance("TextButton", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -20, 0, 20),
			Position = UDim2.new(0, 10, 1, -28),
			Text = "Get Key Info",
			Font = Enum.Font.Code,
			TextSize = 10,
			TextColor3 = theme.TextDim or Color3.fromRGB(150, 150, 160),
			Parent = modal,
		})

		getKeyBtn.MouseButton1Click:Connect(function()
			local copied, msg = false, "No Link"
			if KeySystem and KeySystem.CopyGetKeyLink then
				copied, msg = KeySystem.CopyGetKeyLink()
			end
			errorLabel.Text = msg or (copied and "Information copied." or "Failed to copy info.")
			errorLabel.TextColor3 = copied and (theme.Success or theme.Accent or Color3.fromRGB(90, 200, 120)) or (theme.Danger or Color3.fromRGB(220, 80, 80))
		end)

		local function submit()
			authenticateBtn.Text = "Checking..."
			task.wait(0.05)
			local success, _, msg = KeySystem.ApplyKey(box.Text)
			if success then
				gui:Destroy()
				if onSuccess then
					task.spawn(onSuccess)
				end
			else
				authenticateBtn.Text = "Authenticate"
				errorLabel.Text = msg or "Invalid Key"
				errorLabel.TextColor3 = theme.Danger or Color3.fromRGB(220, 80, 80)
			end
		end

		authenticateBtn.MouseButton1Click:Connect(submit)
		box.FocusLost:Connect(function(enter)
			if enter then submit() end
		end)
	end

	function UI.new(title)
		local self = setmetatable({}, UI)
		self.Tabs = {}
		self.ActiveTab = nil
		self._openDropdowns = {}
		self._themeBindings = {}
		self.Title = title or "B0Xaz"

		self.ScreenGui = createInstance("ScreenGui", {
			Name = "B0XazUI",
			ResetOnSpawn = false,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			IgnoreGuiInset = true,
			DisplayOrder = SETTINGS.DISPLAY_ORDERS.MAIN,
		})

		local parented = false
		pcall(function()
			if gethui then
				self.ScreenGui.Parent = gethui()
				parented = true
			end
		end)
		if not parented then
			pcall(function()
				self.ScreenGui.Parent = CoreGui
				parented = true
			end)
		end
		if not parented and LocalPlayer then
			self.ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
		end

		self.Main = createInstance("Frame", {
			Size = UDim2.new(0, UI_W, 0, UI_H),
			Position = UDim2.new(0.5, -UI_W / 2, 0.5, -UI_H / 2),
			BackgroundColor3 = Theme.Bg,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			Parent = self.ScreenGui,
		})
		local mainStroke = createStroke(Theme.Border, 1)
		mainStroke.Parent = self.Main
		self:BindTheme(self.Main, "BackgroundColor3", "Bg")
		self:BindTheme(mainStroke, "Color", "Border")

		self.TitleBar = createInstance("Frame", {
			Size = UDim2.new(1, 0, 0, TITLE_H),
			BackgroundColor3 = Theme.Side,
			BorderSizePixel = 0,
			Parent = self.Main,
		})
		self:BindTheme(self.TitleBar, "BackgroundColor3", "Side")

		local titleLine = createInstance("Frame", {
			Size = UDim2.new(1, 0, 0, 1),
			Position = UDim2.new(0, 0, 1, -1),
			BackgroundColor3 = Theme.Border,
			BorderSizePixel = 0,
			Parent = self.TitleBar,
		})
		self:BindTheme(titleLine, "BackgroundColor3", "Border")

		local titleLabel = createInstance("TextLabel", {
			Text = self.Title,
			Font = Enum.Font.Code,
			TextSize = 13,
			TextColor3 = Theme.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 10, 0, 0),
			Size = UDim2.new(1, -40, 1, 0),
			Parent = self.TitleBar,
		})
		self:BindTheme(titleLabel, "TextColor3", "Text")

		local closeBtn = createInstance("TextButton", {
			Text = "x",
			Font = Enum.Font.Code,
			TextSize = 14,
			TextColor3 = Theme.TextDim,
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 28, 1, 0),
			Position = UDim2.new(1, -28, 0, 0),
			AutoButtonColor = false,
			Parent = self.TitleBar,
		})
		self:BindTheme(closeBtn, "TextColor3", "TextDim")
		closeBtn.MouseEnter:Connect(function()
			closeBtn.TextColor3 = Theme.Danger
		end)
		closeBtn.MouseLeave:Connect(function()
			closeBtn.TextColor3 = Theme.TextDim
		end)
		closeBtn.MouseButton1Click:Connect(function()
			self.Main.Visible = false
			State.MenuVisible = false
		end)

		self.TabBar = createInstance("Frame", {
			Size = UDim2.new(1, 0, 0, TAB_H),
			Position = UDim2.new(0, 0, 0, TITLE_H),
			BackgroundColor3 = Theme.Side,
			BorderSizePixel = 0,
			Parent = self.Main,
		})
		self:BindTheme(self.TabBar, "BackgroundColor3", "Side")

		local tabLine = createInstance("Frame", {
			Size = UDim2.new(1, 0, 0, 1),
			Position = UDim2.new(0, 0, 1, -1),
			BackgroundColor3 = Theme.BorderDim,
			BorderSizePixel = 0,
			Parent = self.TabBar,
		})
		self:BindTheme(tabLine, "BackgroundColor3", "BorderDim")

		self.TabList = createInstance("ScrollingFrame", {
			Size = UDim2.new(1, -8, 1, 0),
			Position = UDim2.new(0, 4, 0, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 0,
			ScrollingDirection = Enum.ScrollingDirection.X,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.X,
			ClipsDescendants = true,
			Parent = self.TabBar,
		}, {
			createInstance("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 4),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
		})

		self.Content = createInstance("Frame", {
			Size = UDim2.new(1, 0, 1, -(TITLE_H + TAB_H)),
			Position = UDim2.new(0, 0, 0, TITLE_H + TAB_H),
			BackgroundTransparency = 1,
			Parent = self.Main,
		})
		self.PagesContainer = createInstance("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Parent = self.Content,
		})

		do
			local dragging, dragStart, startPos = false, nil, nil
			self.TitleBar.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = true
					dragStart = input.Position
					startPos = self.Main.Position
				end
			end)
			self.TitleBar.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = false
				end
			end)
			if Connections and Connections.Add then
				Connections.Add(UserInputService.InputChanged:Connect(function(input)
					if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
						local delta = input.Position - dragStart
						self.Main.Position = UDim2.new(
							startPos.X.Scale,
							startPos.X.Offset + delta.X,
							startPos.Y.Scale,
							startPos.Y.Offset + delta.Y
						)
					end
				end))
			end
		end

		self.NotifyContainer = createInstance("Frame", {
			Size = UDim2.new(0, 300, 1, -20),
			Position = UDim2.new(1, -310, 0, 10),
			BackgroundTransparency = 1,
			Parent = self.ScreenGui,
		}, {
			createInstance("UIListLayout", {
				Padding = UDim.new(0, 6),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Bottom,
			}),
		})

		return self
	end

	function UI:BindTheme(instance, property, themeKey)
		table.insert(self._themeBindings, {
			Instance = instance,
			Property = property,
			Key = themeKey,
		})
		if Theme[themeKey] then
			pcall(function() instance[property] = Theme[themeKey] end)
		end
	end

	function UI:SetTheme(newTheme)
		for k, v in pairs(newTheme) do Theme[k] = v end
		if newTheme.Accent and ThemeManager and ThemeManager.DeriveAccentTones then
			local tones = ThemeManager.DeriveAccentTones(newTheme.Accent)
			Theme.AccentDark = newTheme.AccentDark or tones.AccentDark
			Theme.AccentDim = newTheme.AccentDim or tones.AccentDim
		end
		for _, binding in ipairs(self._themeBindings) do
			if binding.Instance and binding.Instance.Parent then
				local val = Theme[binding.Key]
				if val then
					pcall(function() binding.Instance[binding.Property] = val end)
				end
			end
		end
		if self.ActiveTab then
			self:SelectTab(self.ActiveTab)
		end
	end

	function UI:UpdateThemeKey(key, color)
		Theme[key] = color
		if key == "Accent" and ThemeManager and ThemeManager.DeriveAccentTones then
			local tones = ThemeManager.DeriveAccentTones(color)
			Theme.AccentDark = tones.AccentDark
			Theme.AccentDim = tones.AccentDim
		end
		for _, binding in ipairs(self._themeBindings) do
			if binding.Instance and binding.Instance.Parent and (binding.Key == key or (key == "Accent" and (binding.Key == "AccentDark" or binding.Key == "AccentDim"))) then
				local val = Theme[binding.Key]
				if val then
					pcall(function() binding.Instance[binding.Property] = val end)
				end
			end
		end
		if self.ActiveTab then
			self:SelectTab(self.ActiveTab)
		end
	end

	function UI:Destroy()
		pcall(function()
			if self.ScreenGui then self.ScreenGui:Destroy() end
		end)
	end

	function UI:RegisterDropdown(closeFn)
		table.insert(self._openDropdowns, closeFn)
	end

	function UI:CloseAllDropdownsExcept(exceptFn)
		for _, fn in ipairs(self._openDropdowns) do
			if fn ~= exceptFn then
				pcall(fn, false)
			end
		end
	end

	function UI:Notify(title, text, duration, color)
		local accent = color or Theme.Accent
		local notif = createInstance("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = Theme.Panel,
			BorderSizePixel = 0,
			Parent = self.NotifyContainer,
		}, {
			createStroke(accent, 1),
			createPadding(6, 6, 8, 8),
			createInstance("UIListLayout", {
				Padding = UDim.new(0, 3),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			createInstance("TextLabel", {
				Text = title or "Notification",
				Font = Enum.Font.Code,
				TextSize = 12,
				TextColor3 = Theme.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 14),
				LayoutOrder = 1,
			}),
			createInstance("TextLabel", {
				Text = text or "",
				Font = Enum.Font.Code,
				TextSize = 11,
				TextColor3 = Theme.TextDim,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextWrapped = true,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = 2,
			}),
		})
		task.delay(duration or (CONFIG.NOTIFY_DEFAULT_TIME or SETTINGS.GEOMETRY.NOTIFY_DEFAULT_T), function()
			if notif and notif.Parent then
				pcall(function() notif:Destroy() end)
			end
		end)
	end

	function UI:SelectTab(tab)
		for _, t in ipairs(self.Tabs) do
			t.Page.Visible = false
			t.Button.TextColor3 = Theme.TextDim
			if t.Underline then t.Underline.Visible = false end
		end
		tab.Page.Visible = true
		tab.Button.TextColor3 = Theme.Text
		if tab.Underline then
			tab.Underline.BackgroundColor3 = Theme.Accent
			tab.Underline.Visible = true
		end
		self.ActiveTab = tab
		self:CloseAllDropdownsExcept(nil)
	end

	local function createDummyTab()
		local d = {}
		function d:AddSection()
			local s = {}
			function s:AddToggle(_, def)
				return {
					Set = function() end,
					Get = function() return def end,
					UpdateTheme = function() end,
				}
			end
			function s:AddSlider(_, def)
				return {
					Set = function() end,
					Get = function() return def end,
				}
			end
			function s:AddButton() end
			function s:AddDropdown(_, _, _, def)
				return {
					Set = function() end,
					Get = function() return def end,
					Refresh = function() end,
					Close = function() end,
				}
			end
			function s:AddTextbox(_, def)
				return {
					Set = function() end,
					Get = function() return def end,
				}
			end
			function s:AddColorPicker(_, def)
				return {
					Set = function() end,
					Get = function() return def or Color3.new() end,
				}
			end
			function s:AddKeybind(_, def)
				return {
					Set = function() end,
					Get = function() return def end,
				}
			end
			return s
		end
		return d
	end

	function UI:AddTab(name, reqTier)
		reqTier = reqTier or 1
		local currentT = (Context.KeySystem and Context.KeySystem.CurrentTier) or 0
		if reqTier > currentT then
			return createDummyTab()
		end

		local ui = self
		local tab = { Name = name, Sections = {}, UI = ui, _col = 0 }

		tab.Button = createInstance("TextButton", {
			Text = name,
			Font = Enum.Font.Code,
			TextSize = 12,
			TextColor3 = Theme.TextDim,
			BackgroundTransparency = 1,
			Size = UDim2.new(0, math.max(52, #name * 7 + 16), 1, 0),
			AutoButtonColor = false,
			Parent = self.TabList,
		})
		ui:BindTheme(tab.Button, "TextColor3", "TextDim")

		tab.Underline = createInstance("Frame", {
			Size = UDim2.new(1, -8, 0, 2),
			Position = UDim2.new(0, 4, 1, -2),
			BackgroundColor3 = Theme.Accent,
			BorderSizePixel = 0,
			Visible = false,
			Parent = tab.Button,
		})
		ui:BindTheme(tab.Underline, "BackgroundColor3", "Accent")

		tab.Page = createInstance("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Visible = false,
			Parent = self.PagesContainer,
		})

		local colPad, gap, scrollBarW = PAD, COL_GAP, 3

		tab.LeftCol = createInstance("ScrollingFrame", {
			Name = "LeftCol",
			Size = UDim2.new(0.5, -(colPad + gap / 2), 1, -colPad * 2),
			Position = UDim2.new(0, colPad, 0, colPad),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = scrollBarW,
			ScrollBarImageColor3 = Theme.AccentDark,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ClipsDescendants = true,
			Parent = tab.Page,
		}, {
			createInstance("UIListLayout", {
				Padding = UDim.new(0, gap),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			createPadding(0, 4, 0, scrollBarW + 2),
		})
		ui:BindTheme(tab.LeftCol, "ScrollBarImageColor3", "AccentDark")

		tab.RightCol = createInstance("ScrollingFrame", {
			Name = "RightCol",
			Size = UDim2.new(0.5, -(colPad + gap / 2), 1, -colPad * 2),
			Position = UDim2.new(0.5, gap / 2, 0, colPad),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = scrollBarW,
			ScrollBarImageColor3 = Theme.AccentDark,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ClipsDescendants = true,
			Parent = tab.Page,
		}, {
			createInstance("UIListLayout", {
				Padding = UDim.new(0, gap),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			createPadding(0, 4, 0, scrollBarW + 2),
		})
		ui:BindTheme(tab.RightCol, "ScrollBarImageColor3", "AccentDark")

		tab.Button.MouseEnter:Connect(function()
			if ui.ActiveTab ~= tab then tab.Button.TextColor3 = Theme.Text end
		end)
		tab.Button.MouseLeave:Connect(function()
			if ui.ActiveTab ~= tab then tab.Button.TextColor3 = Theme.TextDim end
		end)
		tab.Button.MouseButton1Click:Connect(function() ui:SelectTab(tab) end)

		table.insert(self.Tabs, tab)
		if not self.ActiveTab then self:SelectTab(tab) end

		function tab:AddSection(secName)
			local section = { Name = secName, Elements = {}, Tab = tab }
			tab._col = (tab._col % 2) + 1
			local parentCol = (tab._col == 1) and tab.LeftCol or tab.RightCol

			section.Frame = createInstance("Frame", {
				BackgroundColor3 = Theme.Panel,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BorderSizePixel = 0,
				Parent = parentCol,
			}, {
				createInstance("UIListLayout", {
					Padding = UDim.new(0, 0),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
			})
			local secStroke = createStroke(Theme.Border, 1)
			secStroke.Parent = section.Frame
			ui:BindTheme(section.Frame, "BackgroundColor3", "Panel")
			ui:BindTheme(secStroke, "Color", "Border")

			local titleBar = createInstance("Frame", {
				Size = UDim2.new(1, 0, 0, 20),
				BackgroundColor3 = Theme.Side,
				BorderSizePixel = 0,
				LayoutOrder = 0,
				Parent = section.Frame,
			})
			ui:BindTheme(titleBar, "BackgroundColor3", "Side")

			local secLine = createInstance("Frame", {
				Size = UDim2.new(1, 0, 0, 1),
				Position = UDim2.new(0, 0, 1, -1),
				BackgroundColor3 = Theme.Accent,
				BorderSizePixel = 0,
				Parent = titleBar,
			})
			ui:BindTheme(secLine, "BackgroundColor3", "Accent")

			local secLabel = createInstance("TextLabel", {
				Text = "  " .. secName,
				Font = Enum.Font.Code,
				TextSize = 11,
				TextColor3 = Theme.TextDim,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				Parent = titleBar,
			})
			ui:BindTheme(secLabel, "TextColor3", "TextDim")

			local body = createInstance("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = 1,
				Parent = section.Frame,
			}, {
				createInstance("UIListLayout", {
					Padding = UDim.new(0, 2),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				createPadding(4, 6, 6, 6),
			})

			table.insert(tab.Sections, section)
			local rowOrder = 0

			local function newRow(elemName, h)
				rowOrder = rowOrder + 1
				local row = createInstance("Frame", {
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					LayoutOrder = rowOrder,
					Parent = body,
				}, {
					createInstance("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }),
				})
				local rowContent = createInstance("Frame", {
					Size = UDim2.new(1, 0, 0, h),
					BackgroundTransparency = 1,
					LayoutOrder = 1,
					Parent = row,
				})
				table.insert(section.Elements, { Container = row, Name = elemName })
				return row, rowContent
			end

			local function triggerAutosave()
				if Context.ConfigSystem and Context.ConfigSystem.NotifyChange then
					pcall(Context.ConfigSystem.NotifyChange)
				end
			end

			local function isLocked(rTier)
				return rTier and rTier > ((Context.KeySystem and Context.KeySystem.CurrentTier) or 0)
			end

			function section:AddToggle(name, default, callback, rTier)
				if isLocked(rTier) then
					return {
						Set = function() end,
						Get = function() return default end,
						UpdateTheme = function() end,
					}
				end
				local _, rowContent = newRow(name, SETTINGS.GEOMETRY.ROW_HEIGHT)
				local state = default and true or false
				local box = createInstance("Frame", {
					Size = UDim2.new(0, 12, 0, 12),
					Position = UDim2.new(0, 2, 0.5, -6),
					BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff,
					BorderSizePixel = 0,
					Parent = rowContent,
				})
				local boxStroke = createStroke(Theme.Border, 1)
				boxStroke.Parent = box
				ui:BindTheme(boxStroke, "Color", "Border")

				local lbl = createInstance("TextLabel", {
					Text = name,
					Font = Enum.Font.Code,
					TextSize = 11,
					TextColor3 = Theme.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 20, 0, 0),
					Size = UDim2.new(1, -24, 1, 0),
					Parent = rowContent,
				})
				ui:BindTheme(lbl, "TextColor3", "Text")

				local btn = createInstance("TextButton", {
					Text = "",
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 1, 0),
					Parent = rowContent,
				})

				local function setState(v, silent)
					state = v and true or false
					box.BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff
					if not silent and callback then
						Utils.SafeCall(callback, state)
					end
					if not silent then triggerAutosave() end
				end
				btn.MouseButton1Click:Connect(function() setState(not state) end)

				return {
					Set = setState,
					Get = function() return state end,
					UpdateTheme = function()
						box.BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff
					end,
				}
			end

			function section:AddSlider(name, default, min, max, callback, suffix, rTier)
				if isLocked(rTier) then
					return {
						Set = function() end,
						Get = function() return default end,
					}
				end
				local _, rowContent = newRow(name, 36)
				suffix = suffix or ""

				local lbl = createInstance("TextLabel", {
					Text = name,
					Font = Enum.Font.Code,
					TextSize = 11,
					TextColor3 = Theme.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 2, 0, 0),
					Size = UDim2.new(1, -50, 0, 14),
					Parent = rowContent,
				})
				ui:BindTheme(lbl, "TextColor3", "Text")

				local valLabel = createInstance("TextLabel", {
					Text = tostring(default) .. "/" .. tostring(max) .. suffix,
					Font = Enum.Font.Code,
					TextSize = 10,
					TextColor3 = Theme.TextDim,
					TextXAlignment = Enum.TextXAlignment.Right,
					BackgroundTransparency = 1,
					Position = UDim2.new(1, -48, 0, 0),
					Size = UDim2.new(0, 46, 0, 14),
					Parent = rowContent,
				})
				ui:BindTheme(valLabel, "TextColor3", "TextDim")

				local track = createInstance("Frame", {
					Size = UDim2.new(1, -4, 0, 4),
					Position = UDim2.new(0, 2, 0, 22),
					BackgroundColor3 = Theme.Elem,
					BorderSizePixel = 0,
					Parent = rowContent,
				})
				local trackStroke = createStroke(Theme.BorderDim, 1)
				trackStroke.Parent = track
				ui:BindTheme(track, "BackgroundColor3", "Elem")
				ui:BindTheme(trackStroke, "Color", "BorderDim")

				local initRel = math.clamp((default - min) / math.max(max - min, SETTINGS.LIMITS.MIN_GEOM_SIZE), 0, 1)
				local fill = createInstance("Frame", {
					Size = UDim2.new(initRel, 0, 1, 0),
					BackgroundColor3 = Theme.Accent,
					BorderSizePixel = 0,
					Parent = track,
				})
				ui:BindTheme(fill, "BackgroundColor3", "Accent")

				local value = default
				local function commit(rel, silent)
					rel = math.clamp(rel, 0, 1)
					value = math.floor(min + (max - min) * rel + 0.5)
					fill.Size = UDim2.new(rel, 0, 1, 0)
					valLabel.Text = tostring(value) .. "/" .. tostring(max) .. suffix
					if not silent and callback then
						Utils.SafeCall(callback, value)
					end
					if not silent then triggerAutosave() end
				end
				local function updateFromX(x)
					commit((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1))
				end

				track.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						activeDragCallback = updateFromX
						updateFromX(input.Position.X)
					end
				end)
				local hit = createInstance("TextButton", {
					Text = "",
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 14),
					Position = UDim2.new(0, 0, 0, 16),
					Parent = rowContent,
				})
				hit.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						activeDragCallback = updateFromX
						updateFromX(input.Position.X)
					end
				end)

				return {
					Set = function(v, silent)
						local val = math.clamp(v, min, max)
						commit((val - min) / math.max(max - min, SETTINGS.LIMITS.MIN_GEOM_SIZE), silent)
					end,
					Get = function() return value end,
				}
			end

			function section:AddButton(name, callback, rTier)
				if isLocked(rTier) then return nil end
				local _, rowContent = newRow(name, 24)
				local btn = createInstance("TextButton", {
					Text = name,
					Font = Enum.Font.Code,
					TextSize = 11,
					TextColor3 = Theme.Text,
					BackgroundColor3 = Theme.Elem,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 0, 20),
					Position = UDim2.new(0, 0, 0, 2),
					AutoButtonColor = false,
					Parent = rowContent,
				})
				local btnStroke = createStroke(Theme.Border, 1)
				btnStroke.Parent = btn
				ui:BindTheme(btn, "BackgroundColor3", "Elem")
				ui:BindTheme(btn, "TextColor3", "Text")
				ui:BindTheme(btnStroke, "Color", "Border")
				btn.MouseEnter:Connect(function()
					btn.BackgroundColor3 = Theme.ElemHover
					btn.TextColor3 = Theme.Accent
				end)
				btn.MouseLeave:Connect(function()
					btn.BackgroundColor3 = Theme.Elem
					btn.TextColor3 = Theme.Text
				end)
				btn.MouseButton1Click:Connect(function()
					if callback then Utils.SafeCall(callback) end
				end)
				return btn
			end

			function section:AddDropdown(name, options, callback, default, rTier)
				if isLocked(rTier) then
					return {
						Set = function() end,
						Get = function() return default end,
						Refresh = function() end,
						Close = function() end,
					}
				end
				local row, rowContent = newRow(name, 40)
				local lbl = createInstance("TextLabel", {
					Text = name,
					Font = Enum.Font.Code,
					TextSize = 11,
					TextColor3 = Theme.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 2, 0, 0),
					Size = UDim2.new(1, -4, 0, 14),
					Parent = rowContent,
				})
				ui:BindTheme(lbl, "TextColor3", "Text")

				local currentOptions = table.clone(options or {})
				local selected = default or currentOptions[1] or ""
				local displayBtn = createInstance("TextButton", {
					Text = (selected ~= "" and tostring(selected) or "None") .. "  v",
					Font = Enum.Font.Code,
					TextSize = 11,
					TextColor3 = Theme.TextDim,
					BackgroundColor3 = Theme.Elem,
					BorderSizePixel = 0,
					Size = UDim2.new(1, -4, 0, 18),
					Position = UDim2.new(0, 2, 0, 16),
					AutoButtonColor = false,
					Parent = rowContent,
				})
				local dispStroke = createStroke(Theme.Border, 1)
				dispStroke.Parent = displayBtn
				ui:BindTheme(displayBtn, "BackgroundColor3", "Elem")
				ui:BindTheme(displayBtn, "TextColor3", "TextDim")
				ui:BindTheme(dispStroke, "Color", "Border")

				local expansion = createInstance("Frame", {
					Size = UDim2.new(1, 0, 0, 0),
					BackgroundTransparency = 1,
					LayoutOrder = 2,
					Visible = false,
					Parent = row,
				})
				local listBox = createInstance("ScrollingFrame", {
					Size = UDim2.new(1, -4, 1, 0),
					Position = UDim2.new(0, 2, 0, 0),
					BackgroundColor3 = Theme.Elem,
					BorderSizePixel = 0,
					CanvasSize = UDim2.new(0, 0, 0, 0),
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					ScrollBarThickness = 2,
					ScrollBarImageColor3 = Theme.AccentDark,
					Parent = expansion,
				}, {
					createInstance("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }),
				})
				local listStroke = createStroke(Theme.Border, 1)
				listStroke.Parent = listBox
				ui:BindTheme(listBox, "BackgroundColor3", "Elem")
				ui:BindTheme(listBox, "ScrollBarImageColor3", "AccentDark")
				ui:BindTheme(listStroke, "Color", "Border")

				local isOpen = false
				local function setOpen(open)
					isOpen = open
					if open then
						local count = #currentOptions
						local rowH = CONFIG.DROPDOWN_ROW_HEIGHT or SETTINGS.GEOMETRY.DROPDOWN_ROW_H
						local maxRows = CONFIG.DROPDOWN_MAX_ROWS or SETTINGS.GEOMETRY.DROPDOWN_MAX_ROWS
						local h = math.min(count, maxRows) * rowH + 4
						expansion.Size = UDim2.new(1, 0, 0, math.max(h, 24))
						expansion.Visible = true
					else
						expansion.Visible = false
						expansion.Size = UDim2.new(1, 0, 0, 0)
					end
				end
				ui:RegisterDropdown(setOpen)

				local function rebuildOptions()
					for _, child in ipairs(listBox:GetChildren()) do
						if child:IsA("TextButton") then child:Destroy() end
					end
					local opts = #currentOptions > 0 and currentOptions or { "None" }
					for _, opt in ipairs(opts) do
						local optBtn = createInstance("TextButton", {
							Text = "  " .. tostring(opt),
							Font = Enum.Font.Code,
							TextSize = 11,
							TextColor3 = Theme.Text,
							TextXAlignment = Enum.TextXAlignment.Left,
							BackgroundTransparency = 1,
							Size = UDim2.new(1, 0, 0, CONFIG.DROPDOWN_ROW_HEIGHT or SETTINGS.GEOMETRY.DROPDOWN_ROW_H),
							AutoButtonColor = false,
							Parent = listBox,
						})
						ui:BindTheme(optBtn, "TextColor3", "Text")
						optBtn.MouseEnter:Connect(function()
							optBtn.BackgroundTransparency = 0
							optBtn.BackgroundColor3 = Theme.ElemHover
						end)
						optBtn.MouseLeave:Connect(function()
							optBtn.BackgroundTransparency = 1
						end)
						optBtn.MouseButton1Click:Connect(function()
							if opt ~= "None" or #currentOptions > 0 then
								selected = opt
								displayBtn.Text = tostring(opt) .. "  v"
								setOpen(false)
								if callback then Utils.SafeCall(callback, opt) end
								triggerAutosave()
							end
						end)
					end
				end
				rebuildOptions()

				displayBtn.MouseButton1Click:Connect(function()
					ui:CloseAllDropdownsExcept(setOpen)
					setOpen(not isOpen)
				end)

				return {
					Set = function(v, silent)
						selected = v
						displayBtn.Text = tostring(v) .. "  v"
						if not silent and callback then Utils.SafeCall(callback, v) end
						if not silent then triggerAutosave() end
					end,
					Get = function() return selected end,
					Refresh = function(newOpts, preserve)
						currentOptions = table.clone(newOpts or {})
						if not preserve or not table.find(currentOptions, selected) then
							selected = currentOptions[1] or ""
							displayBtn.Text = (selected ~= "" and tostring(selected) or "None") .. "  v"
						end
						rebuildOptions()
					end,
					Close = function() setOpen(false) end,
				}
			end

			function section:AddTextbox(name, default, callback, placeholder, rTier)
				if isLocked(rTier) then
					return {
						Set = function() end,
						Get = function() return default end,
					}
				end
				local _, rowContent = newRow(name, 40)
				local lbl = createInstance("TextLabel", {
					Text = name,
					Font = Enum.Font.Code,
					TextSize = 11,
					TextColor3 = Theme.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 2, 0, 0),
					Size = UDim2.new(1, -4, 0, 14),
					Parent = rowContent,
				})
				ui:BindTheme(lbl, "TextColor3", "Text")

				local boxFrame = createInstance("Frame", {
					Size = UDim2.new(1, -4, 0, 18),
					Position = UDim2.new(0, 2, 0, 16),
					BackgroundColor3 = Theme.Elem,
					BorderSizePixel = 0,
					Parent = rowContent,
				})
				local boxStroke = createStroke(Theme.Border, 1)
				boxStroke.Parent = boxFrame
				ui:BindTheme(boxFrame, "BackgroundColor3", "Elem")
				ui:BindTheme(boxStroke, "Color", "Border")

				local box = createInstance("TextBox", {
					Text = default or "",
					PlaceholderText = placeholder or "",
					Font = Enum.Font.Code,
					TextSize = 11,
					TextColor3 = Theme.Text,
					PlaceholderColor3 = Theme.TextMuted,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -8, 1, 0),
					Position = UDim2.new(0, 4, 0, 0),
					ClearTextOnFocus = false,
					Parent = boxFrame,
				})
				ui:BindTheme(box, "TextColor3", "Text")
				ui:BindTheme(box, "PlaceholderColor3", "TextMuted")

				box.FocusLost:Connect(function(enter)
					if callback then Utils.SafeCall(callback, box.Text, enter) end
					triggerAutosave()
				end)

				return {
					Set = function(v) box.Text = tostring(v or "") end,
					Get = function() return box.Text end,
				}
			end

			function section:AddColorPicker(name, default, callback, rTier)
				if isLocked(rTier) then
					return {
						Set = function() end,
						Get = function() return default or Color3.new() end,
					}
				end
				local row, rowContent = newRow(name, 22)
				local lbl = createInstance("TextLabel", {
					Text = name,
					Font = Enum.Font.Code,
					TextSize = 11,
					TextColor3 = Theme.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 2, 0, 0),
					Size = UDim2.new(1, -30, 1, 0),
					Parent = rowContent,
				})
				ui:BindTheme(lbl, "TextColor3", "Text")

				local currentColor = default or Color3.new(1, 1, 1)
				local swatch = createInstance("TextButton", {
					Text = "",
					Size = UDim2.new(0, 16, 0, 12),
					Position = UDim2.new(1, -20, 0.5, -6),
					BackgroundColor3 = currentColor,
					BorderSizePixel = 0,
					AutoButtonColor = false,
					Parent = rowContent,
				})
				local swatchStroke = createStroke(Theme.Border, 1)
				swatchStroke.Parent = swatch
				ui:BindTheme(swatchStroke, "Color", "Border")

				local presets = {
					SETTINGS.PRESETS.COLORS.WHITE,
					SETTINGS.PRESETS.COLORS.BLACK,
					SETTINGS.PRESETS.COLORS.RED,
					SETTINGS.PRESETS.COLORS.ORANGE,
					SETTINGS.PRESETS.COLORS.YELLOW,
					SETTINGS.PRESETS.COLORS.GREEN,
					SETTINGS.PRESETS.COLORS.CYAN,
					SETTINGS.PRESETS.COLORS.BLUE,
					SETTINGS.PRESETS.COLORS.PURPLE,
					SETTINGS.PRESETS.COLORS.PINK,
				}
				local expansion = createInstance("Frame", {
					Size = UDim2.new(1, 0, 0, 0),
					BackgroundTransparency = 1,
					LayoutOrder = 2,
					Visible = false,
					Parent = row,
				})
				local pickerBox = createInstance("Frame", {
					Size = UDim2.new(1, -4, 1, 0),
					Position = UDim2.new(0, 2, 0, 0),
					BackgroundColor3 = Theme.Elem,
					BorderSizePixel = 0,
					Parent = expansion,
				}, {
					createInstance("UIGridLayout", {
						CellSize = UDim2.new(0, 18, 0, 18),
						CellPadding = UDim2.new(0, 2, 0, 2),
					}),
					createPadding(4),
				})
				local pboxStroke = createStroke(Theme.Border, 1)
				pboxStroke.Parent = pickerBox
				ui:BindTheme(pickerBox, "BackgroundColor3", "Elem")
				ui:BindTheme(pboxStroke, "Color", "Border")

				for _, col in ipairs(presets) do
					local pb = createInstance("TextButton", {
						Text = "",
						BackgroundColor3 = col,
						BorderSizePixel = 0,
						AutoButtonColor = false,
						Parent = pickerBox,
					})
					local pbStroke = createStroke(Theme.BorderDim, 1)
					pbStroke.Parent = pb
					ui:BindTheme(pbStroke, "Color", "BorderDim")
					pb.MouseButton1Click:Connect(function()
						currentColor = col
						swatch.BackgroundColor3 = col
						if callback then Utils.SafeCall(callback, col) end
						triggerAutosave()
					end)
				end

				local function setOpen(open)
					expansion.Visible = open
					expansion.Size = open and UDim2.new(1, 0, 0, 48) or UDim2.new(1, 0, 0, 0)
				end
				ui:RegisterDropdown(setOpen)
				swatch.MouseButton1Click:Connect(function()
					ui:CloseAllDropdownsExcept(setOpen)
					setOpen(not expansion.Visible)
				end)

				return {
					Set = function(c, silent)
						currentColor = c
						swatch.BackgroundColor3 = c
						if not silent and callback then Utils.SafeCall(callback, c) end
						if not silent then triggerAutosave() end
					end,
					Get = function() return currentColor end,
				}
			end

			function section:AddKeybind(name, defaultKey, callback, rTier)
				if isLocked(rTier) then
					return {
						Set = function() end,
						Get = function() return defaultKey end,
					}
				end
				local _, rowContent = newRow(name, 22)
				local lbl = createInstance("TextLabel", {
					Text = name,
					Font = Enum.Font.Code,
					TextSize = 11,
					TextColor3 = Theme.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 2, 0, 0),
					Size = UDim2.new(1, -64, 1, 0),
					Parent = rowContent,
				})
				ui:BindTheme(lbl, "TextColor3", "Text")

				local currentKey = defaultKey
				local function getKeyDisplay(key)
					if not key then return "None" end
					if typeof(key) == "string" then return key:upper() end
					if typeof(key) == "EnumItem" then
						if key.EnumType == Enum.KeyCode then
							return key.Name
						elseif key.EnumType == Enum.UserInputType then
							return SET_MAP and SET_MAP[key] or SETTINGS.MOUSE_MAP[key] or key.Name
						end
					end
					return "None"
				end

				local keyBtn = createInstance("TextButton", {
					Text = getKeyDisplay(defaultKey),
					Font = Enum.Font.Code,
					TextSize = 10,
					TextColor3 = Theme.Text,
					BackgroundColor3 = Theme.Elem,
					BorderSizePixel = 0,
					Size = UDim2.new(0, 56, 0, 16),
					Position = UDim2.new(1, -58, 0.5, -8),
					AutoButtonColor = false,
					Parent = rowContent,
				})
				local kbStroke = createStroke(Theme.Border, 1)
				kbStroke.Parent = keyBtn
				ui:BindTheme(keyBtn, "BackgroundColor3", "Elem")
				ui:BindTheme(keyBtn, "TextColor3", "Text")
				ui:BindTheme(kbStroke, "Color", "Border")

				local listening = false
				keyBtn.MouseButton1Click:Connect(function()
					listening = true
					keyBtn.Text = "..."
					keyBtn.TextColor3 = Theme.Accent
				end)

				if Connections and Connections.Add then
					Connections.Add(UserInputService.InputBegan:Connect(function(input)
						if not listening then return end
						local bound, finalize = nil, false
						if input.UserInputType == Enum.UserInputType.Keyboard then
							if input.KeyCode == Enum.KeyCode.Escape then
								bound = nil
								finalize = true
							else
								bound = input.KeyCode
								finalize = true
							end
						elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
							bound = input.UserInputType
							finalize = true
						end
						if finalize then
							currentKey = bound
							keyBtn.Text = getKeyDisplay(bound)
							keyBtn.TextColor3 = Theme.Text
							listening = false
							if callback then Utils.SafeCall(callback, bound) end
							triggerAutosave()
						end
					end))
				end

				return {
					Set = function(k, silent)
						currentKey = k
						keyBtn.Text = getKeyDisplay(k)
						if not silent and callback then Utils.SafeCall(callback, k) end
						if not silent then triggerAutosave() end
					end,
					Get = function() return currentKey end,
				}
			end

			return section
		end

		return tab
	end

	return UI
end
