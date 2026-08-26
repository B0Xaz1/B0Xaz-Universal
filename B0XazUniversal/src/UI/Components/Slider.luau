--!strict

local UserInputService = game:GetService("UserInputService")

export type SliderHandle = {
	Set: (self: SliderHandle, value: number, silent: boolean?) -> (),
	Get: (self: SliderHandle) -> number,
	Instance: Frame,
}

return function(services: any)
	local ThemeEngine = services:Get("ThemeEngine")
	local StateStore = services:Get("StateStore")
	local EventBus = services:Get("EventBus")
	local Disposer = services:Get("Disposer")
	local DOM = services:Get("DOM")

	local Slider = {}

	-- A number defaultOrPath is a literal value, a string is a StateStore path
	function Slider.new(
		parent: Instance,
		label: string,
		min: number,
		max: number,
		defaultOrPath: any,
		step: number?,
		suffix: string?,
		callback: ((value: number) -> ())?
	): SliderHandle
		local isPath = typeof(defaultOrPath) == "string"
		local stepSize = step or 1
		local unitSuffix = suffix or ""
		local currentValue = min

		if isPath then
			currentValue = tonumber(StateStore:Get(defaultOrPath)) or min
		elseif typeof(defaultOrPath) == "number" then
			currentValue = defaultOrPath
		end

		currentValue = math.clamp(currentValue, min, max)

		local container = DOM.Create("Frame", {
			Size = UDim2.new(1, 0, 0, 36),
			BackgroundTransparency = 1,
			Parent = parent,
		}) :: Frame

		local titleLabel = DOM.Create("TextLabel", {
			Text = label,
			Font = Enum.Font.Code,
			TextSize = 11,
			TextColor3 = ThemeEngine:GetToken("Text"),
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 2, 0, 0),
			Size = UDim2.new(1, -70, 0, 14),
			Parent = container,
		}) :: TextLabel

		local valueLabel = DOM.Create("TextLabel", {
			Text = string.format("%s%s", tostring(currentValue), unitSuffix),
			Font = Enum.Font.Code,
			TextSize = 10,
			TextColor3 = ThemeEngine:GetToken("TextDim"),
			TextXAlignment = Enum.TextXAlignment.Right,
			BackgroundTransparency = 1,
			Position = UDim2.new(1, -66, 0, 0),
			Size = UDim2.new(0, 64, 0, 14),
			Parent = container,
		}) :: TextLabel

		local trackFrame = DOM.Create("Frame", {
			Size = UDim2.new(1, -4, 0, 4),
			Position = UDim2.new(0, 2, 0, 22),
			BackgroundColor3 = ThemeEngine:GetToken("Elem"),
			BorderSizePixel = 0,
			Parent = container,
		}, {
			DOM.CreateStroke(ThemeEngine:GetToken("BorderDim"), 1),
		}) :: Frame

		local initialFraction = math.clamp((currentValue - min) / math.max(max - min, 1e-6), 0, 1)

		local fillBar = DOM.Create("Frame", {
			Size = UDim2.new(initialFraction, 0, 1, 0),
			BackgroundColor3 = ThemeEngine:GetToken("Accent"),
			BorderSizePixel = 0,
			Parent = trackFrame,
		}) :: Frame

		ThemeEngine:BindToken(trackFrame, "BackgroundColor3", "Elem")
		ThemeEngine:BindToken(fillBar, "BackgroundColor3", "Accent")

		local handle: SliderHandle = {
			Instance = container,
			Set = nil :: any,
			Get = nil :: any,
		}

		-- The silent flag breaks the observe/set feedback loop: state-driven
		-- updates redraw the bar without writing the same value back.
		local function applyValue(val: number, silent: boolean?)
			local clamped = math.clamp(val, min, max)
			if stepSize > 0 then
				clamped = math.floor((clamped - min) / stepSize + 0.5) * stepSize + min
			end

			currentValue = math.clamp(clamped, min, max)
			local fraction = math.clamp((currentValue - min) / math.max(max - min, 1e-6), 0, 1)

			fillBar.Size = UDim2.new(fraction, 0, 1, 0)
			valueLabel.Text = string.format("%s%s", tostring(currentValue), unitSuffix)

			if isPath then
				StateStore:Set(defaultOrPath, currentValue)
			end

			if not silent and callback then
				task.spawn(callback, currentValue)
			end
		end

		function handle:Set(val: number, silent: boolean?)
			applyValue(val, silent)
		end

		function handle:Get(): number
			return currentValue
		end

		if isPath then
			StateStore:Observe(defaultOrPath, function(newValue)
				applyValue(tonumber(newValue) or min, true)
			end)
			EventBus:Subscribe("StateHydrated", function()
				applyValue(tonumber(StateStore:Get(defaultOrPath)) or min, true)
				if callback then task.spawn(callback, currentValue) end
			end)
		end

		local dragging = false

		local function updateFromX(absoluteX: number)
			-- Absolute screen coordinates are mapped onto the track's current
			-- on-screen rect, so window dragging does not offset the mapping.
			local trackX = trackFrame.AbsolutePosition.X
			local trackWidth = math.max(trackFrame.AbsoluteSize.X, 1)
			local relFraction = math.clamp((absoluteX - trackX) / trackWidth, 0, 1)
			local rawValue = min + (max - min) * relFraction
			applyValue(rawValue)
		end

		local hitButton = DOM.Create("TextButton", {
			Text = "",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 16),
			Position = UDim2.new(0, 0, 0, 16),
			Parent = container,
		}) :: TextButton

		hitButton.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				updateFromX(input.Position.X)
			end
		end)

		local dragEnded = UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
		Disposer:Add(dragEnded)

		local dragChanged = UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				updateFromX(input.Position.X)
			end
		end)
		Disposer:Add(dragChanged)

		return handle
	end

	return Slider
end
