--!strict
-- ══════════════════════════════════════════════════════════════════════════════
-- B0XazUniversal - Settings & Profile Manager UI Tab
-- Profile persistence, configuration export/import, reactive theme selector,
-- custom token palette pickers, and license status.
-- ══════════════════════════════════════════════════════════════════════════════

return function(services: any, tab: any)
	local ThemeEngine = services:Get("ThemeEngine")
	local StateStore = services:Get("StateStore")
	local EventBus = services:Get("EventBus")
	local ConfigService = services:Get("ConfigService")
	local KeyService = services:Get("KeyService")
	local UIEngine = services:Get("UIEngine")
	local Require = services:Get("Require")
	local DOM = services:Get("DOM")

	local Toggle = Require("B0XazUniversal/src/UI/Components/Toggle.luau", services)
	local Slider = Require("B0XazUniversal/src/UI/Components/Slider.luau", services)
	local Dropdown = Require("B0XazUniversal/src/UI/Components/Dropdown.luau", services)
	local ColorPicker = Require("B0XazUniversal/src/UI/Components/ColorPicker.luau", services)
	local Keybind = Require("B0XazUniversal/src/UI/Components/Keybind.luau", services)
	local Components = Require("B0XazUniversal/src/UI/Components/Textbox.luau", services)
	local ConfigShareModal = Require("B0XazUniversal/src/UI/Modals/ConfigShareModal.luau", services)

	local function createSection(parent: Instance, title: string): Frame
		local secFrame = DOM.Create("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = ThemeEngine:GetToken("Panel"),
			BorderSizePixel = 0,
			Parent = parent,
		}, {
			DOM.CreateStroke(ThemeEngine:GetToken("Border"), 1),
			DOM.Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }),
		}) :: Frame
		ThemeEngine:BindToken(secFrame, "BackgroundColor3", "Panel")

		local header = DOM.Create("Frame", {
			Size = UDim2.new(1, 0, 0, 20),
			BackgroundColor3 = ThemeEngine:GetToken("Side"),
			BorderSizePixel = 0,
			Parent = secFrame,
		}, {
			DOM.Create("Frame", {
				Size = UDim2.new(1, 0, 0, 1),
				Position = UDim2.new(0, 0, 1, -1),
				BackgroundColor3 = ThemeEngine:GetToken("Accent"),
				BorderSizePixel = 0,
			}),
			DOM.Create("TextLabel", {
				Text = "  " .. title,
				Font = Enum.Font.Code,
				TextSize = 11,
				TextColor3 = ThemeEngine:GetToken("TextDim"),
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
			}),
		})
		ThemeEngine:BindToken(header, "BackgroundColor3", "Side")

		local content = DOM.Create("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Parent = secFrame,
		}, {
			DOM.Create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }),
			DOM.CreatePadding(4, 6, 6, 6),
		}) :: Frame

		return content
	end

	local selectedProfileName = "Default"
	local inputProfileName = "MyProfile"

	-- ─────────────────────────────────────────────────────────────────────────
	-- Left Column: Profiles & Import/Export
	-- ─────────────────────────────────────────────────────────────────────────
	local profileSec = createSection(tab.LeftCol, "Configuration Profiles")
	local profileDropdown = Dropdown.new(profileSec, "Select Profile", ConfigService:ListProfiles(), selectedProfileName, function(name)
		selectedProfileName = name
	end)

	Components.CreateTextbox(profileSec, "Profile Name", inputProfileName, "Profile name...", function(txt)
		inputProfileName = txt
	end)

	Components.CreateButton(profileSec, "Save Profile", function()
		if inputProfileName == "" or inputProfileName:lower() == "default" then
			UIEngine:Notify("Config", "Invalid profile name.", 2, ThemeEngine:GetToken("Warning"))
			return
		end
		local ok, err = ConfigService:Save(inputProfileName)
		if ok then
			profileDropdown:Refresh(ConfigService:ListProfiles(), true)
			UIEngine:Notify("Config", "Saved profile: " .. inputProfileName, 2, ThemeEngine:GetToken("Success"))
		else
			UIEngine:Notify("Save Failed", err or "Error", 2, ThemeEngine:GetToken("Danger"))
		end
	end)

	Components.CreateButton(profileSec, "Load Selected Profile", function()
		local ok, err = ConfigService:Load(selectedProfileName)
		if ok then
			UIEngine:Notify("Config", "Loaded profile: " .. selectedProfileName, 2, ThemeEngine:GetToken("Success"))
		else
			UIEngine:Notify("Load Failed", err or "Error", 2, ThemeEngine:GetToken("Danger"))
		end
	end)

	Components.CreateButton(profileSec, "Delete Selected Profile", function()
		if selectedProfileName == "Default" then
			UIEngine:Notify("Config", "Cannot delete default profile.", 2, ThemeEngine:GetToken("Warning"))
			return
		end
		if ConfigService:Delete(selectedProfileName) then
			profileDropdown:Refresh(ConfigService:ListProfiles(), false)
			UIEngine:Notify("Config", "Deleted profile.", 2, ThemeEngine:GetToken("Success"))
		end
	end)

	local shareSec = createSection(tab.LeftCol, "Profile Sharing")
	Components.CreateButton(shareSec, "Export Profile to Clipboard", function()
		local ok, _ = ConfigService:Export()
		if ok then
			UIEngine:Notify("Config", "JSON copied to clipboard.", 2, ThemeEngine:GetToken("Success"))
		end
	end)
	Components.CreateButton(shareSec, "Open Two-Way JSON Editor", function()
		local _, jsonStr = ConfigService:Export()
		ConfigShareModal:Show(jsonStr)
	end)

	-- ─────────────────────────────────────────────────────────────────────────
	-- Right Column: Themes, UI Scale & License Management
	-- ─────────────────────────────────────────────────────────────────────────
	local uiSec = createSection(tab.RightCol, "UI Preferences")
	local uiScaleSlider = Slider.new(uiSec, "UI Scale Factor", 50, 150, math.floor((StateStore:Get("Settings.UIScale") or 1.0) * 100), 5, "%", function(scaleVal)
		local factor = scaleVal / 100
		StateStore:Set("Settings.UIScale", factor)
		if UIEngine.ScaleObject then UIEngine.ScaleObject.Scale = factor end
	end)
	EventBus:Subscribe("StateHydrated", function()
		local factor = tonumber(StateStore:Get("Settings.UIScale")) or 1.0
		if UIEngine.ScaleObject then UIEngine.ScaleObject.Scale = factor end
		uiScaleSlider:Set(math.floor(factor * 100), true)
	end)
	Keybind.new(uiSec, "Menu Toggle Hotkey", "Settings.MenuKeybind")

	local themeSec = createSection(tab.RightCol, "Themes & Styling")
	local presetList = {}
	for name in pairs(ThemeEngine.Presets) do table.insert(presetList, name) end
	table.sort(presetList)

	Dropdown.new(themeSec, "Color Preset", presetList, "Theme.ActivePreset", function(preset)
		ThemeEngine:SetPreset(preset)
		UIEngine:Notify("Themes", "Applied theme: " .. preset, 1.5, ThemeEngine:GetToken("Success"))
	end)

	local tokens = { "Accent", "Bg", "Panel", "Elem", "Side", "Text", "Border" }
	for _, tk in ipairs(tokens) do
		ColorPicker.new(themeSec, tk .. " Token Color", ThemeEngine:GetToken(tk), function(color)
			ThemeEngine:UpdateToken(tk, color)
		end)
	end

	local keySec = createSection(tab.RightCol, "License & Account")
	Components.CreateButton(keySec, "Access Tier: " .. KeyService:GetTierName(), function() end)
	Components.CreateButton(keySec, "Copy Support Link", function()
		local ok, msg = KeyService:CopyInfo()
		UIEngine:Notify("Support", msg, 2, ThemeEngine:GetToken("Success"))
	end)
	Components.CreateButton(keySec, "Logout & Clear License", function()
		KeyService:ClearKey()
		UIEngine:Notify("License", "Cleared saved license key.", 2, ThemeEngine:GetToken("Warning"))
		if (getgenv and getgenv()).B0XazRelaunch then
			(getgenv and getgenv()).B0XazRelaunch()
		end
	end)
	Components.CreateButton(keySec, "Unload Suite & Clear Output", function()
		local globalEnv = (getgenv and getgenv()) or _G
		if typeof(globalEnv.B0XazUnload) == "function" then
			globalEnv.B0XazUnload()
		end
	end)
end
