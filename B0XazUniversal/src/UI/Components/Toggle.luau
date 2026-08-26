--!strict
-- ══════════════════════════════════════════════════════════════════════════════
-- B0XazUniversal - Reactive Toggle Component
-- Automatically binds to StateStore paths or standalone boolean states,
-- supports tier permission gating, and features reactive theme transitions.
-- ══════════════════════════════════════════════════════════════════════════════

export type ToggleHandle = {
	Set: (self: ToggleHandle, value: boolean, silent: boolean?) -> (),
	Get: (self: ToggleHandle) -> boolean,
	Instance: Frame,
}

return function(services: any)
	local ThemeEngine = services:Get("ThemeEngine")
	local StateStore = services:Get("StateStore")
	local EventBus = services:Get("EventBus")
	local DOM = services:Get("DOM")

	local Toggle = {}

	function Toggle.new(
		parent: Instance,
		label: string,
		statePathOrInit: any,
		callback: ((value: boolean) -> ())?,
		requiredTier: number?
	): ToggleHandle
		local tier = requiredTier or 0
		local isPath = typeof(statePathOrInit) == "string"
		local currentState: boolean = false

		if isPath then
			currentState = StateStore:Get(statePathOrInit) == true
		elseif typeof(statePathOrInit) == "boolean" then
			currentState = statePathOrInit
		end

		local container = DOM.Create("Frame", {
			Size = UDim2.new(1, 0, 0, 22),
			BackgroundTransparency = 1,
			Parent = parent,
		}) :: Frame

		local indicatorBox = DOM.Create("Frame", {
			Size = UDim2.fromOffset(12, 12),
			Position = UDim2.new(0, 2, 0.5, -6),
			BackgroundColor3 = currentState and ThemeEngine:GetToken("ToggleOn") or ThemeEngine:GetToken("ToggleOff"),
			BorderSizePixel = 0,
			Parent = container,
		}, {
			DOM.CreateStroke(ThemeEngine:GetToken("Border"), 1),
		}) :: Frame

		local titleLabel = DOM.Create("TextLabel", {
			Text = label,
			Font = Enum.Font.Code,
			TextSize = 11,
			TextColor3 = ThemeEngine:GetToken("Text"),
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 22, 0, 0),
			Size = UDim2.new(1, -24, 1, 0),
			Parent = container,
		}) :: TextLabel

		ThemeEngine:BindToken(titleLabel, "TextColor3", "Text")

		local clickButton = DOM.Create("TextButton", {
			Text = "",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Parent = container,
		}) :: TextButton

		local handle: ToggleHandle = {
			Instance = container,
			Set = nil :: any,
			Get = nil :: any,
		}

		local function updateVisuals(active: boolean)
			indicatorBox.BackgroundColor3 = active and ThemeEngine:GetToken("ToggleOn") or ThemeEngine:GetToken("ToggleOff")
		end

		function handle:Set(value: boolean, silent: boolean?)
			if tier > StateStore:GetTier() and value == true then
				return
			end

			currentState = value
			updateVisuals(currentState)

			if isPath then
				StateStore:Set(statePathOrInit, currentState)
			end

			if not silent and callback then
				task.spawn(callback, currentState)
			end
		end

		function handle:Get(): boolean
			return currentState
		end

		clickButton.MouseButton1Click:Connect(function()
			handle:Set(not currentState)
		end)

		-- Observe reactive state path if provided
		if isPath then
			StateStore:Observe(statePathOrInit, function(newVal)
				if newVal ~= currentState then
					currentState = newVal == true
					updateVisuals(currentState)
				end
			end)
		end

		EventBus:Subscribe("ThemeUpdated", function()
			updateVisuals(currentState)
		end)

		return handle
	end

	return Toggle
end
