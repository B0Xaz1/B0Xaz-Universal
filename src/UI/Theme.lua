local SETTINGS = {
	DEFAULT_PRESET = "Default Cyan",
	STATUS_COLORS = {
		Success = Color3.fromRGB(90, 200, 120),
		Danger = Color3.fromRGB(220, 80, 80),
		Warning = Color3.fromRGB(230, 175, 70),
	},
	ACCENT_FACTORS = {
		DARK_SATURATION = 0.9,
		DARK_VALUE = 0.7,
		DIM_SATURATION = 0.8,
		DIM_VALUE = 0.45,
	},
	PRESETS = {
		["Default Cyan"] = {
			Bg = Color3.fromRGB(18, 18, 20),
			Panel = Color3.fromRGB(26, 26, 30),
			Elem = Color3.fromRGB(32, 32, 38),
			ElemHover = Color3.fromRGB(42, 42, 50),
			Side = Color3.fromRGB(22, 22, 26),
			Accent = Color3.fromRGB(0, 200, 220),
			AccentDark = Color3.fromRGB(0, 140, 160),
			AccentDim = Color3.fromRGB(0, 90, 105),
			Text = Color3.fromRGB(225, 225, 230),
			TextDim = Color3.fromRGB(145, 145, 155),
			TextMuted = Color3.fromRGB(95, 95, 105),
			Border = Color3.fromRGB(55, 55, 65),
			BorderDim = Color3.fromRGB(40, 40, 48),
			ToggleOff = Color3.fromRGB(40, 40, 48),
			ToggleOn = Color3.fromRGB(0, 200, 220),
		},
		["Midnight Purple"] = {
			Bg = Color3.fromRGB(14, 12, 20),
			Panel = Color3.fromRGB(22, 18, 30),
			Elem = Color3.fromRGB(28, 24, 38),
			ElemHover = Color3.fromRGB(38, 32, 52),
			Side = Color3.fromRGB(18, 14, 25),
			Accent = Color3.fromRGB(170, 70, 250),
			AccentDark = Color3.fromRGB(130, 45, 200),
			AccentDim = Color3.fromRGB(80, 30, 120),
			Text = Color3.fromRGB(235, 230, 245),
			TextDim = Color3.fromRGB(160, 150, 175),
			TextMuted = Color3.fromRGB(105, 95, 120),
			Border = Color3.fromRGB(65, 50, 80),
			BorderDim = Color3.fromRGB(45, 35, 60),
			ToggleOff = Color3.fromRGB(45, 35, 60),
			ToggleOn = Color3.fromRGB(170, 70, 250),
		},
		["Blood Crimson"] = {
			Bg = Color3.fromRGB(18, 12, 12),
			Panel = Color3.fromRGB(28, 18, 18),
			Elem = Color3.fromRGB(38, 24, 24),
			ElemHover = Color3.fromRGB(50, 30, 30),
			Side = Color3.fromRGB(22, 14, 14),
			Accent = Color3.fromRGB(235, 50, 65),
			AccentDark = Color3.fromRGB(170, 30, 45),
			AccentDim = Color3.fromRGB(110, 20, 30),
			Text = Color3.fromRGB(240, 225, 225),
			TextDim = Color3.fromRGB(170, 145, 145),
			TextMuted = Color3.fromRGB(115, 95, 95),
			Border = Color3.fromRGB(75, 45, 45),
			BorderDim = Color3.fromRGB(50, 35, 35),
			ToggleOff = Color3.fromRGB(50, 35, 35),
			ToggleOn = Color3.fromRGB(235, 50, 65),
		},
		["Emerald Neon"] = {
			Bg = Color3.fromRGB(12, 18, 14),
			Panel = Color3.fromRGB(18, 28, 22),
			Elem = Color3.fromRGB(24, 38, 28),
			ElemHover = Color3.fromRGB(32, 50, 38),
			Side = Color3.fromRGB(15, 22, 18),
			Accent = Color3.fromRGB(0, 225, 120),
			AccentDark = Color3.fromRGB(0, 160, 85),
			AccentDim = Color3.fromRGB(0, 100, 55),
			Text = Color3.fromRGB(225, 240, 230),
			TextDim = Color3.fromRGB(145, 170, 155),
			TextMuted = Color3.fromRGB(95, 115, 100),
			Border = Color3.fromRGB(45, 75, 55),
			BorderDim = Color3.fromRGB(35, 50, 40),
			ToggleOff = Color3.fromRGB(35, 50, 40),
			ToggleOn = Color3.fromRGB(0, 225, 120),
		},
		["Cyber Gold"] = {
			Bg = Color3.fromRGB(18, 18, 15),
			Panel = Color3.fromRGB(28, 27, 20),
			Elem = Color3.fromRGB(38, 36, 26),
			ElemHover = Color3.fromRGB(50, 48, 34),
			Side = Color3.fromRGB(22, 21, 16),
			Accent = Color3.fromRGB(245, 195, 35),
			AccentDark = Color3.fromRGB(180, 140, 20),
			AccentDim = Color3.fromRGB(110, 85, 10),
			Text = Color3.fromRGB(240, 238, 225),
			TextDim = Color3.fromRGB(170, 168, 145),
			TextMuted = Color3.fromRGB(115, 113, 95),
			Border = Color3.fromRGB(75, 72, 45),
			BorderDim = Color3.fromRGB(50, 48, 35),
			ToggleOff = Color3.fromRGB(50, 48, 35),
			ToggleOn = Color3.fromRGB(245, 195, 35),
		},
		["Sakura Pink"] = {
			Bg = Color3.fromRGB(20, 15, 18),
			Panel = Color3.fromRGB(30, 22, 26),
			Elem = Color3.fromRGB(40, 28, 34),
			ElemHover = Color3.fromRGB(52, 36, 44),
			Side = Color3.fromRGB(24, 18, 21),
			Accent = Color3.fromRGB(255, 120, 170),
			AccentDark = Color3.fromRGB(190, 80, 120),
			AccentDim = Color3.fromRGB(120, 50, 75),
			Text = Color3.fromRGB(245, 230, 238),
			TextDim = Color3.fromRGB(175, 150, 165),
			TextMuted = Color3.fromRGB(120, 100, 110),
			Border = Color3.fromRGB(80, 50, 68),
			BorderDim = Color3.fromRGB(55, 38, 48),
			ToggleOff = Color3.fromRGB(55, 38, 48),
			ToggleOn = Color3.fromRGB(255, 120, 170),
		},
		["Abyss Dark"] = {
			Bg = Color3.fromRGB(10, 10, 10),
			Panel = Color3.fromRGB(16, 16, 16),
			Elem = Color3.fromRGB(22, 22, 22),
			ElemHover = Color3.fromRGB(30, 30, 30),
			Side = Color3.fromRGB(13, 13, 13),
			Accent = Color3.fromRGB(200, 200, 200),
			AccentDark = Color3.fromRGB(140, 140, 140),
			AccentDim = Color3.fromRGB(80, 80, 80),
			Text = Color3.fromRGB(240, 240, 240),
			TextDim = Color3.fromRGB(150, 150, 150),
			TextMuted = Color3.fromRGB(90, 90, 90),
			Border = Color3.fromRGB(45, 45, 45),
			BorderDim = Color3.fromRGB(30, 30, 30),
			ToggleOff = Color3.fromRGB(30, 30, 30),
			ToggleOn = Color3.fromRGB(200, 200, 200),
		},
	},
}

return function()
	local ThemeManager = {
		Presets = {},
		ActivePreset = SETTINGS.DEFAULT_PRESET,
	}

	for presetName, colors in pairs(SETTINGS.PRESETS) do
		local fullPreset = {}
		for key, value in pairs(colors) do
			fullPreset[key] = value
		end
		for key, value in pairs(SETTINGS.STATUS_COLORS) do
			fullPreset[key] = value
		end
		ThemeManager.Presets[presetName] = fullPreset
	end

	local activeTheme = {}
	local initialPreset = ThemeManager.Presets[SETTINGS.DEFAULT_PRESET] or next(ThemeManager.Presets)
	for key, value in pairs(initialPreset) do
		activeTheme[key] = value
	end

	ThemeManager.Current = activeTheme

	function ThemeManager.DeriveAccentTones(accentColor)
		if typeof(accentColor) ~= "Color3" then
			return {
				Accent = Color3.fromRGB(255, 255, 255),
				AccentDark = Color3.fromRGB(180, 180, 180),
				AccentDim = Color3.fromRGB(100, 100, 100),
			}
		end

		local h, s, v = accentColor:ToHSV()
		return {
			Accent = accentColor,
			AccentDark = Color3.fromHSV(
				h,
				math.clamp(s * SETTINGS.ACCENT_FACTORS.DARK_SATURATION, 0, 1),
				math.clamp(v * SETTINGS.ACCENT_FACTORS.DARK_VALUE, 0, 1)
			),
			AccentDim = Color3.fromHSV(
				h,
				math.clamp(s * SETTINGS.ACCENT_FACTORS.DIM_SATURATION, 0, 1),
				math.clamp(v * SETTINGS.ACCENT_FACTORS.DIM_VALUE, 0, 1)
			),
		}
	end

	return activeTheme, ThemeManager
end
