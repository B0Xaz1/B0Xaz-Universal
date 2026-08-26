-- ════════════════════════════════════════════════════════════════════════════
-- UI/Presenters/CombatPresenter.lua
-- Binds Combat UI widgets to CombatService and ConfigService
-- ════════════════════════════════════════════════════════════════════════════

local Toggle = require(script.Parent.Parent.Components.Toggle)
local Slider = require(script.Parent.Parent.Components.Slider)
local Dropdown = require(script.Parent.Parent.Components.Dropdown)
local Keybind = require(script.Parent.Parent.Components.Keybind)

local CombatPresenter = {}

function CombatPresenter.Build(tab, container, themeEngine)
	local config = container:Get("ConfigService")
	local page = tab.Page

	-- Aimbot Core Controls
	Toggle.new(page, "Enable Aimbot", config:Get("Aimbot.Enabled"), function(v)
		config:Set("Aimbot.Enabled", v)
	end, themeEngine)

	Toggle.new(page, "Camera CFrame Lock", config:Get("Aimbot.UseCamera"), function(v)
		config:Set("Aimbot.UseCamera", v)
	end, themeEngine)

	Keybind.new(page, "Aimbot Keybind", config:Get("Aimbot.Keybind"), function(k)
		config:Set("Aimbot.Keybind", k)
	end, themeEngine)

	Dropdown.new(page, "Lock Mode", { "Hold", "Toggle" }, function(v)
		config:Set("Aimbot.LockMode", v)
	end, config:Get("Aimbot.LockMode"), themeEngine)

	Dropdown.new(page, "Target Hitpart", { "Head", "Torso", "Root" }, function(v)
		config:Set("Aimbot.Hitpart", v)
	end, config:Get("Aimbot.Hitpart"), themeEngine)

	Slider.new(page, "Smoothing Factor", config:Get("Aimbot.Smoothness"), 1, 20, function(v)
		config:Set("Aimbot.Smoothness", v)
	end, "", themeEngine)

	Dropdown.new(page, "Movement Mode", { "Linear", "WindMouse" }, function(v)
		config:Set("Aimbot.MovementMode", v)
	end, config:Get("Aimbot.MovementMode"), themeEngine)

	-- FOV Reticle Controls
	Toggle.new(page, "Show FOV Circle", config:Get("Aimbot.FOV.Show"), function(v)
		config:Set("Aimbot.FOV.Show", v)
	end, themeEngine)

	Toggle.new(page, "Filled FOV Circle", config:Get("Aimbot.FOV.Filled"), function(v)
		config:Set("Aimbot.FOV.Filled", v)
	end, themeEngine)

	Toggle.new(page, "Rainbow FOV", config:Get("Aimbot.FOV.Rainbow"), function(v)
		config:Set("Aimbot.FOV.Rainbow", v)
	end, themeEngine)

	Slider.new(page, "FOV Radius", config:Get("Aimbot.FOV.Size"), 30, 500, function(v)
		config:Set("Aimbot.FOV.Size", v)
	end, " px", themeEngine)

	-- Triggerbot Controls
	Toggle.new(page, "Enable Triggerbot", config:Get("Aimbot.Triggerbot.Enabled"), function(v)
		config:Set("Aimbot.Triggerbot.Enabled", v)
	end, themeEngine)

	Slider.new(page, "Triggerbot Delay", math.floor((config:Get("Aimbot.Triggerbot.Delay") or 0.05) * 1000), 0, 500, function(v)
		config:Set("Aimbot.Triggerbot.Delay", v / 1000)
	end, " ms", themeEngine)
end

return CombatPresenter
