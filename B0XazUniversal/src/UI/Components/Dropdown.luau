--!strict
-- ══════════════════════════════════════════════════════════════════════════════
-- B0XazUniversal - Expandable Dropdown Component
-- Features responsive expanding layout, auto-closing coordinator hooks,
-- full option refreshing, and reactive selection bindings.
-- ══════════════════════════════════════════════════════════════════════════════

export type DropdownHandle = {
	Set: (self: DropdownHandle, option: string, silent: boolean?) -> (),
	Get: (self: DropdownHandle) -> string,
	Refresh: (self: DropdownHandle, newOptions: { string }, preserveSelection: boolean?) -> (),
	Instance: Frame,
}

return function(services: any)
	local ThemeEngine = services:Get("ThemeEngine")
	local StateStore = services:Get("StateStore")
	local EventBus = services:Get("EventBus")
	local UIEngine = services:Get("UIEngine")
	local DOM = services:Get("DOM")

	local Dropdown = {}

	function Dropdown.new(
		parent: Instance,
		label: string,
		options: { string },
		defaultOrPath: any,
		callback: ((selected: string) -> ())?
	): DropdownHandle
		local isPath = typeof(defaultOrPath) == "string"
		local currentOptions = table.clone(options)
		local selectedOption: string = ""

		if isPath then
			selectedOption = tostring(StateStore:Get(defaultOrPath) or currentOptions[1] or "None")
		elseif typeof(defaultOrPath) == "string" and defaultOrPath ~= "" then
			selectedOption = defaultOrPath
		else
			selectedOption = currentOptions[1] or "None"
		end

		local container = DOM.Create("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Parent = parent,
		}, {
			DOM.Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }),
		}) :: Frame

		local headerRow = DOM.Create("Frame", {
			Size = UDim2.new(1, 0, 0, 38),
			BackgroundTransparency = 1,
			LayoutOrder = 1,
			Parent = container,
		}) :: Frame

		local titleLabel = DOM.Create("TextLabel", {
			Text = label,
			Font = Enum.Font.Code,
			TextSize = 11,
			TextColor3 = ThemeEngine:GetToken("Text"),
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 2, 0, 0),
			Size = UDim2.new(1, -4, 0, 14),
			Parent = headerRow,
		}) :: TextLabel

		local displayButton = DOM.Create("TextButton", {
			Text = string.format("%s  ▼", selectedOption),
			Font = Enum.Font.Code,
			TextSize = 11,
			TextColor3 = ThemeEngine:GetToken("TextDim"),
			BackgroundColor3 = ThemeEngine:GetToken("Elem"),
			BorderSizePixel = 0,
			Size = UDim2.new(1, -4, 0, 18),
			Position = UDim2.new(0, 2, 0, 16),
			AutoButtonColor = false,
			Parent = headerRow,
		}, {
			DOM.CreateStroke(ThemeEngine:GetToken("Border"), 1),
		}) :: TextButton

		local expansionFrame = DOM.Create("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 1,
			Visible = false,
			LayoutOrder = 2,
			Parent = container,
		}) :: Frame

		local listScroller = DOM.Create("ScrollingFrame", {
			Size = UDim2.new(1, -4, 1, 0),
			Position = UDim2.new(0, 2, 0, 0),
			BackgroundColor3 = ThemeEngine:GetToken("Elem"),
			BorderSizePixel = 0,
			ScrollBarThickness = 2,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Parent = expansionFrame,
		}, {
			DOM.CreateStroke(ThemeEngine:GetToken("Border"), 1),
			DOM.Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }),
		}) :: ScrollingFrame

		local isOpen = false
		local function setOpen(open: boolean)
			isOpen = open
			if open then
				local height = math.min(#currentOptions, 5) * 20 + 4
				expansionFrame.Size = UDim2.new(1, 0, 0, math.max(height, 24))
				expansionFrame.Visible = true
				displayButton.Text = string.format("%s  ▲", selectedOption)
			else
				expansionFrame.Visible = false
				expansionFrame.Size = UDim2.new(1, 0, 0, 0)
				displayButton.Text = string.format("%s  ▼", selectedOption)
			end
		end

		UIEngine:RegisterDropdownClose(function()
			if isOpen then setOpen(false) end
		end)

		local handle: DropdownHandle = {
			Instance = container,
			Set = nil :: any,
			Get = nil :: any,
			Refresh = nil :: any,
		}

		local function rebuildOptionButtons()
			for _, child in ipairs(listScroller:GetChildren()) do
				if child:IsA("TextButton") then child:Destroy() end
			end

			local items = #currentOptions > 0 and currentOptions or { "None" }
			for _, opt in ipairs(items) do
				local optBtn = DOM.Create("TextButton", {
					Text = "  " .. opt,
					Font = Enum.Font.Code,
					TextSize = 11,
					TextColor3 = (opt == selectedOption) and ThemeEngine:GetToken("Accent") or ThemeEngine:GetToken("Text"),
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 20),
					AutoButtonColor = false,
					Parent = listScroller,
				}) :: TextButton

				optBtn.MouseEnter:Connect(function()
					optBtn.BackgroundTransparency = 0
					optBtn.BackgroundColor3 = ThemeEngine:GetToken("ElemHover")
				end)
				optBtn.MouseLeave:Connect(function()
					optBtn.BackgroundTransparency = 1
				end)

				optBtn.MouseButton1Click:Connect(function()
					handle:Set(opt)
					setOpen(false)
				end)
			end
		end

		function handle:Set(option: string, silent: boolean?)
			selectedOption = option
			displayButton.Text = string.format("%s  ▼", selectedOption)

			if isPath then
				StateStore:Set(defaultOrPath, selectedOption)
			end

			rebuildOptionButtons()

			if not silent and callback then
				task.spawn(callback, selectedOption)
			end
		end

		function handle:Get(): string
			return selectedOption
		end

		if isPath then
			local function syncFromState()
				local hydratedOption = tostring(StateStore:Get(defaultOrPath) or currentOptions[1] or "None")
				if table.find(currentOptions, hydratedOption) then
					handle:Set(hydratedOption, true)
					if callback then task.spawn(callback, hydratedOption) end
				end
			end
			StateStore:Observe(defaultOrPath, function(newValue)
				if typeof(newValue) == "string" then handle:Set(newValue, true) end
			end)
			EventBus:Subscribe("StateHydrated", syncFromState)
		end
		
		function handle:Refresh(newOptions: { string }, preserveSelection: boolean?)
			currentOptions = table.clone(newOptions)
			if not preserveSelection or not table.find(currentOptions, selectedOption) then
				selectedOption = currentOptions[1] or "None"
			end
			displayButton.Text = string.format("%s  ▼", selectedOption)
			rebuildOptionButtons()
		end

		displayButton.MouseButton1Click:Connect(function()
			UIEngine:CloseAllDropdownsExcept(function() setOpen(false) end)
			setOpen(not isOpen)
		end)

		rebuildOptionButtons()
		return handle
	end

	return Dropdown
end
