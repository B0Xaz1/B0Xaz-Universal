--!strict
-- ══════════════════════════════════════════════════════════════════════════════
-- B0XazUniversal - Two-Way Config Sharing Modal
-- Supports direct JSON payload viewing, clipboard copying, and live JSON parsing
-- to import external configurations directly into the suite.
-- ══════════════════════════════════════════════════════════════════════════════

return function(services: any)
	local Environment = services:Get("Environment")
	local ThemeEngine = services:Get("ThemeEngine")
	local ConfigService = services:Get("ConfigService")
	local UIEngine = services:Get("UIEngine")
	local DOM = services:Get("DOM")

	local ConfigShareModal = {}

	function ConfigShareModal:Show(initialJson: string?)
		local parent = Environment.GetSafeGuiParent()

		local screenGui = DOM.Create("ScreenGui", {
			Name = DOM.GenerateGUID(),
			DisplayOrder = 10001,
			IgnoreGuiInset = true,
			ResetOnSpawn = false,
			Parent = parent,
		}) :: ScreenGui

		local backdrop = DOM.Create("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
			Parent = screenGui,
		})

		local modalFrame = DOM.Create("Frame", {
			Size = UDim2.fromOffset(460, 320),
			Position = UDim2.new(0.5, -230, 0.5, -160),
			BackgroundColor3 = ThemeEngine:GetToken("Bg"),
			BorderSizePixel = 0,
			Parent = backdrop,
		}, {
			DOM.CreateStroke(ThemeEngine:GetToken("Border"), 1),
			DOM.Create("TextLabel", {
				Text = " Configuration Data (JSON)",
				Font = Enum.Font.Code,
				TextSize = 13,
				TextColor3 = ThemeEngine:GetToken("Text"),
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -40, 0, 28),
				Position = UDim2.fromOffset(10, 8),
			}),
		}) :: Frame

		local closeBtn = DOM.Create("TextButton", {
			Text = "✕",
			Font = Enum.Font.Code,
			TextSize = 13,
			TextColor3 = ThemeEngine:GetToken("TextDim"),
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(28, 28),
			Position = UDim2.new(1, -28, 0, 8),
			Parent = modalFrame,
		}) :: TextButton
		closeBtn.MouseButton1Click:Connect(function()
			screenGui:Destroy()
		end)

		local scrollContainer = DOM.Create("ScrollingFrame", {
			Size = UDim2.new(1, -20, 0, 200),
			Position = UDim2.fromOffset(10, 42),
			BackgroundColor3 = ThemeEngine:GetToken("Panel"),
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			AutomaticCanvasSize = Enum.AutomaticSize.XY,
			Parent = modalFrame,
		}, {
			DOM.CreateStroke(ThemeEngine:GetToken("Border"), 1),
			DOM.CreatePadding(6),
		}) :: ScrollingFrame

		local textBox = DOM.Create("TextBox", {
			Text = initialJson or "",
			PlaceholderText = "Paste configuration JSON string here to import...",
			PlaceholderColor3 = ThemeEngine:GetToken("TextMuted"),
			TextColor3 = ThemeEngine:GetToken("Text"),
			Font = Enum.Font.Code,
			TextSize = 11,
			ClearTextOnFocus = false,
			TextWrapped = false,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Parent = scrollContainer,
		}) :: TextBox

		local btnContainer = DOM.Create("Frame", {
			Size = UDim2.new(1, -20, 0, 32),
			Position = UDim2.fromOffset(10, 252),
			BackgroundTransparency = 1,
			Parent = modalFrame,
		}, {
			DOM.Create("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		})

		-- Copy Button
		local copyBtn = DOM.Create("TextButton", {
			Text = "Copy JSON to Clipboard",
			Font = Enum.Font.Code,
			TextSize = 11,
			TextColor3 = Color3.new(0, 0, 0),
			BackgroundColor3 = ThemeEngine:GetToken("Accent"),
			BorderSizePixel = 0,
			Size = UDim2.new(0.5, -4, 1, 0),
			Parent = btnContainer,
		}) :: TextButton

		copyBtn.MouseButton1Click:Connect(function()
			if textBox.Text ~= "" then
				Environment.SetClipboard(textBox.Text)
				copyBtn.Text = "Copied!"
				task.delay(1.5, function()
					if copyBtn and copyBtn.Parent then
						copyBtn.Text = "Copy JSON to Clipboard"
					end
				end)
			end
		end)

		-- Apply / Import Button
		local importBtn = DOM.Create("TextButton", {
			Text = "Import & Apply JSON",
			Font = Enum.Font.Code,
			TextSize = 11,
			TextColor3 = ThemeEngine:GetToken("Text"),
			BackgroundColor3 = ThemeEngine:GetToken("Elem"),
			BorderSizePixel = 0,
			Size = UDim2.new(0.5, -4, 1, 0),
			Parent = btnContainer,
		}, {
			DOM.CreateStroke(ThemeEngine:GetToken("Border"), 1),
		}) :: TextButton

		importBtn.MouseButton1Click:Connect(function()
			local ok, err = ConfigService:Import(textBox.Text)
			if ok then
				UIEngine:Notify("Config", "Configuration applied successfully.", 2.5, ThemeEngine:GetToken("Success"))
				screenGui:Destroy()
			else
				UIEngine:Notify("Import Failed", err or "Invalid JSON", 3, ThemeEngine:GetToken("Danger"))
			end
		end)
	end

	return ConfigShareModal
end
