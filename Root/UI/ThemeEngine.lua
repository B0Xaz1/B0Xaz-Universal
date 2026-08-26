-- ════════════════════════════════════════════════════════════════════════════
-- UI/ThemeEngine.lua
-- Design tokens, preset palettes, and reactive UI theme bindings
-- ════════════════════════════════════════════════════════════════════════════

local ThemeEngine = {}
ThemeEngine.__index = ThemeEngine

local PRESETS = {
	["Flat Dark"] = {
		Bg = Color3.fromRGB(13, 13, 13),
		Panel = Color3.fromRGB(17, 17, 17),
		Elem = Color3.fromRGB(24, 24, 24),
		ElemHover = Color3.fromRGB(34, 34, 34),
		Side = Color3.fromRGB(17, 17, 17),
		Accent = Color3.fromRGB(0, 220, 70),
		Text = Color3.fromRGB(225, 225, 225),
		TextDim = Color3.fromRGB(150, 150, 150),
		TextMuted = Color3.fromRGB(95, 95, 95),
		Border = Color3.fromRGB(60, 60, 60),
		BorderDim = Color3.fromRGB(42, 42, 42),
		ToggleOff = Color3.fromRGB(24, 24, 24),
		ToggleOn = Color3.fromRGB(0, 220, 70),
		Success = Color3.fromRGB(0, 220, 70),
		Danger = Color3.fromRGB(230, 60, 60),
		Warning = Color3.fromRGB(230, 175, 70),
	},
	["Midnight Purple"] = {
		Bg = Color3.fromRGB(14, 12, 20),
		Panel = Color3.fromRGB(20, 17, 27),
		Elem = Color3.fromRGB(27, 23, 36),
		ElemHover = Color3.fromRGB(36, 31, 48),
		Side = Color3.fromRGB(18, 15, 24),
		Accent = Color3.fromRGB(170, 70, 250),
		Text = Color3.fromRGB(235, 230, 245),
		TextDim = Color3.fromRGB(160, 150, 175),
		TextMuted = Color3.fromRGB(105, 95, 120),
		Border = Color3.fromRGB(62, 50, 80),
		BorderDim = Color3.fromRGB(45, 36, 62),
		ToggleOff = Color3.fromRGB(27, 23, 36),
		ToggleOn = Color3.fromRGB(170, 70, 250),
		Success = Color3.fromRGB(0, 220, 70),
		Danger = Color3.fromRGB(230, 60, 60),
		Warning = Color3.fromRGB(230, 175, 70),
	},
	["Blood Crimson"] = {
		Bg = Color3.fromRGB(18, 12, 12),
		Panel = Color3.fromRGB(24, 16, 16),
		Elem = Color3.fromRGB(33, 21, 21),
		ElemHover = Color3.fromRGB(44, 28, 28),
		Side = Color3.fromRGB(21, 14, 14),
		Accent = Color3.fromRGB(235, 50, 65),
		Text = Color3.fromRGB(240, 225, 225),
		TextDim = Color3.fromRGB(170, 145, 145),
		TextMuted = Color3.fromRGB(115, 95, 95),
		Border = Color3.fromRGB(70, 44, 44),
		BorderDim = Color3.fromRGB(50, 33, 33),
		ToggleOff = Color3.fromRGB(33, 21, 21),
		ToggleOn = Color3.fromRGB(235, 50, 65),
		Success = Color3.fromRGB(0, 220, 70),
		Danger = Color3.fromRGB(230, 60, 60),
		Warning = Color3.fromRGB(230, 175, 70),
	},
	["Emerald Neon"] = {
		Bg = Color3.fromRGB(12, 18, 14),
		Panel = Color3.fromRGB(16, 24, 19),
		Elem = Color3.fromRGB(22, 32, 25),
		ElemHover = Color3.fromRGB(30, 43, 33),
		Side = Color3.fromRGB(14, 21, 17),
		Accent = Color3.fromRGB(0, 225, 120),
		Text = Color3.fromRGB(225, 240, 230),
		TextDim = Color3.fromRGB(145, 170, 155),
		TextMuted = Color3.fromRGB(95, 115, 100),
		Border = Color3.fromRGB(50, 74, 58),
		BorderDim = Color3.fromRGB(36, 52, 42),
		ToggleOff = Color3.fromRGB(22, 32, 25),
		ToggleOn = Color3.fromRGB(0, 225, 120),
		Success = Color3.fromRGB(0, 220, 70),
		Danger = Color3.fromRGB(230, 60, 60),
		Warning = Color3.fromRGB(230, 175, 70),
	},
	["Abyss Dark"] = {
		Bg = Color3.fromRGB(10, 10, 10),
		Panel = Color3.fromRGB(15, 15, 15),
		Elem = Color3.fromRGB(21, 21, 21),
		ElemHover = Color3.fromRGB(30, 30, 30),
		Side = Color3.fromRGB(13, 13, 13),
		Accent = Color3.fromRGB(200, 200, 200),
		Text = Color3.fromRGB(240, 240, 240),
		TextDim = Color3.fromRGB(150, 150, 150),
		TextMuted = Color3.fromRGB(90, 90, 90),
		Border = Color3.fromRGB(48, 48, 48),
		BorderDim = Color3.fromRGB(33, 33, 33),
		ToggleOff = Color3.fromRGB(21, 21, 21),
		ToggleOn = Color3.fromRGB(200, 200, 200),
		Success = Color3.fromRGB(0, 220, 70),
		Danger = Color3.fromRGB(230, 60, 60),
		Warning = Color3.fromRGB(230, 175, 70),
	},
}

function ThemeEngine.new()
	local self = setmetatable({}, ThemeEngine)
	self.Presets = PRESETS
	self.ActivePreset = "Flat Dark"
	self.Current = {}
	self._bindings = {}

	for k, v in pairs(PRESETS["Flat Dark"]) do
		self.Current[k] = v
	end
	return self
end

function ThemeEngine:Init(container)
	self._signalClass = container:Get("Signal")
	self.OnThemeUpdated = self._signalClass.new()
end

-- Binds a property of an instance to a dynamic theme token
function ThemeEngine:Bind(instance, property, tokenKey)
	table.insert(self._bindings, { Instance = instance, Property = property, Key = tokenKey })
	if self.Current[tokenKey] then
		pcall(function() instance[property] = self.Current[tokenKey] end)
	end
end

-- Switches the active theme preset
function ThemeEngine:SetPreset(presetName)
	local target = self.Presets[presetName]
	if not target then return end

	self.ActivePreset = presetName
	for k, v in pairs(target) do
		self.Current[k] = v
	end
	self:Refresh()
end

-- Updates a single color token manually
function ThemeEngine:SetToken(key, color)
	self.Current[key] = color
	self:Refresh()
end

-- Repaints all bound UI instances
function ThemeEngine:Refresh()
	for i = #self._bindings, 1, -1 do
		local b = self._bindings[i]
		if b.Instance and b.Instance.Parent then
			local val = self.Current[b.Key]
			if val then
				pcall(function() b.Instance[b.Property] = val end)
			end
		else
			table.remove(self._bindings, i)
		end
	end
	self.OnThemeUpdated:Fire(self.Current)
end

function ThemeEngine:Destroy()
	table.clear(self._bindings)
	self.OnThemeUpdated:Destroy()
end

return ThemeEngine
