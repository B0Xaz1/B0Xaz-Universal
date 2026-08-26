--!strict
-- ══════════════════════════════════════════════════════════════════════════════
-- B0XazUniversal - Textbox & Action Button Component Factories
-- Encapsulates text inputs, clear on focus options, sanitize hooks,
-- and styled section action buttons.
-- ══════════════════════════════════════════════════════════════════════════════

export type TextboxHandle = {
	Set: (self: TextboxHandle, text: string) -> (),
	Get: (self: TextboxHandle) -> string,
	Instance: Frame,
}

return function(services: any)
	local ThemeEngine = services:Get("ThemeEngine")
	local StateStore = services:Get("StateStore")
	local DOM = services:Get("DOM")

	local Components = {}

	function Components.CreateTextbox(
		parent: Instance,
		label: string,
		defaultOrPath: any,
		placeholder: string?,
		callback: ((text: string, enterPressed: boolean) -> ())?
	): TextboxHandle
		local isPath = typeof(defaultOrPath) == "string"
		local currentText = ""

		if isPath then
			currentText = tostring(StateStore:Get(defaultOrPath) or "")
		elseif typeof(defaultOrPath) == "string" then
			currentText = defaultOrPath
		end

		local container = DOM.Create("Frame", {
			Size = UDim2.new(1, 0, 0, 38),
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
			Size = UDim2.new(1, -4, 0, 14),
			Parent = container,
		}) :: TextLabel

		local boxBg = DOM.Create("Frame", {
			Size = UDim2.new(1, -4, 0, 18),
			Position = UDim2.new(0, 2, 0, 16),
			BackgroundColor3 = ThemeEngine:GetToken("Elem"),
			BorderSizePixel = 0,
			Parent = container,
		}, {
			DOM.CreateStroke(ThemeEngine:GetToken("Border"), 1),
		})

		local textBox = DOM.Create("TextBox", {
			Text = currentText,
			PlaceholderText = placeholder or "",
			Font = Enum.Font.Code,
			TextSize = 11,
			TextColor3 = ThemeEngine:GetToken("Text"),
			PlaceholderColor3 = ThemeEngine:GetToken("TextMuted"),
			ClearTextOnFocus = false,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -8, 1, 0),
			Position = UDim2.fromOffset(4, 0),
			Parent = boxBg,
		}) :: TextBox

		local handle: TextboxHandle = {
			Instance = container,
			Set = nil :: any,
			Get = nil :: any,
		}

		function handle:Set(text: string)
			currentText = text
			textBox.Text = text
			if isPath then
				StateStore:Set(defaultOrPath, currentText)
			end
		end

		function handle:Get(): string
			return textBox.Text
		end

		textBox.FocusLost:Connect(function(enter)
			currentText = textBox.Text
			if isPath then
				StateStore:Set(defaultOrPath, currentText)
			end
			if callback then
				task.spawn(callback, currentText, enter)
			end
		end)

		return handle
	end

	function Components.CreateButton(
		parent: Instance,
		name: string,
		callback: () -> (),
		requiredTier: number?
	): TextButton?
		local tier = requiredTier or 0
		if tier > StateStore:GetTier() then return nil end

		local container = DOM.Create("Frame", {
			Size = UDim2.new(1, 0, 0, 24),
			BackgroundTransparency = 1,
			Parent = parent,
		}) :: Frame

		local btn = DOM.Create("TextButton", {
			Text = name,
			Font = Enum.Font.Code,
			TextSize = 11,
			TextColor3 = ThemeEngine:GetToken("Text"),
			BackgroundColor3 = ThemeEngine:GetToken("Elem"),
			BorderSizePixel = 0,
			Size = UDim2.new(1, -4, 0, 20),
			Position = UDim2.new(0, 2, 0, 2),
			AutoButtonColor = false,
			Parent = container,
		}, {
			DOM.CreateStroke(ThemeEngine:GetToken("Border"), 1),
		}) :: TextButton

		btn.MouseEnter:Connect(function()
			btn.BackgroundColor3 = ThemeEngine:GetToken("ElemHover")
			btn.TextColor3 = ThemeEngine:GetToken("Accent")
		end)
		btn.MouseLeave:Connect(function()
			btn.BackgroundColor3 = ThemeEngine:GetToken("Elem")
			btn.TextColor3 = ThemeEngine:GetToken("Text")
		end)

		btn.MouseButton1Click:Connect(function()
			task.spawn(callback)
		end)

		return btn
	end

	return Components
end
