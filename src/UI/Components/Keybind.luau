local UserInputService = game:GetService("UserInputService")

export type KeybindHandle = {
	Set: (self: KeybindHandle, bind: any, silent: boolean?) -> (),
	Get: (self: KeybindHandle) -> any,
	Instance: Frame,
}

-- Only one component can capture input at a time; the active handler takes
-- the next matching key and is then cleared.
local activeCaptureHandler: ((any) -> ())? = nil
local captureConnection: RBXScriptConnection? = nil

return function(services: any)
	local ThemeEngine = services:Get("ThemeEngine")
	local StateStore = services:Get("StateStore")
	local EventBus = services:Get("EventBus")
	local Environment = services:Get("Environment")
	local Disposer = services:Get("Disposer")
	local DOM = services:Get("DOM")

	-- The capture listener is created once per factory instance and released
	-- with the disposer so repeated suite loads do not stack listeners.
	local function ensureCaptureListener()
		if not captureConnection or not captureConnection.Connected then
			captureConnection = UserInputService.InputBegan:Connect(function(input)
				if not activeCaptureHandler then return end
				local boundInput: any = nil
				local shouldFinalize = false

				if input.UserInputType == Enum.UserInputType.Keyboard then
					-- Escape cancels capture and unbinds the key
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
			Disposer:Add(captureConnection)
		end
	end

	local Keybind = {}

	function Keybind.new(
		parent: Instance,
		label: string,
		defaultOrPath: any,
		callback: ((bound: any) -> ())?
	): KeybindHandle
		ensureCaptureListener()

		-- Any string is treated as a StateStore path; pass nil for "no bind"
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
			-- The global "binding key" flag pauses the menu/unload hotkeys so
			-- pressing a candidate key cannot toggle the UI mid-capture.
			StateStore:SetTransient("IsBindingKey", true)
			bindButton.Text = "..."
			bindButton.TextColor3 = ThemeEngine:GetToken("Accent")

			task.defer(function()
				activeCaptureHandler = function(newBound)
					StateStore:SetTransient("IsBindingKey", false)
					handle:Set(newBound)
				end
			end)
		end)

		return handle
	end

	return Keybind
end
