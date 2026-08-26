--!strict

export type ColorPickerHandle = {
	Set: (self: ColorPickerHandle, color: Color3, silent: boolean?) -> (),
	Get: (self: ColorPickerHandle) -> Color3,
	Instance: Frame,
}

local PRESET_PALETTE = {
	Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0), Color3.fromRGB(255, 50, 50),
	Color3.fromRGB(255, 150, 50), Color3.fromRGB(255, 230, 50), Color3.fromRGB(50, 255, 80),
	Color3.fromRGB(0, 200, 220), Color3.fromRGB(80, 80, 255), Color3.fromRGB(200, 80, 255),
	Color3.fromRGB(255, 80, 180),
}

return function(services: any)
	local ThemeEngine = services:Get("ThemeEngine")
	local StateStore = services:Get("StateStore")
	local EventBus = services:Get("EventBus")
	local UIEngine = services:Get("UIEngine")
	local DOM = services:Get("DOM")

	local ColorPicker = {}

	-- A string defaultOrPath is a StateStore path, a Color3 is a literal
	function ColorPicker.new(
		parent: Instance,
		label: string,
		defaultOrPath: any,
		callback: ((color: Color3) -> ())?
	): ColorPickerHandle
		local isPath = typeof(defaultOrPath) == "string"
		local currentColor = Color3.fromRGB(255, 255, 255)

		if isPath then
			currentColor = StateStore:Get(defaultOrPath) or currentColor
		elseif typeof(defaultOrPath) == "Color3" then
			currentColor = defaultOrPath
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
			Size = UDim2.new(1, 0, 0, 22),
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
			Size = UDim2.new(1, -30, 1, 0),
			Parent = headerRow,
		}) :: TextLabel

		local swatchButton = DOM.Create("TextButton", {
			Text = "",
			Size = UDim2.fromOffset(18, 12),
			Position = UDim2.new(1, -20, 0.5, -6),
			BackgroundColor3 = currentColor,
			BorderSizePixel = 0,
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

		local paletteGrid = DOM.Create("Frame", {
			Size = UDim2.new(1, -4, 1, 0),
			Position = UDim2.new(0, 2, 0, 0),
			BackgroundColor3 = ThemeEngine:GetToken("Elem"),
			BorderSizePixel = 0,
			Parent = expansionFrame,
		}, {
			DOM.CreateStroke(ThemeEngine:GetToken("Border"), 1),
			DOM.Create("UIGridLayout", {
				CellSize = UDim2.fromOffset(18, 18),
				CellPadding = UDim2.fromOffset(3, 3),
			}),
			DOM.CreatePadding(4),
		}) :: Frame

		local isOpen = false
		local function setOpen(open: boolean)
			isOpen = open
			expansionFrame.Visible = open
			expansionFrame.Size = open and UDim2.new(1, 0, 0, 48) or UDim2.new(1, 0, 0, 0)
		end

		-- The guard keeps the shared close-all sweep from touching a picker
		-- whose GUI has already been destroyed.
		UIEngine:RegisterDropdownClose(function()
			if isOpen and expansionFrame.Parent then setOpen(false) end
		end)

		local handle: ColorPickerHandle = {
			Instance = container,
			Set = nil :: any,
			Get = nil :: any,
		}

		function handle:Set(color: Color3, silent: boolean?)
			currentColor = color
			swatchButton.BackgroundColor3 = color

			if isPath then
				StateStore:Set(defaultOrPath, currentColor)
			end

			if not silent and callback then
				task.spawn(callback, currentColor)
			end
		end

		function handle:Get(): Color3
			return currentColor
		end

		if isPath then
			local function syncFromState()
				local hydratedColor = StateStore:Get(defaultOrPath)
				if typeof(hydratedColor) == "Color3" then
					handle:Set(hydratedColor, true)
					if callback then task.spawn(callback, hydratedColor) end
				end
			end
			StateStore:Observe(defaultOrPath, function(newValue)
				if typeof(newValue) == "Color3" then handle:Set(newValue, true) end
			end)
			EventBus:Subscribe("StateHydrated", syncFromState)
		end

		for _, col in ipairs(PRESET_PALETTE) do
			local cell = DOM.Create("TextButton", {
				Text = "",
				BackgroundColor3 = col,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Parent = paletteGrid,
			}, {
				DOM.CreateStroke(ThemeEngine:GetToken("BorderDim"), 1),
			}) :: TextButton

			cell.MouseButton1Click:Connect(function()
				handle:Set(col)
				setOpen(false)
			end)
		end

		swatchButton.MouseButton1Click:Connect(function()
			UIEngine:CloseAllDropdownsExcept(function() setOpen(false) end)
			setOpen(not isOpen)
		end)

		return handle
	end

	return ColorPicker
end
