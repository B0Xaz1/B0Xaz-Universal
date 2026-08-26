-- ════════════════════════════════════════════════════════════════════════════
-- UI/Presenters/VisualsPresenter.lua
-- Binds Visuals UI widgets to VisualsService and EnvironmentService
-- ════════════════════════════════════════════════════════════════════════════

local Toggle = require(script.Parent.Parent.Components.Toggle)
local Slider = require(script.Parent.Parent.Components.Slider)
local Dropdown = require(script.Parent.Parent.Components.Dropdown)
local ColorPicker = require(script.Parent.Parent.Components.ColorPicker)
local Section = require(script.Parent.Parent.Components.Section)

local VisualsPresenter = {}

function VisualsPresenter.Build(tab, container, themeEngine)
	local config = container:Get("ConfigService")
	local page = tab.Page

	-- 2D ESP Overlays
	Section.new(page, "2D ESP", themeEngine)
	Toggle.new(page, "Master ESP Switch", config:Get("ESP.Enabled"), function(v)
		config:Set("ESP.Enabled", v)
	end, themeEngine)

	Toggle.new(page, "Draw Boxes", config:Get("ESP.Box"), function(v)
		config:Set("ESP.Box", v)
	end, themeEngine)

	Toggle.new(page, "Show Names", config:Get("ESP.Name"), function(v)
		config:Set("ESP.Name", v)
	end, themeEngine)

	Toggle.new(page, "Show Health Bars", config:Get("ESP.Health"), function(v)
		config:Set("ESP.Health", v)
	end, themeEngine)

	Toggle.new(page, "Show Distance", config:Get("ESP.Distance"), function(v)
		config:Set("ESP.Distance", v)
	end, themeEngine)

	Toggle.new(page, "Show Snap Tracers", config:Get("ESP.Tracers"), function(v)
		config:Set("ESP.Tracers", v)
	end, themeEngine)

	ColorPicker.new(page, "ESP Global Color", config:Get("ESP.Color"), function(c)
		config:Set("ESP.Color", c)
	end, themeEngine)

	-- 3D Chams / Highlights
	Section.new(page, "Chams", themeEngine)
	Toggle.new(page, "Enable Player Chams", config:Get("Chams.Enabled"), function(v)
		config:Set("Chams.Enabled", v)
	end, themeEngine)

	Dropdown.new(page, "Chams Occlusion Mode", { "AlwaysOnTop", "Occluded" }, function(v)
		config:Set("Chams.DepthMode", v)
	end, config:Get("Chams.DepthMode"), themeEngine)

	ColorPicker.new(page, "Chams Fill Color", config:Get("Chams.FillColor"), function(c)
		config:Set("Chams.FillColor", c)
	end, themeEngine)

	-- World Lighting & FX
	Section.new(page, "World & FX", themeEngine)
	Toggle.new(page, "Fullbright Mode", config:Get("Visuals.Fullbright"), function(v)
		config:Set("Visuals.Fullbright", v)
	end, themeEngine)

	Toggle.new(page, "Draw Speed Lines", config:Get("Extras.SpeedLines"), function(v)
		config:Set("Extras.SpeedLines", v)
	end, themeEngine)
end

return VisualsPresenter
