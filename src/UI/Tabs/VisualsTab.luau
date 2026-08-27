local Lighting = game:GetService("Lighting")

return function(services: any, tab: any)
	local ThemeEngine = services:Get("ThemeEngine")
	local StateStore = services:Get("StateStore")
	local EventBus = services:Get("EventBus")
	local Disposer = services:Get("Disposer")
	local Require = services:Get("Require")
	local DOM = services:Get("DOM")

	local Toggle = Require("src/UI/Components/Toggle.luau", services)
	local Slider = Require("src/UI/Components/Slider.luau", services)
	local Dropdown = Require("src/UI/Components/Dropdown.luau", services)
	local ColorPicker = Require("src/UI/Components/ColorPicker.luau", services)
	local Components = Require("src/UI/Components/Textbox.luau", services)

	-- Lighting values are backed up only once, before the first change, so
	-- toggling fullbright repeatedly never stacks backups.
	local fullbrightBackup: { [string]: any }? = nil
	local function setFullbright(enabled: boolean)
		if enabled then
			if not fullbrightBackup then
				fullbrightBackup = {
					Ambient = Lighting.Ambient,
					OutdoorAmbient = Lighting.OutdoorAmbient,
					Brightness = Lighting.Brightness,
					GlobalShadows = Lighting.GlobalShadows,
				}
			end
			Lighting.Ambient = Color3.new(1, 1, 1)
			Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
			Lighting.Brightness = 2
			Lighting.GlobalShadows = false
		elseif fullbrightBackup then
			Lighting.Ambient = fullbrightBackup.Ambient
			Lighting.OutdoorAmbient = fullbrightBackup.OutdoorAmbient
			Lighting.Brightness = fullbrightBackup.Brightness
			-- NoShadows owns the shadow state if it is still active
			if StateStore:Get("Performance.NoShadows") == true then
				Lighting.GlobalShadows = false
			else
				Lighting.GlobalShadows = fullbrightBackup.GlobalShadows
			end
			fullbrightBackup = nil
		end
	end
	Disposer:Add(function()
		setFullbright(false)
	end)

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

	local espMainSec = createSection(tab.LeftCol, "Player ESP")
	Toggle.new(espMainSec, "Enable Player ESP", "ESP.Enabled", nil, 2)
	Toggle.new(espMainSec, "Draw 2D Bounding Boxes", "ESP.Box")
	Toggle.new(espMainSec, "Show Display Names", "ESP.Name")
	Toggle.new(espMainSec, "Show Health Bar", "ESP.Health")
	Toggle.new(espMainSec, "Show Distance", "ESP.Distance")
	Toggle.new(espMainSec, "Show Equipped Weapon", "ESP.Tool")
	Toggle.new(espMainSec, "Show Backpack Items", "ESP.Backpack")
	Toggle.new(espMainSec, "Show Tracers", "ESP.Tracers")
	Toggle.new(espMainSec, "Show 2D Skeletons", "ESP.Skeleton")
	Toggle.new(espMainSec, "Draw Head Dot", "ESP.HeadDot")
	Toggle.new(espMainSec, "Look Direction Lines", "ESP.LookDir")
	Toggle.new(espMainSec, "Team Check Filter", "ESP.TeamCheck")

	local espConfigSec = createSection(tab.LeftCol, "ESP Configuration")
	Slider.new(espConfigSec, "Max Rendering Distance", 100, 2000, "ESP.MaxDist", 50, " studs")
	ColorPicker.new(espConfigSec, "Global ESP Color", "ESP.Color")
	Dropdown.new(espConfigSec, "ESP Font Style", { "Monospace", "UI", "System", "Plex" }, "ESP.Font")
	Toggle.new(espConfigSec, "Text Outlines", "ESP.Outline")
	Toggle.new(espConfigSec, "Auto-Scaling Distance", "ESP.AutoScaling")

	-- Every flag here is consumed by OptimizerService, which caches the
	-- original property values so a restore stays lossless.
	local perfSec = createSection(tab.LeftCol, "Performance Boosters")
	Toggle.new(perfSec, "Strip Textures & Decals", "Performance.NoTextures")
	Toggle.new(perfSec, "Force Flat Smooth Plastic", "Performance.LowMaterials")
	Toggle.new(perfSec, "Reduce 3D Terrain Fidelity", "Performance.OptimizeTerrain")
	Toggle.new(perfSec, "Disable Post-Processing FX", "Performance.NoPostProcessing")
	Toggle.new(perfSec, "Disable Global Shadows", "Performance.NoShadows")
	Toggle.new(perfSec, "Disable Particle Emitters", "Performance.NoParticles")

	local statSec = createSection(tab.LeftCol, "On-Screen Telemetry")
	Toggle.new(statSec, "Display FPS Counter", "Settings.ShowFPS")
	Toggle.new(statSec, "Display Ping Monitor", "Settings.ShowPing")

	local chamsSec = createSection(tab.RightCol, "Player Chams (Highlights)")
	Toggle.new(chamsSec, "Enable Highlights", "Chams.Enabled", nil, 2)
	Toggle.new(chamsSec, "Use Player Team Color", "Chams.UseTeamColor")
	Dropdown.new(chamsSec, "Depth Rendering Mode", { "AlwaysOnTop", "Occluded" }, "Chams.DepthMode")
	ColorPicker.new(chamsSec, "Highlight Fill Color", "Chams.FillColor")
	ColorPicker.new(chamsSec, "Highlight Outline Color", "Chams.OutlineColor")

	local lightingSec = createSection(tab.RightCol, "World & Lighting")
	Toggle.new(lightingSec, "Fullbright Mode", "Visuals.Fullbright", setFullbright, 1)
	EventBus:Subscribe("StateHydrated", function()
		setFullbright(StateStore:Get("Visuals.Fullbright") == true)
	end)

	-- Clock time is a live server property; the original is remembered so
	-- unload restores the world's lighting schedule.
	local originalClockTime = Lighting.ClockTime
	Slider.new(lightingSec, "Time of Day", 0, 24, math.floor(originalClockTime), 1, "h", function(timeVal)
		Lighting.ClockTime = timeVal
	end)
	Disposer:Add(function()
		Lighting.ClockTime = originalClockTime
	end)

	-- Every cinematic mode owns ClockTime while active, so the manual Time of
	-- Day slider above only has an effect while the mode is Off. The static
	-- presets pin one look; Dynamic runs the full 24-hour cycle.
	local cineSec = createSection(tab.RightCol, "Cinematic Lighting")
	Dropdown.new(cineSec, "Lighting Mode", { "Off", "Static Day", "Static Night", "Dynamic" }, "Lighting.Mode")
	Toggle.new(cineSec, "Vignette Overlay", "Lighting.Vignette")

	-- Dynamic-only controls
	Slider.new(cineSec, "Day Cycle Duration", 30, 1800, "Lighting.CycleDuration", 30, " s")
	Slider.new(cineSec, "Cycle Start Hour", 0, 24, "Lighting.TimeOfDay", 1, "h")
	Toggle.new(cineSec, "Freeze Time Cycle", "Lighting.Paused")
	Toggle.new(cineSec, "Remaster Part Materials", "Lighting.RemasterMaterials")
	Toggle.new(cineSec, "Upgrade Map Lights", "Lighting.UpgradeMapLights")

	local fxSec = createSection(tab.RightCol, "Visual Effects")
	Toggle.new(fxSec, "Draw Radial Speed Lines", "Extras.SpeedLines", nil, 1)
end
