-- ════════════════════════════════════════════════════════════════════════════
-- UI/Presenters/UtilityPresenter.lua
-- Binds Utility tab widgets to EnvironmentService and ServerService
-- ════════════════════════════════════════════════════════════════════════════

local Toggle = require(script.Parent.Parent.Components.Toggle)
local Button = require(script.Parent.Parent.Components.Button)
local Section = require(script.Parent.Parent.Components.Section)

local UtilityPresenter = {}

function UtilityPresenter.Build(tab, container, themeEngine)
	local config = container:Get("ConfigService")
	local environment = container:Get("EnvironmentService")
	local server = container:Get("ServerService")
	local page = tab.Page

	-- Graphics & Performance Optimizers
	Section.new(page, "Performance", themeEngine)
	Toggle.new(page, "Remove Textures & Decals", config:Get("Performance.NoTextures"), function(v)
		environment:SetNoTextures(v)
	end, themeEngine)

	Toggle.new(page, "Force Smooth Plastic Materials", config:Get("Performance.LowMaterials"), function(v)
		environment:SetLowMaterials(v)
	end, themeEngine)

	Toggle.new(page, "Disable Engine Shadow Cascades", config:Get("Performance.NoShadows"), function(v)
		environment:SetNoShadows(v)
	end, themeEngine)

	-- Framerate Limits
	Section.new(page, "Framerate", themeEngine)
	Button.new(page, "Unlock Target Framerate Cap (999)", function()
		if setfpscap then pcall(setfpscap, 999) end
	end, themeEngine)

	Button.new(page, "Cap Framerate to 60 FPS", function()
		if setfpscap then pcall(setfpscap, 60) end
	end, themeEngine)

	-- Server Tools
	Section.new(page, "Server", themeEngine)
	Toggle.new(page, "Enable Anti-AFK Idle Simulation", config:Get("Settings.AntiAfk"), function(v)
		server:SetAntiAfk(v)
	end, themeEngine)

	Button.new(page, "Matchmake Public Server Hop", function()
		tab:Notify("Server Hop", "Searching open instances...", 2)
		local ok, msg = server:ServerHop()
		if not ok then
			tab:Notify("Server Hop", msg or "Hop failed", 3, themeEngine.Current.Danger)
		end
	end, themeEngine)
end

return UtilityPresenter
