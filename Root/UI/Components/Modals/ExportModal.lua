-- ════════════════════════════════════════════════════════════════════════════
-- UI/Components/Modals/ExportModal.lua
-- Modal JSON profile viewer and clipboard exporter
-- ════════════════════════════════════════════════════════════════════════════

local DOM = require(script.Parent.Parent.Parent.DOM)

local ExportModal = {}
ExportModal.__index = ExportModal

function ExportModal.Show(jsonString, themeEngine)
	local safeParent = DOM.GetSafeParent()

	local gui = DOM.Create("ScreenGui", {
		Name = DOM.RandomName(),
		DisplayOrder = 10001,
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		Parent = safeParent,
	})

	local backdrop = DOM.Create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		Parent = gui,
	})

	local card = DOM.Create("Frame", {
		Size = UDim2.fromOffset(440, 300),
		Position = UDim2.new(0.5, -220, 0.5, -150),
		BackgroundColor3 = themeEngine.Current.Bg,
		BorderSizePixel = 0,
		Parent = backdrop,
	}, {
		DOM.CreateStroke(themeEngine.Current.Border, 1),
	})

	DOM.Create("TextLabel", {
		Text = "Configuration JSON Data",
		Font = Enum.Font.Code,
		TextSize = 13,
		TextColor3 = themeEngine.Current.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 10),
		Size = UDim2.new(1, -50, 0, 20),
		Parent = card,
	})

	local closeBtn = DOM.Create("TextButton", {
		Size = UDim2.fromOffset(20, 20),
		Position = UDim2.new(1, -28, 0, 10),
		BackgroundTransparency = 1,
		Text = "x",
		Font = Enum.Font.Code,
		TextSize = 13,
		TextColor3 = themeEngine.Current.TextDim,
		Parent = card,
	})
	closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

	local scroll = DOM.Create("ScrollingFrame", {
		Size = UDim2.new(1, -24, 0, 200),
		Position = UDim2.fromOffset(12, 40),
		BackgroundColor3 = themeEngine.Current.Panel,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = themeEngine.Current.Accent,
		AutomaticCanvasSize = Enum.AutomaticSize.XY,
		Parent = card,
	}, {
		DOM.CreateStroke(themeEngine.Current.BorderDim, 1),
		DOM.CreatePadding(6),
	})

	local textBox = DOM.Create("TextBox", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = Enum.Font.Code,
		TextSize = 11,
		Text = jsonString or "",
		TextColor3 = themeEngine.Current.Text,
		ClearTextOnFocus = false,
		TextWrapped = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = scroll,
	})

	local copyBtn = DOM.Create("TextButton", {
		Size = UDim2.new(1, -24, 0, 30),
		Position = UDim2.new(0, 12, 1, -40),
		BackgroundColor3 = themeEngine.Current.Accent,
		BorderSizePixel = 0,
		Text = "Copy to Clipboard",
		Font = Enum.Font.Code,
		TextSize = 11,
		TextColor3 = Color3.new(0, 0, 0),
		Parent = card,
	})

	copyBtn.MouseButton1Click:Connect(function()
		if setclipboard then
			pcall(setclipboard, textBox.Text)
			copyBtn.Text = "Copied!"
			task.delay(1.5, function()
				if copyBtn and copyBtn.Parent then copyBtn.Text = "Copy to Clipboard" end
			end)
		end
	end)
end

return ExportModal
