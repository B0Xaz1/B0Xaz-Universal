--!strict
-- ══════════════════════════════════════════════════════════════════════════════
-- B0XazUniversal - Keybind & Input Capture Component
-- Captures keyboard inputs and mouse buttons, sets global binding states,
-- and integrates with Environment keycode formatters.
-- ══════════════════════════════════════════════════════════════════════════════

local UserInputService = game:GetService("UserInputService")

export type KeybindHandle = {
	Set: (self: KeybindHandle, bind: any, silent: boolean?) -> (),
	Get: (self: KeybindHandle) -> any,
	Instance: Frame,
}

local activeCaptureHandler: ((any) -> ())? = nil

UserInputService.InputBegan:Connect(function(input)
	if not activeCaptureHandler then return end
	local boundInput: any = nil
	local shouldFinalize = false

	if input.UserInputType == Enum.UserInputType.Keyboard then
		boundInput = (input.KeyCode == Enum.KeyCode.Escape) and nil or input.KeyCode
		shouldFinalize = true
	elseif input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.MouseButton2
		or input.UserInputType == Enum.UserInputType.MouseButton3 then
		boundInput = input.UserInputType
		shouldFinalize = true
	end

	if shouldFinalize then
		local handler = activeCaptureHandler
		activeCaptureHandler = nil
		handler(boundInput)
	end
end)

return function(services: any)
	local ThemeEngine = services:Get("ThemeEngine")
	local StateStore = services:Get("StateStore")
	local EventBus = services:Get("EventBus")
	local Environment = services:Get("Environment")
	local DOM = services:Get("DOM")

	local Keybind = {}

	function Keybind.new(
		parent: Instance,
		label: string,
		defaultOrPath: any,
		callback: ((bound: any) -> ())?
	): KeybindHandle
		local isPath = typeof(defaultOrPath) == "string"
		local currentBind: any = nil

		if isPath then
			currentBind = StateStore:Get(defaultOrPath)
		else
			currentBind = defaultOrPath
		end

		local container = DOM.Create("Frame", {
			Size = UDim2.new(1, 0, 0, 22),
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
			Size = UDim2.new(1, -64, 1, 0),
			Parent = container,
		}) :: TextLabel

		local bindButton = DOM.Create("TextButton", {
			Text = Environment.FormatKeybindName(currentBind),
			Font = Enum.Font.Code,
			TextSize = 10,
			TextColor3 = ThemeEngine:GetToken("Text"),
			BackgroundColor3 = ThemeEngine:GetToken("Elem"),
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(56, 16),
			Position = UDim2.new(1, -58, 0.5, -8),
			AutoButtonColor = false,
			Parent = container,
		}, {
			DOM.CreateStroke(ThemeEngine:GetToken("Border"), 1),
		}) :: TextButton

		local handle: KeybindHandle = {
			Instance = container,
			Set = nil :: any,
			Get = nil :: any,
		}

		function handle:Set(bind: any, silent: boolean?)
			currentBind = bind
			bindButton.Text = Environment.FormatKeybindName(currentBind)
			bindButton.TextColor3 = ThemeEngine:GetToken("Text")

			if isPath then
				StateStore:Set(defaultOrPath, currentBind)
			end

			if not silent and callback then
				task.spawn(callback, currentBind)
			end
		end

		function handle:Get(): any
			return currentBind
		end

		if isPath then
			local function syncFromState()
				local hydratedBind = StateStore:Get(defaultOrPath)
				if hydratedBind ~= nil then handle:Set(hydratedBind, true) end
			end
			StateStore:Observe(defaultOrPath, function(newValue)
				if newValue ~= nil then handle:Set(newValue, true) end
			end)
			EventBus:Subscribe("StateHydrated", syncFromState)
		end
		
		bindButton.MouseButton1Click:Connect(function()
			StateStore:SetTransient("IsBindingKey", true)
			bindButton.Text = "..."
			bindButton.TextColor3 = ThemeEngine:GetToken("Accent")

			activeCaptureHandler = function(newBound)
				StateStore:SetTransient("IsBindingKey", false)
				handle:Set(newBound)
			end
		end)

		return handle
	end

	return Keybind
end
