-- ════════════════════════════════════════════════════════════════════════════
-- UI/Presenters/SettingsPresenter.lua
-- Binds profile saves, UI scaling, theming, and verification inputs
-- ════════════════════════════════════════════════════════════════════════════

local Toggle = require(script.Parent.Parent.Components.Toggle)
local Dropdown = require(script.Parent.Parent.Components.Dropdown)
local Keybind = require(script.Parent.Parent.Components.Keybind)
local Button = require(script.Parent.Parent.Components.Button)
local ExportModal = require(script.Parent.Parent.Components.Modals.ExportModal)
local Section = require(script.Parent.Parent.Components.Section)

local SettingsPresenter = {}

function SettingsPresenter.Build(tab, container, themeEngine)
	local config = container:Get("ConfigService")
	local auth = container:Get("AuthService")
	local page = tab.Page

	-- Profile Directory Dropdown
	Section.new(page, "Profiles", themeEngine)
	local dropdownProfiles
	dropdownProfiles = Dropdown.new(page, "Select Profile File", config:GetSavedProfiles(), function(v)
		-- Selected profile handler
	end, "Default", themeEngine)

	Button.new(page, "Refresh Profiles List", function()
		dropdownProfiles:Refresh(config:GetSavedProfiles(), true)
	end, themeEngine)

	Button.new(page, "Save Current Configuration", function()
		local activeProfile = dropdownProfiles:Get()
		if activeProfile:lower() == "default" then
			tab:Notify("Error", "Cannot overwrite default snapshot.", 3, themeEngine.Current.Danger)
			return
		end
		local ok, msg = config:SaveProfile(activeProfile)
		tab:Notify("Saves", ok and "Config saved!" or msg, 2, ok and themeEngine.Current.Success or themeEngine.Current.Danger)
	end, themeEngine)

	Button.new(page, "Load Selected Profile", function()
		local ok = config:LoadProfile(dropdownProfiles:Get())
		tab:Notify("Saves", ok and "Config loaded!" or "Load failed", 2)
	end, themeEngine)

	Button.new(page, "Export Profile JSON", function()
		local raw = config:Export()
		ExportModal.Show(raw, themeEngine)
	end, themeEngine)

	-- Interface Modifications
	Section.new(page, "Interface", themeEngine)
	Keybind.new(page, "Menu Toggle Hotkey", config:Get("Settings.MenuKeybind"), function(k)
		config:Set("Settings.MenuKeybind", k)
	end, themeEngine)

	Toggle.new(page, "Show On-Screen FPS Counter", config:Get("Settings.ShowFPS"), function(v)
		config:Set("Settings.ShowFPS", v)
	end, themeEngine)

	Toggle.new(page, "Show On-Screen Ping Monitor", config:Get("Settings.ShowPing"), function(v)
		config:Set("Settings.ShowPing", v)
	end, themeEngine)

	-- Design Theme Presets
	Section.new(page, "Theme", themeEngine)
	local presets = {}
	for name in pairs(themeEngine.Presets) do table.insert(presets, name) end
	table.sort(presets)

	Dropdown.new(page, "Visual Color Preset", presets, function(v)
		themeEngine:SetPreset(v)
	end, themeEngine.ActivePreset, themeEngine)

	-- Licensing Verifications
	Section.new(page, "License", themeEngine)
	Button.new(page, "Active License Level: " .. auth:GetTierName(), function() end, themeEngine)
end

return SettingsPresenter
