-- ════════════════════════════════════════════════════════════════════════════
-- UI/Presenters/MovementPresenter.lua
-- Binds Locomotion and Flight UI controls to LocomotionService
-- ════════════════════════════════════════════════════════════════════════════

local Toggle = require(script.Parent.Parent.Components.Toggle)
local Slider = require(script.Parent.Parent.Components.Slider)
local Keybind = require(script.Parent.Parent.Components.Keybind)
local Button = require(script.Parent.Parent.Components.Button)

local MovementPresenter = {}

function MovementPresenter.Build(tab, container, themeEngine)
	local config = container:Get("ConfigService")
	local locomotion = container:Get("LocomotionService")
	local page = tab.Page

	-- Speed & Jump Modifiers
	Slider.new(page, "Walk Speed", config:Get("Movement.Speed"), 16, 300, function(v)
		config:Set("Movement.Speed", v)
	end, " ws", themeEngine)

	Toggle.new(page, "Shift Sprint", config:Get("Movement.SprintEnabled"), function(v)
		config:Set("Movement.SprintEnabled", v)
	end, themeEngine)

	Slider.new(page, "Sprint Speed", config:Get("Movement.SprintSpeed"), 20, 350, function(v)
		config:Set("Movement.SprintSpeed", v)
	end, " ws", themeEngine)

	Toggle.new(page, "Infinite Air Jump", config:Get("Movement.InfJump"), function(v)
		config:Set("Movement.InfJump", v)
	end, themeEngine)

	Toggle.new(page, "CFrame Speed Translation", config:Get("Movement.CFrameSpeed"), function(v)
		config:Set("Movement.CFrameSpeed", v)
	end, themeEngine)

	Slider.new(page, "CFrame Speed Rate", config:Get("Movement.CFrameSpeedValue"), 10, 300, function(v)
		config:Set("Movement.CFrameSpeedValue", v)
	end, " sps", themeEngine)

	-- Flight Physics Controls
	Toggle.new(page, "Enable 6-DOF Flight", config:Get("Movement.FlyEnabled"), function(v)
		if v then locomotion:StartFly() else locomotion:StopFly() end
	end, themeEngine)

	Slider.new(page, "Flight Velocity", config:Get("Movement.FlySpeed"), 10, 300, function(v)
		config:Set("Movement.FlySpeed", v)
	end, "", themeEngine)

	Keybind.new(page, "Flight Activation Bind", config:Get("Movement.FlyKeybind"), function(k)
		config:Set("Movement.FlyKeybind", k)
	end, themeEngine)
end

return MovementPresenter
