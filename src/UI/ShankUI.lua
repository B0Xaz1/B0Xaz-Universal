-- src/UI/ShankUI.lua
return function(Context, Theme)
    local TS = game:GetService("TweenService")
    local UIS = game:GetService("UserInputService")
    local CoreGui = game:GetService("CoreGui")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    local CONFIG = Context.CONFIG
    local State = Context.State
    local Utils = Context.Utils
    local Connections = Context.Connections

    local function createElement(class, props, children)
        local inst = Instance.new(class)
        if props then for k, v in pairs(props) do pcall(function() inst[k] = v end) end end
        if children then for _, child in ipairs(children) do child.Parent = inst end end
        return inst
    end

    local function uiCorner(r) return createElement("UICorner", {CornerRadius = UDim.new(0, r or 6)}) end
    local function uiStroke(color, thick, trans) 
        return createElement("UIStroke", {Color = color or Theme.Border, Thickness = thick or 1, Transparency = trans or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}) 
    end
    local function uiPadding(t, b, l, r)
        if b == nil then return createElement("UIPadding", {PaddingTop=UDim.new(0,t), PaddingBottom=UDim.new(0,t), PaddingLeft=UDim.new(0,t), PaddingRight=UDim.new(0,t)}) end
        return createElement("UIPadding", {PaddingTop=UDim.new(0,t or 0), PaddingBottom=UDim.new(0,b or 0), PaddingLeft=UDim.new(0,l or 0), PaddingRight=UDim.new(0,r or 0)})
    end
    local function uiTween(obj, time, props) 
        TS:Create(obj, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play() 
    end

    local _activeDrag = nil
    Connections.Add(UIS.InputChanged:Connect(function(input) 
        if _activeDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then 
            _activeDrag(input.Position.X) 
        end 
    end))
    Connections.Add(UIS.InputEnded:Connect(function(input) 
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
            _activeDrag = nil 
        end 
    end))

    local ShankUI = {}
    ShankUI.__index = ShankUI

    function ShankUI.new(title)
        local self = setmetatable({}, ShankUI)
        self.Tabs = {}; self.ActiveTab = nil; self._openDropdowns = {}; self.Minimized = false

        self.ScreenGui = createElement("ScreenGui", {Name = "B0XazShankUI", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true, DisplayOrder = 999})
        local parented = false
        pcall(function() if gethui then self.ScreenGui.Parent = gethui(); parented = true end end)
        if not parented then pcall(function() self.ScreenGui.Parent = CoreGui; parented = true end) end
        if not parented then self.ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

        self.Main = createElement("Frame", {Size = UDim2.new(0, CONFIG.UI_W, 0, CONFIG.UI_H), Position = UDim2.new(0.5, -CONFIG.UI_W/2, 0.5, -CONFIG.UI_H/2), BackgroundColor3 = Theme.Bg, BorderSizePixel = 0, ClipsDescendants = true, Parent = self.ScreenGui}, {uiCorner(6), uiStroke(Theme.Border, 1)})

        self.TitleBar = createElement("Frame", {Size = UDim2.new(1, 0, 0, CONFIG.UI_TITLEBAR_H), BackgroundColor3 = Theme.Side, BorderSizePixel = 0, Parent = self.Main})
        createElement("TextLabel", {Text = title or "B0Xaz", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -100, 1, 0), Parent = self.TitleBar})

        local closeBtn = createElement("TextButton", {Text = "X", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Theme.TextDim, BackgroundTransparency = 1, Size = UDim2.new(0, 28, 0, 28), Position = UDim2.new(1, -32, 0, 3), Parent = self.TitleBar, AutoButtonColor = false})
        closeBtn.MouseEnter:Connect(function() closeBtn.TextColor3 = Theme.Danger end)
        closeBtn.MouseLeave:Connect(function() closeBtn.TextColor3 = Theme.TextDim end)
        closeBtn.MouseButton1Click:Connect(function()
            self.Main.Visible = false
            State.MenuVisible = false
        end)

        local minBtn = createElement("TextButton", {Text = "-", Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = Theme.TextDim, BackgroundTransparency = 1, Size = UDim2.new(0, 28, 0, 28), Position = UDim2.new(1, -60, 0, 3), Parent = self.TitleBar, AutoButtonColor = false})
        minBtn.MouseEnter:Connect(function() minBtn.TextColor3 = Theme.Text end)
        minBtn.MouseLeave:Connect(function() minBtn.TextColor3 = Theme.TextDim end)

        self.ContentWrapper = createElement("Frame", {Size = UDim2.new(1, 0, 1, -CONFIG.UI_TITLEBAR_H), Position = UDim2.new(0, 0, 0, CONFIG.UI_TITLEBAR_H), BackgroundTransparency = 1, Parent = self.Main})

        minBtn.MouseButton1Click:Connect(function()
            self.Minimized = not self.Minimized
            if self.Minimized then 
                uiTween(self.Main, 0.2, {Size = UDim2.new(0, CONFIG.UI_W, 0, CONFIG.UI_TITLEBAR_H)})
                self.ContentWrapper.Visible = false
            else 
                self.ContentWrapper.Visible = true
                uiTween(self.Main, 0.2, {Size = UDim2.new(0, CONFIG.UI_W, 0, CONFIG.UI_H)}) 
            end
        end)

        self.Sidebar = createElement("Frame", {Size = UDim2.new(0, 140, 1, 0), BackgroundColor3 = Theme.Side, BorderSizePixel = 0, Parent = self.ContentWrapper})
        self.SidebarList = createElement("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Parent = self.Sidebar}, {createElement("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}), uiPadding(8, 8, 6, 6)})
        self.Content = createElement("Frame", {Size = UDim2.new(1, -140, 1, 0), Position = UDim2.new(0, 140, 0, 0), BackgroundTransparency = 1, Parent = self.ContentWrapper})
        self.SearchFrame = createElement("Frame", {Size = UDim2.new(1, -16, 0, 28), Position = UDim2.new(0, 8, 0, 6), BackgroundColor3 = Theme.Elem, BorderSizePixel = 0, Parent = self.Content}, {uiCorner(5)})
        self.SearchBox = createElement("TextBox", {PlaceholderText = "Search", Text = "", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, PlaceholderColor3 = Theme.TextMuted, BackgroundTransparency = 1, Size = UDim2.new(1, -16, 1, 0), Position = UDim2.new(0, 8, 0, 0), TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, Parent = self.SearchFrame})
        self.PagesContainer = createElement("Frame", {Size = UDim2.new(1, 0, 1, -42), Position = UDim2.new(0, 0, 0, 42), BackgroundTransparency = 1, Parent = self.Content})

        do
            local dragging, dragStart, startPos = false, Vector3.zero, UDim2.new()
            self.TitleBar.InputBegan:Connect(function(input) 
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
                    dragging = true; dragStart = input.Position; startPos = self.Main.Position 
                end 
            end)
            self.TitleBar.InputEnded:Connect(function(input) 
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
                    dragging = false 
                end 
            end)
            Connections.Add(UIS.InputChanged:Connect(function(input) 
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then 
                    local delta = input.Position - dragStart
                    self.Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) 
                end 
            end))
        end

        self.SearchBox:GetPropertyChangedSignal("Text"):Connect(function() self:_ApplySearch(self.SearchBox.Text) end)
        self.NotifyContainer = createElement("Frame", {Size = UDim2.new(0, 260, 1, -20), Position = UDim2.new(1, -270, 0, 10), BackgroundTransparency = 1, Parent = self.ScreenGui}, {createElement("UIListLayout", {Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom})})
        return self
    end

    function ShankUI:RegisterDropdown(closeFn) table.insert(self._openDropdowns, closeFn) end
    function ShankUI:CloseAllDropdownsExcept(exceptFn) 
        for _, fn in ipairs(self._openDropdowns) do 
            if fn ~= exceptFn then fn(false) end 
        end 
    end

    function ShankUI:_ApplySearch(query)
        query = query:lower()
        for _, tab in ipairs(self.Tabs) do
            for _, section in ipairs(tab.Sections) do
                if #query == 0 then 
                    section.Frame.Visible = true
                    for _, elem in ipairs(section.Elements) do elem.Container.Visible = true end
                else
                    local secMatch = section.Name:lower():find(query, 1, true)
                    local anyVisible = false
                    for _, elem in ipairs(section.Elements) do 
                        local match = secMatch or elem.Name:lower():find(query, 1, true)
                        elem.Container.Visible = match and true or false
                        if match then anyVisible = true end 
                    end
                    section.Frame.Visible = anyVisible
                end
            end
        end
    end

    function ShankUI:Notify(title, text, duration, color)
        local accentColor = color or Theme.Accent
        local notif = createElement("Frame", {Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = Theme.Panel, BorderSizePixel = 0, Parent = self.NotifyContainer, BackgroundTransparency = 1},
            {uiCorner(6), uiStroke(accentColor, 1, 0.5),
            createElement("TextLabel", {Text = title, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Position = UDim2.new(0, 8, 0, 6), Size = UDim2.new(1, -16, 0, 14)}),
            createElement("TextLabel", {Text = text, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Theme.TextDim, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, BackgroundTransparency = 1, Position = UDim2.new(0, 8, 0, 22), Size = UDim2.new(1, -16, 0, 22)})})
        uiTween(notif, 0.15, {BackgroundTransparency = 0})
        task.delay(duration or CONFIG.NOTIFY_DEFAULT_TIME, function() 
            if not notif.Parent then return end
            uiTween(notif, 0.2, {BackgroundTransparency = 1})
            task.wait(0.2)
            pcall(function() notif:Destroy() end) 
        end)
    end

    function ShankUI:SelectTab(tab)
        for _, t in ipairs(self.Tabs) do 
            t.Page.Visible = false; t.Button.TextColor3 = Theme.TextDim; t.Button.BackgroundColor3 = Theme.Side 
        end
        tab.Page.Visible = true; tab.Button.TextColor3 = Theme.Text; tab.Button.BackgroundColor3 = Theme.Elem
        self.ActiveTab = tab; self:CloseAllDropdownsExcept(nil)
    end

    function ShankUI:AddTab(name)
        local ui = self
        local tab = {Name = name, Sections = {}, UI = ui}

        tab.Button = createElement("TextButton", {Text = name, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Theme.TextDim, TextXAlignment = Enum.TextXAlignment.Left, BackgroundColor3 = Theme.Side, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 30), AutoButtonColor = false, Parent = self.SidebarList}, {uiCorner(5), createElement("UIPadding", {PaddingLeft = UDim.new(0, 10)})})
        tab.Page = createElement("ScrollingFrame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.AccentDark, CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false, Parent = self.PagesContainer}, {createElement("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}), uiPadding(4, 10, 8, 8)})

        tab.Button.MouseEnter:Connect(function() if ui.ActiveTab ~= tab then uiTween(tab.Button, 0.1, {BackgroundColor3 = Theme.ElemHover}) end end)
        tab.Button.MouseLeave:Connect(function() if ui.ActiveTab ~= tab then uiTween(tab.Button, 0.1, {BackgroundColor3 = Theme.Side}) end end)
        tab.Button.MouseButton1Click:Connect(function() ui:SelectTab(tab) end)
        table.insert(self.Tabs, tab)
        if not self.ActiveTab then self:SelectTab(tab) end

        function tab:AddSection(secName)
            local section = {Name = secName, Elements = {}, Tab = tab}
            local rowOrder = 0

            section.Frame = createElement("Frame", {BackgroundColor3 = Theme.Panel, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BorderSizePixel = 0, Parent = tab.Page}, {uiCorner(6), uiStroke(Theme.Border, 1), createElement("UIListLayout", {Padding = UDim.new(0, 0), SortOrder = Enum.SortOrder.LayoutOrder})})
            createElement("TextLabel", {Text = "  " .. secName, Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = Theme.TextDim, TextXAlignment = Enum.TextXAlignment.Left, BackgroundColor3 = Theme.Elem, Size = UDim2.new(1, 0, 0, 26), LayoutOrder = 0, Parent = section.Frame}, {uiCorner(6)})
            local body = createElement("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1, Parent = section.Frame}, {createElement("UIListLayout", {Padding = UDim.new(0, 1), SortOrder = Enum.SortOrder.LayoutOrder}), uiPadding(4, 6, 6, 6)})
            table.insert(tab.Sections, section)

            local function newRow(elemName, h)
                rowOrder += 1
                local row = createElement("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = rowOrder, Parent = body}, {createElement("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder})})
                local content = createElement("Frame", {Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, LayoutOrder = 1, Parent = row})
                table.insert(section.Elements, {Container = row, Name = elemName})
                return row, content
            end

            function section:AddToggle(name, default, callback)
                local _, content = newRow(name, 34)
                createElement("TextLabel", {Text = name, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Position = UDim2.new(0, 4, 0, 0), Size = UDim2.new(1, -50, 1, 0), Parent = content})
                local toggleBG = createElement("Frame", {Size = UDim2.new(0, 32, 0, 16), Position = UDim2.new(1, -38, 0.5, -8), BackgroundColor3 = default and Theme.ToggleOn or Theme.ToggleOff, BorderSizePixel = 0, Parent = content}, {uiCorner(8)})
                local knob = createElement("Frame", {Size = UDim2.new(0, 12, 0, 12), Position = default and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6), BackgroundColor3 = Color3.fromRGB(240,240,245), BorderSizePixel = 0, Parent = toggleBG}, {uiCorner(6)})
                local btn = createElement("TextButton", {Text = "", BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0), Parent = content})
                local state = default or false
                local function setState(v, silent)
                    state = v
                    uiTween(toggleBG, 0.1, {BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff})
                    uiTween(knob, 0.1, {Position = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)})
                    if not silent and callback then Utils.SafeCall(callback, state) end
                end
                btn.MouseButton1Click:Connect(function() setState(not state) end)
                return {Set = setState, Get = function() return state end}
            end

            function section:AddSlider(name, default, min, max, callback, suffix)
                local _, content = newRow(name, 46)
                createElement("TextLabel", {Text = name, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Position = UDim2.new(0, 4, 0, 2), Size = UDim2.new(1, -60, 0, 16), Parent = content})
                local valLabel = createElement("TextLabel", {Text = tostring(default) .. (suffix or ""), Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Theme.TextDim, TextXAlignment = Enum.TextXAlignment.Right, BackgroundTransparency = 1, Position = UDim2.new(1, -50, 0, 2), Size = UDim2.new(0, 46, 0, 16), Parent = content})
                local track = createElement("Frame", {Size = UDim2.new(1, -8, 0, 4), Position = UDim2.new(0, 4, 0, 28), BackgroundColor3 = Theme.ToggleOff, BorderSizePixel = 0, Parent = content}, {uiCorner(2)})
                local initRel = math.clamp((default - min) / math.max(max - min, 1e-6), 0, 1)
                local fill = createElement("Frame", {Size = UDim2.new(initRel, 0, 1, 0), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = track}, {uiCorner(2)})
                local knob = createElement("Frame", {Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(initRel, -5, 0.5, -5), BackgroundColor3 = Color3.fromRGB(240,240,245), BorderSizePixel = 0, Parent = track}, {uiCorner(5)})
                local value = default
                local function commit(rel, silent)
                    rel = math.clamp(rel, 0, 1); value = math.floor(min + (max - min) * rel + 0.5)
                    fill.Size = UDim2.new(rel, 0, 1, 0); knob.Position = UDim2.new(rel, -5, 0.5, -5)
                    valLabel.Text = tostring(value) .. (suffix or "")
                    if not silent and callback then Utils.SafeCall(callback, value) end
                end
                local function updateFromX(x) commit((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1)) end
                track.InputBegan:Connect(function(input) 
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
                        _activeDrag = updateFromX; updateFromX(input.Position.X) 
                    end 
                end)
                return {
                    Set = function(v, silent) commit((math.clamp(v, min, max) - min) / math.max(max - min, 1e-6), silent) end, 
                    Get = function() return value end
                }
            end

            function section:AddButton(name, callback)
                local _, content = newRow(name, 32)
                local btn = createElement("TextButton", {Text = name, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, BackgroundColor3 = Theme.Elem, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 26), Position = UDim2.new(0, 0, 0, 3), AutoButtonColor = false, Parent = content}, {uiCorner(5)})
                btn.MouseEnter:Connect(function() uiTween(btn, 0.1, {BackgroundColor3 = Theme.ElemHover}) end)
                btn.MouseLeave:Connect(function() uiTween(btn, 0.1, {BackgroundColor3 = Theme.Elem}) end)
                btn.MouseButton1Click:Connect(function() if callback then Utils.SafeCall(callback) end end)
            end

            function section:AddDropdown(name, options, callback, default)
                local row, content = newRow(name, 34)
                createElement("TextLabel", {Text = name, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Position = UDim2.new(0, 4, 0, 0), Size = UDim2.new(0.5, -4, 1, 0), Parent = content})
                local currentOptions = table.clone(options or {}); local selected = default or currentOptions[1] or ""
                local displayBtn = createElement("TextButton", {Text = (selected ~= "" and selected or "None") .. "  v", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Theme.TextDim, BackgroundColor3 = Theme.Elem, BorderSizePixel = 0, Size = UDim2.new(0.5, -8, 0, 24), Position = UDim2.new(0.5, 8, 0.5, -12), AutoButtonColor = false, Parent = content}, {uiCorner(4)})
                local expansion = createElement("Frame", {Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, LayoutOrder = 2, Visible = false, Parent = row})
                local listBox = createElement("ScrollingFrame", {Size = UDim2.new(0.5, -8, 1, -2), Position = UDim2.new(0.5, 8, 0, 0), BackgroundColor3 = Theme.Elem, BorderSizePixel = 0, CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.AccentDark, Parent = expansion}, {uiCorner(4), createElement("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder})})
                local isOpen = false
                local function setOpen(open)
                    isOpen = open
                    if open then 
                        local h = math.min(#currentOptions, CONFIG.DROPDOWN_MAX_ROWS) * CONFIG.DROPDOWN_ROW_HEIGHT + 4
                        expansion.Size = UDim2.new(1, 0, 0, math.max(h, CONFIG.DROPDOWN_ROW_HEIGHT + 4))
                        expansion.Visible = true
                    else 
                        expansion.Visible = false
                        expansion.Size = UDim2.new(1, 0, 0, 0) 
                    end
                end
                ui:RegisterDropdown(setOpen)
                local function rebuildOptions()
                    for _, child in ipairs(listBox:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
                    local opts = #currentOptions > 0 and currentOptions or {"None"}
                    for _, opt in ipairs(opts) do
                        local optBtn = createElement("TextButton", {Text = tostring(opt), Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Theme.Text, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, CONFIG.DROPDOWN_ROW_HEIGHT), AutoButtonColor = false, Parent = listBox})
                        optBtn.MouseEnter:Connect(function() optBtn.BackgroundTransparency = 0; optBtn.BackgroundColor3 = Theme.ElemHover end)
                        optBtn.MouseLeave:Connect(function() optBtn.BackgroundTransparency = 1 end)
                        optBtn.MouseButton1Click:Connect(function() 
                            if opt ~= "None" or #currentOptions > 0 then 
                                selected = opt
                                displayBtn.Text = tostring(opt) .. "  v"
                                setOpen(false)
                                if callback then Utils.SafeCall(callback, opt) end 
                            end 
                        end)
                    end
                end
                rebuildOptions()
                displayBtn.MouseButton1Click:Connect(function() ui:CloseAllDropdownsExcept(setOpen); setOpen(not isOpen) end)
                return {
                    Set = function(v, silent) selected = v; displayBtn.Text = tostring(v) .. "  v"; if not silent and callback then Utils.SafeCall(callback, v) end end,
                    Get = function() return selected end,
                    Refresh = function(newOpts, preserve) 
                        currentOptions = table.clone(newOpts or {})
                        if not preserve or not table.find(currentOptions, selected) then 
                            selected = currentOptions[1] or ""
                            displayBtn.Text = (selected ~= "" and selected or "None") .. "  v" 
                        end
                        rebuildOptions() 
                    end,
                    Close = function() setOpen(false) end,
                }
            end

            function section:AddTextbox(name, default, callback, placeholder)
                local _, content = newRow(name, 34)
                createElement("TextLabel", {Text = name, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Position = UDim2.new(0, 4, 0, 0), Size = UDim2.new(0.5, -4, 1, 0), Parent = content})
                local boxFrame = createElement("Frame", {Size = UDim2.new(0.5, -8, 0, 24), Position = UDim2.new(0.5, 8, 0.5, -12), BackgroundColor3 = Theme.Elem, BorderSizePixel = 0, Parent = content}, {uiCorner(4)})
                local box = createElement("TextBox", {Text = default or "", PlaceholderText = placeholder or "", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Theme.Text, PlaceholderColor3 = Theme.TextMuted, BackgroundTransparency = 1, Size = UDim2.new(1, -8, 1, 0), Position = UDim2.new(0, 4, 0, 0), ClearTextOnFocus = false, Parent = boxFrame})
                box.FocusLost:Connect(function(enter) if callback then Utils.SafeCall(callback, box.Text, enter) end end)
                return {Set = function(v) box.Text = tostring(v or "") end, Get = function() return box.Text end}
            end

            function section:AddColorPicker(name, default, callback)
                local row, content = newRow(name, 34)
                createElement("TextLabel", {Text = name, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Position = UDim2.new(0, 4, 0, 0), Size = UDim2.new(1, -40, 1, 0), Parent = content})
                local swatch = createElement("TextButton", {Text = "", Size = UDim2.new(0, 26, 0, 16), Position = UDim2.new(1, -30, 0.5, -8), BackgroundColor3 = default or Color3.new(1,1,1), BorderSizePixel = 0, AutoButtonColor = false, Parent = content}, {uiCorner(4), uiStroke(Theme.Border, 1)})
                local currentColor = default or Color3.new(1,1,1)
                local presets = {Color3.fromRGB(255,255,255), Color3.fromRGB(0,0,0), Color3.fromRGB(255,50,50), Color3.fromRGB(255,150,50), Color3.fromRGB(255,230,50), Color3.fromRGB(50,255,80), Color3.fromRGB(50,200,255), Color3.fromRGB(80,80,255), Color3.fromRGB(200,80,255), Color3.fromRGB(255,80,180)}
                local expansion = createElement("Frame", {Size = UDim2.new(1,0,0,0), BackgroundTransparency = 1, LayoutOrder = 2, Visible = false, Parent = row})
                local pickerBox = createElement("Frame", {Size = UDim2.new(1, -8, 1, -2), Position = UDim2.new(0, 4, 0, 0), BackgroundColor3 = Theme.Elem, BorderSizePixel = 0, Parent = expansion}, {uiCorner(4), createElement("UIGridLayout", {CellSize = UDim2.new(0,20,0,20), CellPadding = UDim2.new(0,2,0,2)}), uiPadding(4)})
                for _, c in ipairs(presets) do
                    local pb = createElement("TextButton", {Text = "", BackgroundColor3 = c, BorderSizePixel = 0, AutoButtonColor = false, Parent = pickerBox}, {uiCorner(3)})
                    pb.MouseButton1Click:Connect(function() 
                        currentColor = c
                        swatch.BackgroundColor3 = c
                        if callback then Utils.SafeCall(callback, c) end 
                    end)
                end
                local function setOpen(open) 
                    expansion.Visible = open
                    expansion.Size = open and UDim2.new(1, 0, 0, 54) or UDim2.new(1, 0, 0, 0) 
                end
                ui:RegisterDropdown(setOpen)
                swatch.MouseButton1Click:Connect(function() ui:CloseAllDropdownsExcept(setOpen); setOpen(not expansion.Visible) end)
                return {Set = function(c) currentColor = c; swatch.BackgroundColor3 = c end, Get = function() return currentColor end}
            end

            function section:AddKeybind(name, defaultKey, callback)
                local _, content = newRow(name, 34)
                createElement("TextLabel", {Text = name, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Position = UDim2.new(0, 4, 0, 0), Size = UDim2.new(1, -70, 1, 0), Parent = content})
                local currentKey = defaultKey
                local keyBtn = createElement("TextButton", {Text = defaultKey and defaultKey.Name or "None", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Theme.Text, BackgroundColor3 = Theme.Elem, BorderSizePixel = 0, Size = UDim2.new(0, 58, 0, 20), Position = UDim2.new(1, -62, 0.5, -10), AutoButtonColor = false, Parent = content}, {uiCorner(4)})
                local listening = false
                keyBtn.MouseButton1Click:Connect(function() listening = true; keyBtn.Text = "..."; keyBtn.TextColor3 = Theme.Accent end)
                Connections.Add(UIS.InputBegan:Connect(function(input, processed)
                    if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                        if input.KeyCode == Enum.KeyCode.Escape then 
                            currentKey = nil; keyBtn.Text = "None" 
                        else 
                            currentKey = input.KeyCode; keyBtn.Text = input.KeyCode.Name 
                        end
                        keyBtn.TextColor3 = Theme.Text
                        listening = false
                    elseif not processed and currentKey and input.KeyCode == currentKey then 
                        if callback then Utils.SafeCall(callback) end 
                    end
                end))
                return {Set = function(k) currentKey = k; keyBtn.Text = k and k.Name or "None" end, Get = function() return currentKey end}
            end

            return section
        end
        return tab
    end

    return ShankUI
end
