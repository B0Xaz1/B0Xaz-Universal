--!strict
-- ══════════════════════════════════════════════════════════════════════════════
-- B0XazUniversal - Combat & Targeting UI Tab
-- Declarative view-model binding for Aimbot, WindMouse physics, FOV circle,
-- target verification rules, lead prediction, and triggerbot parameters.
-- ══════════════════════════════════════════════════════════════════════════════

return function(services: any, tab: any)
	local ThemeEngine = services:Get("ThemeEngine")
	local StateStore = services:Get("StateStore")
	local Require = services:Get("Require")
	local DOM = services:Get("DOM")

	local Toggle = Require("B0XazUniversal/src/UI/Components/Toggle.luau")
	local Slider = Require("B0XazUniversal/src/UI/Components/Slider.luau")
	local Dropdown = Require("B0XazUniversal/src/UI/Components/Dropdown.luau")
	local Keybind = Require("B0XazUniversal/src/UI/Components/Keybind.luau")
	local Components = Require("B0XazUniversal/src/UI/Components/Textbox.luau")

	-- Section Helper
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

	-- ─────────────────────────────────────────────────────────────────────────
	-- Left Column: Core Aimbot & FOV Customization
	-- ─────────────────────────────────────────────────────────────────────────
	local aimbotSec = createSection(tab.LeftCol, "Aimbot Controls")
	Toggle.new(aimbotSec, "Aimbot Enabled", "Aimbot.Enabled", nil, 3)
	Toggle.new(aimbotSec, "Use Camera Lock (CFrame)", "Aimbot.UseCamera", nil, 3)
	Keybind.new(aimbotSec, "Activation Bind", "Aimbot.Keybind")
	Dropdown.new(aimbotSec, "Lock Mode", { "Hold", "Toggle" }, "Aimbot.LockMode")
	Dropdown.new(aimbotSec, "Target Hitpart", { "Head", "Torso", "Root", "LeftArm", "RightArm", "LeftLeg", "RightLeg" }, "Aimbot.Hitpart")
	Slider.new(aimbotSec, "Smoothness", 1, 20, "Aimbot.Smoothness", 1)
	Dropdown.new(aimbotSec, "Movement Mode", { "Linear", "WindMouse" }, "Aimbot.MovementMode")
	Slider.new(aimbotSec, "Wind Strength", 0, 5, "Aimbot.WindStrength", 0.1)
	Slider.new(aimbotSec, "Wind Damping", 0, 1, "Aimbot.WindDamping", 0.05)
	Slider.new(aimbotSec, "Shake Intensity", 0, 10, "Aimbot.ShakeIntensity", 1)

	local fovSec = createSection(tab.LeftCol, "Field of View (FOV)")
	Toggle.new(fovSec, "Show FOV Circle", "Aimbot.FOV.Show")
	Toggle.new(fovSec, "Filled Circle", "Aimbot.FOV.Filled")
	Toggle.new(fovSec, "Rainbow FOV", "Aimbot.FOV.Rainbow")
	Slider.new(fovSec, "FOV Radius", 10, 600, "Aimbot.FOV.Size", 5, " px")
	Slider.new(fovSec, "Line Thickness", 1, 10, "Aimbot.FOV.Thickness", 1)

	-- ─────────────────────────────────────────────────────────────────────────
	-- Right Column: Target Validation, Prediction & Triggerbot
	-- ─────────────────────────────────────────────────────────────────────────
	local filterSec = createSection(tab.RightCol, "Target Settings")
	Toggle.new(filterSec, "Team Check", "Aimbot.TeamCheck")
	Toggle.new(filterSec, "Ignore Friends", "Aimbot.FriendCheck")
	Toggle.new(filterSec, "Ignore Whitelisted", "Aimbot.WhitelistCheck")
	Toggle.new(filterSec, "Ignore ForceField", "Aimbot.ForceFieldCheck")
	Toggle.new(filterSec, "Visibility (Wall) Check", "Aimbot.VisCheck")
	Toggle.new(filterSec, "Unlock On Death", "Aimbot.UnlockOnDeath")
	Toggle.new(filterSec, "Break On Mouse Pull", "Aimbot.BreakOnPull")
	Slider.new(filterSec, "Max Distance", 50, 2000, "Aimbot.MaxDistance", 25, " studs")
	Slider.new(filterSec, "Max Lock Radius", 50, 500, "Aimbot.MaxLockRadius", 10, " px")

	local triggerSec = createSection(tab.RightCol, "Prediction & Triggerbot")
	Slider.new(triggerSec, "Horizontal Prediction", 0, 1, "Aimbot.Prediction.Horizontal", 0.01)
	Slider.new(triggerSec, "Vertical Prediction", 0, 1, "Aimbot.Prediction.Vertical", 0.01)
	Components.CreateButton(triggerSec, "Reset Prediction", function()
		StateStore:Set("Aimbot.Prediction.Horizontal", 0)
		StateStore:Set("Aimbot.Prediction.Vertical", 0)
	end)
	Toggle.new(triggerSec, "Enable Triggerbot", "Aimbot.Triggerbot.Enabled", nil, 3)
	Slider.new(triggerSec, "Trigger Delay", 0, 0.5, "Aimbot.Triggerbot.Delay", 0.01, " s")
	Slider.new(triggerSec, "Trigger Max Distance", 25, 2000, "Aimbot.Triggerbot.MaxDistance", 25, " studs")
	Toggle.new(triggerSec, "Trigger Team Check", "Aimbot.Triggerbot.TeamCheck")
	Toggle.new(triggerSec, "Trigger Friend Check", "Aimbot.Triggerbot.FriendCheck")
	Toggle.new(triggerSec, "Trigger Wall Check", "Aimbot.Triggerbot.VisCheck")
end
