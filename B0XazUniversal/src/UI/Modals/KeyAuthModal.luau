--!strict

return function(services: any)
	local Environment = services:Get("Environment")
	local ThemeEngine = services:Get("ThemeEngine")
	local KeyService = services:Get("KeyService")
	local DOM = services:Get("DOM")

	local KeyAuthModal = {}

	function KeyAuthModal:Show(onSuccess: (tier: number) -> (), initialError: string?)
		local parent = Environment.GetSafeGuiParent()

		local screenGui = DOM.Create("ScreenGui", {
			Name = DOM.GenerateGUID(),
			DisplayOrder = 10000,
			IgnoreGuiInset = true,
			ResetOnSpawn = false,
			Parent = parent,
		}) :: ScreenGui

		local backdrop = DOM.Create("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.45,
			BorderSizePixel = 0,
			Parent = screenGui,
		})

		local modalFrame = DOM.Create("Frame", {
			Size = UDim2.fromOffset(360, 220),
			Position = UDim2.new(0.5, -180, 0.5, -110),
			BackgroundColor3 = ThemeEngine:GetToken("Bg"),
			BorderSizePixel = 0,
			Parent = backdrop,
		}, {
			DOM.CreateStroke(ThemeEngine:GetToken("Border"), 1),
			DOM.Create("TextLabel", {
				Text = " Authentication Required",
				Font = Enum.Font.Code,
				TextSize = 13,
				TextColor3 = ThemeEngine:GetToken("Text"),
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -20, 0, 26),
				Position = UDim2.fromOffset(10, 10),
			}),
		}) :: Frame

		local statusLabel = DOM.Create("TextLabel", {
			Text = initialError or "Enter your access license key to continue.",
			Font = Enum.Font.Code,
			TextSize = 11,
			TextColor3 = initialError and ThemeEngine:GetToken("Danger") or ThemeEngine:GetToken("TextDim"),
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -20, 0, 32),
			Position = UDim2.fromOffset(10, 42),
			Parent = modalFrame,
		}) :: TextLabel

		local inputContainer = DOM.Create("Frame", {
			Size = UDim2.new(1, -20, 0, 30),
			Position = UDim2.fromOffset(10, 82),
			BackgroundColor3 = ThemeEngine:GetToken("Panel"),
			BorderSizePixel = 0,
			Parent = modalFrame,
		}, {
			DOM.CreateStroke(ThemeEngine:GetToken("Border"), 1),
		})

		local keyInput = DOM.Create("TextBox", {
			Text = "",
			PlaceholderText = "Paste access key here...",
			PlaceholderColor3 = ThemeEngine:GetToken("TextMuted"),
			TextColor3 = ThemeEngine:GetToken("Text"),
			Font = Enum.Font.Code,
			TextSize = 11,
			ClearTextOnFocus = false,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -12, 1, 0),
			Position = UDim2.fromOffset(6, 0),
			Parent = inputContainer,
		}) :: TextBox

		local authBtn = DOM.Create("TextButton", {
			Text = "Authenticate",
			Font = Enum.Font.Code,
			TextSize = 12,
			TextColor3 = Color3.new(0, 0, 0),
			BackgroundColor3 = ThemeEngine:GetToken("Accent"),
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(140, 32),
			Position = UDim2.new(0.5, -70, 0, 126),
			Parent = modalFrame,
		}) :: TextButton

		local getInfoBtn = DOM.Create("TextButton", {
			Text = "Get Access / Support Info",
			Font = Enum.Font.Code,
			TextSize = 10,
			TextColor3 = ThemeEngine:GetToken("TextDim"),
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 20),
			Position = UDim2.new(0, 0, 1, -26),
			Parent = modalFrame,
		}) :: TextButton

		getInfoBtn.MouseButton1Click:Connect(function()
			local ok, msg = KeyService:CopyInfo()
			statusLabel.Text = msg
			statusLabel.TextColor3 = ThemeEngine:GetToken("Success")
		end)

		-- Validation runs in a spawned thread so the modal stays responsive
		-- while the network request is in flight.
		local function submitAuth()
			local rawKey = keyInput.Text
			if rawKey == "" then
				statusLabel.Text = "Please enter a key."
				statusLabel.TextColor3 = ThemeEngine:GetToken("Danger")
				return
			end

			authBtn.Text = "Checking..."
			task.spawn(function()
				local verified, tier, msg = KeyService:AuthenticateKey(rawKey)
				if verified then
					screenGui:Destroy()
					onSuccess(tier)
				else
					authBtn.Text = "Authenticate"
					statusLabel.Text = msg or "License verification failed."
					statusLabel.TextColor3 = ThemeEngine:GetToken("Danger")
				end
			end)
		end

		authBtn.MouseButton1Click:Connect(submitAuth)
		keyInput.FocusLost:Connect(function(enterPressed)
			if enterPressed then submitAuth() end
		end)
	end

	return KeyAuthModal
end
