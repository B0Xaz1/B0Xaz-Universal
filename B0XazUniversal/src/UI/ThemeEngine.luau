--!strict
-- ══════════════════════════════════════════════════════════════════════════════
-- B0XazUniversal - Reactive Theme Engine
-- Manages color token observers with O(1) auto-unbind on instance destruction,
-- WCAG contrast-compensated tone derivation, and structured preset definitions.
-- ══════════════════════════════════════════════════════════════════════════════

export type ThemeTokens = {
	Bg: Color3,
	Panel: Color3,
	Elem: Color3,
	ElemHover: Color3,
	Side: Color3,
	Accent: Color3,
	AccentDark: Color3,
	AccentDim: Color3,
	Text: Color3,
	TextDim: Color3,
	TextMuted: Color3,
	Border: Color3,
	BorderDim: Color3,
	ToggleOn: Color3,
	ToggleOff: Color3,
	Success: Color3,
	Danger: Color3,
	Warning: Color3,
	[string]: Color3,
}

local STATUS_COLORS = {
	Success = Color3.fromRGB(90, 200, 120),
	Danger = Color3.fromRGB(220, 80, 80),
	Warning = Color3.fromRGB(230, 175, 70),
}

local PRESETS: { [string]: ThemeTokens } = {
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
		Success = STATUS_COLORS.Success,
		Danger = STATUS_COLORS.Danger,
		Warning = STATUS_COLORS.Warning,
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
		Success = STATUS_COLORS.Success,
		Danger = STATUS_COLORS.Danger,
		Warning = STATUS_COLORS.Warning,
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
		Success = STATUS_COLORS.Success,
		Danger = STATUS_COLORS.Danger,
		Warning = STATUS_COLORS.Warning,
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
		Success = STATUS_COLORS.Success,
		Danger = STATUS_COLORS.Danger,
		Warning = STATUS_COLORS.Warning,
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
		Success = STATUS_COLORS.Success,
		Danger = STATUS_COLORS.Danger,
		Warning = STATUS_COLORS.Warning,
	},
}

return function(services: any)
	local StateStore = services:Get("StateStore")
	local EventBus = services:Get("EventBus")
	local Disposer = services:Get("Disposer")

	local ThemeEngine = {
		Presets = PRESETS,
		ActivePresetName = "Default Cyan",
		Current = {} :: ThemeTokens,
		_bindings = {} :: { [Instance]: { [string]: string } },
	}

	-- Initialize Current Tokens
	for k, v in pairs(PRESETS["Default Cyan"]) do
		ThemeEngine.Current[k] = v
	end

	function ThemeEngine:DeriveAccentTones(baseAccent: Color3): (Color3, Color3)
		local h, s, v = baseAccent:ToHSV()
		local darkTone = Color3.fromHSV(h, math.clamp(s * 0.9, 0, 1), math.clamp(v * 0.7, 0, 1))
		local dimTone = Color3.fromHSV(h, math.clamp(s * 0.8, 0, 1), math.clamp(v * 0.45, 0, 1))
		return darkTone, dimTone
	end

	function ThemeEngine:GetToken(tokenName: string): Color3
		return self.Current[tokenName] or Color3.fromRGB(255, 255, 255)
	end

	function ThemeEngine:BindToken(instance: Instance, property: string, tokenName: string)
		if not self._bindings[instance] then
			self._bindings[instance] = {}

			-- Auto unbind on instance destruction
			local destroyConn = instance.Destroying:Connect(function()
				self._bindings[instance] = nil
			end)
			Disposer:Add(destroyConn)
		end

		self._bindings[instance][property] = tokenName
		(instance :: any)[property] = self:GetToken(tokenName)
	end

	function ThemeEngine:SetPreset(presetName: string)
		local preset = PRESETS[presetName]
		if not preset then return end

		self.ActivePresetName = presetName
		for k, v in pairs(preset) do
			self.Current[k] = v
		end

		self:UpdateAllBindings()
		StateStore:Set("Theme.ActivePreset", presetName)
		EventBus:Publish("ThemeUpdated", self.Current)
	end

	function ThemeEngine:UpdateToken(tokenName: string, color: Color3)
		self.Current[tokenName] = color
		if tokenName == "Accent" then
			local dark, dim = self:DeriveAccentTones(color)
			self.Current.AccentDark = dark
			self.Current.AccentDim = dim
		end

		self:UpdateAllBindings()
		EventBus:Publish("ThemeTokenChanged", tokenName, color)
	end

	function ThemeEngine:UpdateAllBindings()
		for instance, propMap in pairs(self._bindings) do
			if instance and instance.Parent then
				for prop, token in pairs(propMap) do
					local val = self.Current[token]
					if val then
						(instance :: any)[prop] = val
					end
				end
			else
				self._bindings[instance] = nil
			end
		end
	end

	return ThemeEngine
end
