local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local UI_WIDTH: number = 660
local UI_HEIGHT: number = 460
local TITLE_HEIGHT: number = 28
local TAB_HEIGHT: number = 26
local PAGE_ZINDEX: number = 1
local TAB_ZINDEX: number = 50
local OVERLAY_ZINDEX: number = 100

export type TabInstance = {
	Name: string,
	RequiredTier: number,
	Locked: boolean,
	Button: TextButton,
	Underline: Frame,
	Page: Frame,
	LeftCol: ScrollingFrame,
	RightCol: ScrollingFrame,
	AddSection: (self: any, title: string, side: ("left" | "right")?) -> any,
}

return function(services: any)
	local Environment = services:Get("Environment")
	local ThemeEngine = services:Get("ThemeEngine")
	local StateStore = services:Get("StateStore")
	local Disposer = services:Get("Disposer")
	local EventBus = services:Get("EventBus")
	local DOM = services:Get("DOM")
	local Require = services:Get("Require")

	local UIEngine = {
		ScreenGui = nil :: ScreenGui?,
		MainWindow = nil :: Frame?,
		ScaleObject = nil :: UIScale?,
		TabContainer = nil :: Frame?,
		PagesContainer = nil :: Frame?,
		NotifyContainer = nil :: Frame?,
		Tabs = {} :: { TabInstance },
		ActiveTab = nil :: TabInstance?,
		_dropdownCloseHandlers = {} :: { () -> () },
	}

	-- Drag state lives in this closure; the two UserInputService listeners
	-- are registered with the disposer so dragging cannot survive an unload.
	function UIEngine:MakeDraggable(targetFrame: Frame, handleBar: GuiObject)
		local dragging = false
		local dragStart = Vector3.zero
		local startPos = UDim2.new()

		handleBar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = targetFrame.Position
			end
		end)

		local inputEnded = UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
		Disposer:Add(inputEnded)

		local inputChanged = UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - dragStart
				targetFrame.Position = UDim2.new(
					startPos.X.Scale, startPos.X.Offset + delta.X,
					startPos.Y.Scale, startPos.Y.Offset + delta.Y
				)
			end
		end)
		Disposer:Add(inputChanged)
	end

	-- Toasts stack bottom-up; each new toast gets a higher LayoutOrder so
	-- the newest one always appears above the older ones.
	local toastOrder = 0

	function UIEngine:Notify(title: string, text: string, duration: number?, customColor: Color3?)
		if not self.NotifyContainer then return end
		local accent = customColor or ThemeEngine:GetToken("Accent")
		toastOrder += 1

		local toast = DOM.Create("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = ThemeEngine:GetToken("Panel"),
			BorderSizePixel = 0,
			LayoutOrder = toastOrder,
			Parent = self.NotifyContainer,
		}, {
			DOM.CreateStroke(accent, 1),
			DOM.CreatePadding(6, 6, 8, 8),
			DOM.Create("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }),
			DOM.Create("TextLabel", {
				Text = title or "Notification",
				Font = Enum.Font.Code,
				TextSize = 12,
				TextColor3 = ThemeEngine:GetToken("Text"),
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 14),
				LayoutOrder = 1,
			}),
			DOM.Create("TextLabel", {
				Text = text or "",
				Font = Enum.Font.Code,
				TextSize = 11,
				TextColor3 = ThemeEngine:GetToken("TextDim"),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextWrapped = true,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = 2,
			}),
		})

		ThemeEngine:BindToken(toast, "BackgroundColor3", "Panel")

		Disposer:Delay(duration or 3.5, function()
			if toast and toast.Parent then
				toast:Destroy()
			end
		end)
	end

	function UIEngine:RegisterDropdownClose(closeFn: () -> ())
		table.insert(self._dropdownCloseHandlers, closeFn)
	end

	-- Opening one dropdown closes every other open dropdown
	function UIEngine:CloseAllDropdownsExcept(exceptFn: (() -> ())?)
		for _, fn in ipairs(self._dropdownCloseHandlers) do
			if fn ~= exceptFn then
				pcall(fn)
			end
		end
	end

	function UIEngine:SelectTab(tab: TabInstance)
		if tab.Locked then
			self:Notify("Access Denied", "This tab requires a higher tier key.", 2.5, ThemeEngine:GetToken("Danger"))
			return
		end

		for _, t in ipairs(self.Tabs) do
			t.Page.Visible = false
			t.Button.TextColor3 = ThemeEngine:GetToken("TextDim")
			t.Underline.Visible = false
		end

		tab.Page.Visible = true
		tab.Button.TextColor3 = ThemeEngine:GetToken("Text")
		tab.Underline.BackgroundColor3 = ThemeEngine:GetToken("Accent")
		tab.Underline.Visible = true
		self.ActiveTab = tab

		self:CloseAllDropdownsExcept(nil)
	end

	function UIEngine:ConstructInterface()
		local parent = Environment.GetSafeGuiParent()

		self.ScreenGui = DOM.Create("ScreenGui", {
			Name = DOM.GenerateGUID(),
			ResetOnSpawn = false,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			IgnoreGuiInset = true,
			DisplayOrder = 999,
			Parent = parent,
		}) :: ScreenGui
		Disposer:Add(self.ScreenGui)
		ThemeEngine:RegisterRoot(self.ScreenGui)

		self.MainWindow = DOM.Create("Frame", {
			Size = UDim2.fromOffset(UI_WIDTH, UI_HEIGHT),
			Position = UDim2.new(0.5, -UI_WIDTH * 0.5, 0.5, -UI_HEIGHT * 0.5),
			BackgroundColor3 = ThemeEngine:GetToken("Bg"),
			BorderSizePixel = 0,
			Active = true,
			ClipsDescendants = true,
			ZIndex = PAGE_ZINDEX,
			Parent = self.ScreenGui,
		}, {
			DOM.CreateStroke(ThemeEngine:GetToken("Border"), 1),
		}) :: Frame

		ThemeEngine:BindToken(self.MainWindow, "BackgroundColor3", "Bg")

		self.ScaleObject = DOM.Create("UIScale", {
			Scale = tonumber(StateStore:Get("Settings.UIScale")) or 1.0,
			Parent = self.MainWindow,
		}) :: UIScale

		local titleBar = DOM.Create("Frame", {
			Size = UDim2.new(1, 0, 0, TITLE_HEIGHT),
			BackgroundColor3 = ThemeEngine:GetToken("Side"),
			BorderSizePixel = 0,
			ZIndex = TAB_ZINDEX,
			Parent = self.MainWindow,
		}, {
			DOM.Create("TextLabel", {
				Text = "  B0Xaz Universal Suite",
				Font = Enum.Font.Code,
				TextSize = 13,
				TextColor3 = ThemeEngine:GetToken("Text"),
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -40, 1, 0),
			}),
		}) :: Frame
		ThemeEngine:BindToken(titleBar, "BackgroundColor3", "Side")
		self:MakeDraggable(self.MainWindow, titleBar)

		local closeBtn = DOM.Create("TextButton", {
			Text = "✕",
			Font = Enum.Font.Code,
			TextSize = 13,
			TextColor3 = ThemeEngine:GetToken("TextDim"),
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(28, TITLE_HEIGHT),
			Position = UDim2.new(1, -28, 0, 0),
			ZIndex = TAB_ZINDEX + 2,
			Parent = titleBar,
		}) :: TextButton
		closeBtn.MouseButton1Click:Connect(function()
			self.MainWindow.Visible = false
			StateStore:SetTransient("MenuVisible", false)
		end)

		self.TabContainer = DOM.Create("Frame", {
			Size = UDim2.new(1, 0, 0, TAB_HEIGHT),
			Position = UDim2.new(0, 0, 0, TITLE_HEIGHT),
			BackgroundColor3 = ThemeEngine:GetToken("Side"),
			BorderSizePixel = 0,
			Active = true,
			ClipsDescendants = true,
			ZIndex = TAB_ZINDEX,
			Parent = self.MainWindow,
		}, {
			DOM.Create("Frame", {
				Size = UDim2.new(1, 0, 0, 1),
				Position = UDim2.new(0, 0, 1, -1),
				BackgroundColor3 = ThemeEngine:GetToken("BorderDim"),
				BorderSizePixel = 0,
			}),
		}) :: Frame
		ThemeEngine:BindToken(self.TabContainer, "BackgroundColor3", "Side")

		local tabListLayout = DOM.Create("ScrollingFrame", {
			Size = UDim2.new(1, -8, 1, 0),
			Position = UDim2.new(0, 4, 0, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 0,
			ScrollingDirection = Enum.ScrollingDirection.X,
			AutomaticCanvasSize = Enum.AutomaticSize.X,
			-- The vertical canvas must stay non-zero or the 1-scale buttons
			-- collapse to zero height inside the horizontal scroller.
			CanvasSize = UDim2.new(0, 0, 1, 0),
			Active = true,
			ZIndex = TAB_ZINDEX + 1,
			Parent = self.TabContainer,
		}, {
			DOM.Create("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 4),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
		})

		self.PagesContainer = DOM.Create("Frame", {
			Size = UDim2.new(1, 0, 1, -(TITLE_HEIGHT + TAB_HEIGHT)),
			Position = UDim2.new(0, 0, 0, TITLE_HEIGHT + TAB_HEIGHT),
			BackgroundTransparency = 1,
			ClipsDescendants = true,
			ZIndex = PAGE_ZINDEX,
			Parent = self.MainWindow,
		}) :: Frame

		self.NotifyContainer = DOM.Create("Frame", {
			Size = UDim2.new(0, 280, 1, -20),
			Position = UDim2.new(1, -290, 0, 10),
			BackgroundTransparency = 1,
			ZIndex = OVERLAY_ZINDEX,
			Parent = self.ScreenGui,
		}, {
			DOM.Create("UIListLayout", {
				Padding = UDim.new(0, 6),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Bottom,
			}),
		}) :: Frame

		local function addTab(tabName: string, reqTier: number?): TabInstance
			local tier = reqTier or 1
			local isLocked = tier > StateStore:GetTier()

			local tabBtn = DOM.Create("TextButton", {
				Text = tabName .. (isLocked and " [🔒]" or ""),
				Font = Enum.Font.Code,
				TextSize = 11,
				TextColor3 = ThemeEngine:GetToken("TextDim"),
				BackgroundTransparency = 1,
				Size = UDim2.new(0, math.max(60, #tabName * 7 + 20), 1, 0),
				ZIndex = TAB_ZINDEX + 2,
				Parent = tabListLayout,
			}) :: TextButton

			local underline = DOM.Create("Frame", {
				Size = UDim2.new(1, -6, 0, 2),
				Position = UDim2.new(0, 3, 1, -2),
				BackgroundColor3 = ThemeEngine:GetToken("Accent"),
				BorderSizePixel = 0,
				Visible = false,
				ZIndex = TAB_ZINDEX + 3,
				Parent = tabBtn,
			}) :: Frame

			local pageFrame = DOM.Create("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Visible = false,
				ClipsDescendants = true,
				ZIndex = PAGE_ZINDEX,
				Parent = self.PagesContainer,
			}) :: Frame

			local leftCol = DOM.Create("ScrollingFrame", {
				Size = UDim2.new(0.5, -12, 1, -16),
				Position = UDim2.new(0, 8, 0, 8),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollBarThickness = 3,
				ScrollingDirection = Enum.ScrollingDirection.Y,
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				ZIndex = PAGE_ZINDEX + 1,
				Parent = pageFrame,
			}, {
				DOM.Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
				DOM.CreatePadding(0, 8, 0, 4),
			}) :: ScrollingFrame

			local rightCol = DOM.Create("ScrollingFrame", {
				Size = UDim2.new(0.5, -12, 1, -16),
				Position = UDim2.new(0.5, 4, 0, 8),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollBarThickness = 3,
				ScrollingDirection = Enum.ScrollingDirection.Y,
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				ZIndex = PAGE_ZINDEX + 1,
				Parent = pageFrame,
			}, {
				DOM.Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
				DOM.CreatePadding(0, 8, 0, 4),
			}) :: ScrollingFrame

			local tabRecord: TabInstance = {
				Name = tabName,
				RequiredTier = tier,
				Locked = isLocked,
				Button = tabBtn,
				Underline = underline,
				Page = pageFrame,
				LeftCol = leftCol,
				RightCol = rightCol,
				AddSection = nil :: any,
			}

			tabBtn.MouseButton1Click:Connect(function()
				self:SelectTab(tabRecord)
			end)

			table.insert(self.Tabs, tabRecord)
			return tabRecord
		end

		local tabFiles = {
			{ Path = "src/UI/Tabs/CombatTab.luau", Tier = 3 },
			{ Path = "src/UI/Tabs/VisualsTab.luau", Tier = 2 },
			{ Path = "src/UI/Tabs/MovementTab.luau", Tier = 1 },
			{ Path = "src/UI/Tabs/PlayersTab.luau", Tier = 1 },
			{ Path = "src/UI/Tabs/UtilityTab.luau", Tier = 1 },
			{ Path = "src/UI/Tabs/PerformanceTab.luau", Tier = 1 },
			{ Path = "src/UI/Tabs/GameTab.luau", Tier = 3 },
			{ Path = "src/UI/Tabs/SettingsTab.luau", Tier = 0 },
		}

		for _, tabDef in ipairs(tabFiles) do
			local factory = Require(tabDef.Path)
			if typeof(factory) == "function" then
				local tabInst = addTab(tabDef.Path:match("([^/]+)Tab%.luau$") or "Tab", tabDef.Tier)
				factory(services, tabInst)
			end
		end

		if #self.Tabs > 0 then
			self:SelectTab(self.Tabs[1])
		end

		-- Lock state is computed once at construction; this keeps it current
		-- when the tier changes later (logout, key swap).
		EventBus:Subscribe("TierChanged", function()
			for _, tabRecord in ipairs(self.Tabs) do
				local locked = tabRecord.RequiredTier > StateStore:GetTier()
				if locked ~= tabRecord.Locked then
					tabRecord.Locked = locked
					tabRecord.Button.Text = tabRecord.Name .. (locked and " [🔒]" or "")
				end
			end
			-- If the active tab just got locked, fall back to the first one
			-- the current tier can open.
			if self.ActiveTab and self.ActiveTab.Locked then
				local fallback = nil
				for _, tabRecord in ipairs(self.Tabs) do
					if not tabRecord.Locked then
						fallback = tabRecord
						break
					end
				end
				self:Notify("Access", "Your tier no longer covers the active tab.", 2.5, ThemeEngine:GetToken("Warning"))
				if fallback then
					self:SelectTab(fallback)
				end
			end
		end)

		local toggleConn = UserInputService.InputBegan:Connect(function(input, gp)
			if UserInputService:GetFocusedTextBox() ~= nil or StateStore:GetTransient("IsBindingKey") then return end
			local menuKey = Environment.ParseKeybind(StateStore:Get("Settings.MenuKeybind"))
			if menuKey and (input.KeyCode == menuKey or input.UserInputType == menuKey) then
				local isVis = not self.MainWindow.Visible
				self.MainWindow.Visible = isVis
				StateStore:SetTransient("MenuVisible", isVis)
			end
		end)
		Disposer:Add(toggleConn)
	end

	return UIEngine
end
