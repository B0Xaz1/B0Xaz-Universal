return function(services: any, tab: any)
	local ThemeEngine = services:Get("ThemeEngine")
	local Require = services:Get("Require")
	local DOM = services:Get("DOM")

	local Toggle = Require("src/UI/Components/Toggle.luau", services)

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

	-- Every flag here is consumed by OptimizerService, which caches the
	-- original property values so a restore stays lossless.
	local perfSec = createSection(tab.LeftCol, "Performance Boosters")
	Toggle.new(perfSec, "Strip Textures & Decals", "Performance.NoTextures")
	Toggle.new(perfSec, "Force Flat Smooth Plastic", "Performance.LowMaterials")
	Toggle.new(perfSec, "Reduce 3D Terrain Fidelity", "Performance.OptimizeTerrain")
	Toggle.new(perfSec, "Disable Post-Processing FX", "Performance.NoPostProcessing")
	Toggle.new(perfSec, "Disable Global Shadows", "Performance.NoShadows")
	Toggle.new(perfSec, "Disable Particle Emitters", "Performance.NoParticles")

	local statSec = createSection(tab.RightCol, "On-Screen Telemetry")
	Toggle.new(statSec, "Display FPS Counter", "Settings.ShowFPS")
	Toggle.new(statSec, "Display Ping Monitor", "Settings.ShowPing")
end
