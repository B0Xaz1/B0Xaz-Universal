-- ════════════════════════════════════════════════════════════════════════════
-- UI/Components/Modals/AuthModal.lua
-- Fullscreen modal license authentication prompt
-- ════════════════════════════════════════════════════════════════════════════

local DOM = require(script.Parent.Parent.Parent.DOM)

local AuthModal = {}
AuthModal.__index = AuthModal

function AuthModal.Show(authService, themeEngine, onSuccess)
	local safeParent = DOM.GetSafeParent()

	local gui = DOM.Create("ScreenGui", {
		Name = DOM.RandomName(),
		DisplayOrder = 10000,
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
		Size = UDim2.fromOffset(360, 220),
		Position = UDim2.new(0.5, -180, 0.5, -110),
		BackgroundColor3 = themeEngine.Current.Bg,
		BorderSizePixel = 0,
		Parent = backdrop,
	}, {
		DOM.CreateStroke(themeEngine.Current.Border, 1),
	})

	DOM.Create("TextLabel", {
		Text = "Authentication Required",
		Font = Enum.Font.Code,
		TextSize = 14,
		TextColor3 = themeEngine.Current.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 14),
		Size = UDim2.new(1, -28, 0, 20),
		Parent = card,
	})

	local statusLabel = DOM.Create("TextLabel", {
		Text = "Enter your license key to initialize suite.",
		Font = Enum.Font.Code,
		TextSize = 11,
		TextColor3 = themeEngine.Current.TextDim,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 40),
		Size = UDim2.new(1, -28, 0, 30),
		Parent = card,
	})

	local inputBg = DOM.Create("Frame", {
		Size = UDim2.new(1, -28, 0, 32),
		Position = UDim2.fromOffset(14, 80),
		BackgroundColor3 = themeEngine.Current.Panel,
		BorderSizePixel = 0,
		Parent = card,
	}, {
		DOM.CreateStroke(themeEngine.Current.BorderDim, 1),
	})

	local textBox = DOM.Create("TextBox", {
		Size = UDim2.new(1, -12, 1, 0),
		Position = UDim2.fromOffset(6, 0),
		Font = Enum.Font.Code,
		TextSize = 12,
		TextColor3 = themeEngine.Current.Text,
		PlaceholderText = "Paste access key token here...",
		PlaceholderColor3 = themeEngine.Current.TextMuted,
		BackgroundTransparency = 1,
		ClearTextOnFocus = false,
		Parent = inputBg,
	})

	local submitBtn = DOM.Create("TextButton", {
		Size = UDim2.fromOffset(140, 32),
		Position = UDim2.new(0.5, -70, 0, 126),
		BackgroundColor3 = themeEngine.Current.Accent,
		BorderSizePixel = 0,
		Text = "Authenticate",
		Font = Enum.Font.Code,
		TextSize = 12,
		TextColor3 = Color3.new(0, 0, 0),
		AutoButtonColor = true,
		Parent = card,
	})

	local supportBtn = DOM.Create("TextButton", {
		Size = UDim2.new(1, -28, 0, 20),
		Position = UDim2.new(0, 14, 1, -28),
		BackgroundTransparency = 1,
		Text = "Copy Key Info Link",
		Font = Enum.Font.Code,
		TextSize = 10,
		TextColor3 = themeEngine.Current.TextDim,
		Parent = card,
	})

	local function submit()
		submitBtn.Text = "Checking..."
		task.wait(0.05)
		local ok, _, msg = authService:ApplyKey(textBox.Text)
		if ok then
			gui:Destroy()
			if onSuccess then task.spawn(onSuccess) end
		else
			submitBtn.Text = "Authenticate"
			statusLabel.Text = msg or "Invalid Key"
			statusLabel.TextColor3 = themeEngine.Current.Danger
		end
	end

	submitBtn.MouseButton1Click:Connect(submit)
	textBox.FocusLost:Connect(function(enter) if enter then submit() end end)

	supportBtn.MouseButton1Click:Connect(function()
		if setclipboard then
			setclipboard("Contact suite administrator for an access token.")
			statusLabel.Text = "Support info copied to clipboard."
			statusLabel.TextColor3 = themeEngine.Current.Success
		end
	end)
end

return AuthModal
